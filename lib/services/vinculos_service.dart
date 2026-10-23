import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/vinculo_model.dart';
import 'auth_service.dart';
import 'errores.dart';
import 'notificacion_service.dart';

String _claveEmail(String email) =>
    email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

/// Relaciones proveedor <-> negocio, solicitudes e invitaciones por correo.
class VinculosService extends ChangeNotifier {
  VinculosService._();
  static final VinculosService instance = VinculosService._();

  List<VinculoModel> vinculos = [];
  List<InvitacionModel> invitaciones = [];
  bool cargado = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subV;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subI;
  String? _uid;
  bool _esProveedor = false;
  bool _primeraV = false;
  bool _invCargadas = false;
  final Map<String, String> _estadoPrevio = {};
  final Set<String> _reclamando = {};

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  List<VinculoModel> get activos => vinculos.where((v) => v.activo).toList();
  List<VinculoModel> get pendientes => vinculos.where((v) => v.pendiente).toList();
  List<InvitacionModel> get invitacionesPendientes =>
      invitaciones.where((i) => i.estado == 'pendiente').toList();

  VinculoModel? porId(String id) {
    for (final v in vinculos) {
      if (v.id == id) return v;
    }
    return null;
  }

  VinculoModel? conProveedor(String proveedorId) {
    for (final v in vinculos) {
      if (v.proveedorId == proveedorId) return v;
    }
    return null;
  }

  // ------------------------------------------------------------ inicio / fin

  void iniciarProveedor(String uid) {
    detener();
    _uid = uid;
    _esProveedor = true;
    _subV = _db
        .collection('vinculos')
        .where('proveedorId', isEqualTo: uid)
        .snapshots()
        .listen(_onVinculos, onError: _onError);
    _subI = _db
        .collection('invitaciones')
        .where('proveedorId', isEqualTo: uid)
        .snapshots()
        .listen((s) {
      invitaciones = s.docs.map(InvitacionModel.fromDoc).toList();
      notifyListeners();
    }, onError: _onError);
  }

  void iniciarNegocio(String uid, String email) {
    detener();
    _uid = uid;
    _esProveedor = false;
    _subV = _db
        .collection('vinculos')
        .where('negocioId', isEqualTo: uid)
        .snapshots()
        .listen(_onVinculos, onError: _onError);
    // Invitaciones que algún proveedor hizo a mi correo: se vinculan solas.
    if (email.trim().isEmpty) return;
    _subI = _db
        .collection('invitaciones')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .snapshots()
        .listen((s) {
      invitaciones = s.docs.map(InvitacionModel.fromDoc).toList();
      _invCargadas = true;
      _reclamarInvitaciones();
    }, onError: _onError);
  }

  void detener() {
    _subV?.cancel();
    _subI?.cancel();
    _subV = null;
    _subI = null;
    _uid = null;
    _primeraV = false;
    _invCargadas = false;
    _estadoPrevio.clear();
    _reclamando.clear();
    vinculos = [];
    invitaciones = [];
    cargado = false;
    notifyListeners();
  }

  void _onError(Object e) {
    debugPrint('Vínculos: $e');
    reportarError('No se pudieron sincronizar tus proveedores/clientes.');
  }

  void _onVinculos(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map(VinculoModel.fromDoc).toList()
      ..sort((a, b) => b.creado.compareTo(a.creado));

    if (_primeraV) {
      for (final ch in snap.docChanges) {
        if (ch.doc.metadata.hasPendingWrites) continue;
        final v = VinculoModel.fromDoc(ch.doc);
        if (_esProveedor) {
          if (ch.type == DocumentChangeType.added && v.pendiente) {
            NotificacionService.instance.mostrar(
              id: v.id.hashCode & 0x7fffffff,
              titulo: 'Nueva solicitud de cliente',
              cuerpo: '${v.negocioNombre} quiere surtirse contigo.',
            );
          }
        } else if (ch.type == DocumentChangeType.modified) {
          final antes = _estadoPrevio[v.id];
          if (antes != null && antes != v.estado && v.activo) {
            NotificacionService.instance.mostrar(
              id: v.id.hashCode & 0x7fffffff,
              titulo: 'Proveedor aprobado',
              cuerpo: '${v.proveedorNombre} ya puede surtirte.',
            );
          }
        }
      }
    }
    _primeraV = true;
    _estadoPrevio
      ..clear()
      ..addEntries(lista.map((v) => MapEntry(v.id, v.estado)));
    vinculos = lista;
    cargado = true;
    notifyListeners();
    if (!_esProveedor) _reclamarInvitaciones();
  }

  // ------------------------------------------------ vinculación automática

  void _reclamarInvitaciones() {
    if (_esProveedor || !cargado || !_invCargadas) return;
    final uid = _uid;
    final perfil = AuthService.instance.perfil;
    if (uid == null || perfil == null) return;

    for (final inv in invitaciones.where((i) => i.estado == 'pendiente')) {
      if (_reclamando.contains(inv.id)) continue;
      _reclamando.add(inv.id);
      final id = '${inv.proveedorId}_$uid';
      final invRef = _db.collection('invitaciones').doc(inv.id);

      if (vinculos.any((v) => v.id == id)) {
        // Ya existía una relación: solo se cierra la invitación.
        invRef.update({'estado': 'aceptada'}).catchError(
            (Object e) => debugPrint('Invitación: $e'));
        continue;
      }
      final batch = _db.batch();
      batch.set(_db.collection('vinculos').doc(id), {
        'proveedorId': inv.proveedorId,
        'negocioId': uid,
        'proveedorNombre': inv.proveedorNombre,
        'negocioNombre': perfil.titulo,
        'negocioEmail': perfil.email.toLowerCase(),
        'negocioTelefono': perfil.telefono,
        'negocioDireccion': perfil.direccion,
        'contacto': perfil.nombre,
        'notas': inv.notas,
        'estado': 'activo',
        'invitacionId': inv.id,
        'creado': Timestamp.now(),
      });
      batch.update(invRef, {'estado': 'aceptada'});
      batch.commit().catchError((Object e) {
        debugPrint('Reclamar invitación: $e');
        _reclamando.remove(inv.id);
      });
    }
  }

  // ----------------------------------------------------------- NEGOCIO

  /// Busca al proveedor por su código y le envía la solicitud.
  Future<String?> solicitarPorCodigo(String codigo) async {
    codigo = codigo.trim().toUpperCase();
    if (codigo.length < 4) return 'Escribe el código completo.';
    try {
      final d = await _db.collection('directorio').doc(codigo).get();
      if (!d.exists) return 'No existe ningún proveedor con ese código.';
      return solicitar(DirectorioModel.fromDoc(d));
    } catch (e) {
      debugPrint('Código: $e');
      return 'No se pudo buscar. Revisa tu conexión.';
    }
  }

  String? solicitar(DirectorioModel dir) {
    final uid = _uid;
    final perfil = AuthService.instance.perfil;
    if (uid == null || perfil == null) return 'Sesión no válida.';
    if (!dir.activo) return 'Este proveedor no está disponible.';
    final existente = conProveedor(dir.proveedorId);
    if (existente != null) {
      switch (existente.estado) {
        case 'activo':
          return 'Ya trabajas con ${dir.empresa}.';
        case 'pendiente':
          return 'Ya enviaste una solicitud a ${dir.empresa}. Espera su aprobación.';
        default:
          return 'El proveedor ${etiquetaVinculo(existente.estado).toLowerCase()} '
              'tu relación. Pídele que te registre con tu correo.';
      }
    }
    final id = '${dir.proveedorId}_$uid';
    _db.collection('vinculos').doc(id).set({
      'proveedorId': dir.proveedorId,
      'negocioId': uid,
      'proveedorNombre': dir.empresa,
      'negocioNombre': perfil.titulo,
      'negocioEmail': perfil.email.toLowerCase(),
      'negocioTelefono': perfil.telefono,
      'negocioDireccion': perfil.direccion,
      'contacto': perfil.nombre,
      'notas': '',
      'estado': 'pendiente',
      'creado': Timestamp.now(),
    }).catchError((Object e) {
      debugPrint('Solicitud: $e');
      reportarError('No se pudo enviar la solicitud.');
    });
    return null;
  }

  void cancelarSolicitud(VinculoModel v) {
    _db.collection('vinculos').doc(v.id).delete().catchError(
        (Object e) => reportarError('No se pudo cancelar la solicitud.'));
  }

  static Stream<List<DirectorioModel>> streamDirectorio() {
    return FirebaseFirestore.instance
        .collection('directorio')
        .limit(300)
        .snapshots()
        .map((s) {
      final l = s.docs.map(DirectorioModel.fromDoc).where((d) => d.activo).toList()
        ..sort((a, b) {
          if (a.verificado != b.verificado) return a.verificado ? -1 : 1;
          return a.empresa.toLowerCase().compareTo(b.empresa.toLowerCase());
        });
      return l;
    });
  }

  // --------------------------------------------------------- PROVEEDOR

  void _actualizar(String id, Map<String, dynamic> data) {
    _db.collection('vinculos').doc(id).update(data).catchError(
        (Object e) => reportarError('No se pudo guardar el cambio.'));
  }

  void aprobar(VinculoModel v) => _actualizar(v.id, {'estado': 'activo'});
  void rechazar(VinculoModel v) => _actualizar(v.id, {'estado': 'rechazado'});
  void desactivar(VinculoModel v) => _actualizar(v.id, {'estado': 'inactivo'});
  void reactivar(VinculoModel v) => _actualizar(v.id, {'estado': 'activo'});
  void guardarNotas(VinculoModel v, String notas) =>
      _actualizar(v.id, {'notas': notas.trim()});

  /// Registra un negocio por su correo. Si ya tiene cuenta (o la crea después)
  /// se vincula solo.
  String? invitarNegocio({
    required String email,
    required String nombre,
    String contacto = '',
    String telefono = '',
    String direccion = '',
    String notas = '',
  }) {
    final uid = _uid;
    final perfil = AuthService.instance.perfil;
    if (uid == null || perfil == null) return 'Sesión no válida.';
    final correo = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo)) {
      return 'El correo no es válido.';
    }
    if (nombre.trim().isEmpty) return 'Escribe el nombre del negocio.';
    if (vinculos.any((v) => v.negocioEmail.toLowerCase() == correo)) {
      return 'Ese negocio ya está en tu lista de clientes.';
    }
    final id = '${uid}_${_claveEmail(correo)}';
    if (invitaciones.any((i) => i.id == id && i.estado == 'pendiente')) {
      return 'Ya registraste a ese correo. Espera a que cree su cuenta.';
    }
    _db.collection('invitaciones').doc(id).set({
      'proveedorId': uid,
      'proveedorNombre': perfil.titulo,
      'email': correo,
      'nombre': nombre.trim(),
      'contacto': contacto.trim(),
      'telefono': telefono.trim(),
      'direccion': direccion.trim(),
      'notas': notas.trim(),
      'estado': 'pendiente',
      'creado': Timestamp.now(),
    }).catchError((Object e) {
      debugPrint('Invitar: $e');
      reportarError('No se pudo registrar al negocio.');
    });
    return null;
  }

  void eliminarInvitacion(InvitacionModel i) {
    _db.collection('invitaciones').doc(i.id).delete().catchError(
        (Object e) => reportarError('No se pudo eliminar.'));
  }
}
