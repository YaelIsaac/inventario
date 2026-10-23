import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../models/usuario_model.dart';
import 'catalogo_service.dart';
import 'errores.dart';
import 'inventario_service.dart';
import 'pedidos_service.dart';
import 'vinculos_service.dart';

/// Sesión y roles: 'admin', 'proveedor', 'negocio', 'suspendido' o 'ninguno'.
/// Según el rol se activan o apagan los servicios de datos.
class AuthService extends ChangeNotifier {
  AuthService._();
  static final AuthService instance = AuthService._();

  bool listo = false;
  User? user;
  UsuarioModel? perfil;
  String rol = 'ninguno';
  String? errorPerfil;

  StreamSubscription<User?>? _subAuth;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _subPerfil;
  bool _registrando = false;
  bool _creandoCodigo = false;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  void iniciar() {
    if (_subAuth != null) return;
    _subAuth = FirebaseAuth.instance.authStateChanges().listen(_onUser);
  }

  void _onUser(User? u) {
    // Sesiones anónimas de versiones anteriores: ya no se usan.
    if (u != null && u.isAnonymous) {
      FirebaseAuth.instance.signOut();
      return;
    }
    _subPerfil?.cancel();
    _subPerfil = null;
    user = u;
    perfil = null;
    errorPerfil = null;

    if (u == null) {
      rol = 'ninguno';
      _aplicarRol();
      listo = true;
      notifyListeners();
      return;
    }

    rol = 'cargando';
    listo = false;
    _aplicarRol();
    notifyListeners();

    _subPerfil = _db.collection('users').doc(u.uid).snapshots().listen(
      (snap) {
        if (!snap.exists) {
          // Cuenta sin perfil (p. ej. falló el registro): se repara sola.
          if (!_registrando && !snap.metadata.isFromCache) {
            _crearPerfil(u,
                    nombre: u.displayName ?? '',
                    empresa: '',
                    telefono: '',
                    rolElegido: 'negocio')
                .catchError((Object e) => debugPrint('Perfil: $e'));
          }
          return;
        }
        perfil = UsuarioModel.fromDoc(snap);
        final nuevoRol = perfil!.activo ? perfil!.rol : 'suspendido';
        final cambio = nuevoRol != rol;
        rol = nuevoRol;
        listo = true;
        errorPerfil = null;
        if (cambio) _aplicarRol();
        _repararCodigo();
        notifyListeners();
      },
      onError: (Object e) {
        debugPrint('Error leyendo perfil: $e');
        errorPerfil = 'No se pudo leer tu perfil. Revisa las reglas de '
            'Firestore y tu conexión.';
        notifyListeners();
      },
    );
  }

  void _aplicarRol() {
    InventarioService.instance.detener();
    PedidosService.instance.detener();
    CatalogoService.instance.detener();
    VinculosService.instance.detener();
    final u = user;
    if (u == null) return;

    if (rol == 'proveedor') {
      CatalogoService.instance.iniciar(u.uid);
      VinculosService.instance.iniciarProveedor(u.uid);
      PedidosService.instance.iniciarProveedor(u.uid);
    } else if (rol == 'negocio') {
      InventarioService.instance.iniciar(u.uid);
      VinculosService.instance.iniciarNegocio(u.uid, u.email ?? '');
      PedidosService.instance.iniciarNegocio(u.uid);
    }
  }

  // --------------------------------------------------------------- perfil

  Future<void> _crearPerfil(
    User u, {
    required String nombre,
    required String empresa,
    required String telefono,
    required String rolElegido, // 'proveedor' | 'negocio'
  }) async {
    final correo = (u.email ?? '').toLowerCase();
    final esInicial = correo.isNotEmpty && correo == kAdminInicial.toLowerCase();
    await _db.collection('users').doc(u.uid).set({
      'nombre': nombre.trim(),
      'empresa': empresa.trim(),
      'email': correo,
      'telefono': telefono.trim(),
      'direccion': '',
      'giro': '',
      'rol': esInicial ? 'admin' : rolElegido,
      'rolBase': rolElegido,
      'codigo': '',
      'verificado': false,
      'activo': true,
      'creado': Timestamp.now(),
    });
  }

  /// Crea la ficha pública del proveedor con un código único.
  Future<void> _crearDirectorio(User u, String empresa, String telefono) async {
    const chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    for (var i = 0; i < 8; i++) {
      final codigo =
          List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
      try {
        await _db.collection('directorio').doc(codigo).set({
          'proveedorId': u.uid,
          'empresa': empresa.trim(),
          'giro': '',
          'telefono': telefono.trim(),
          'verificado': false,
          'activo': true,
        });
        await _db.collection('users').doc(u.uid).update({'codigo': codigo});
        return;
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') continue; // código ya usado
        rethrow;
      }
    }
  }

  void _repararCodigo() {
    final p = perfil;
    final u = user;
    if (p == null || u == null || _registrando || _creandoCodigo) return;
    if (p.rol == 'proveedor' && p.codigo.isEmpty) {
      _creandoCodigo = true;
      _crearDirectorio(u, p.titulo, p.telefono)
          .catchError((Object e) => debugPrint('Código: $e'))
          .whenComplete(() => _creandoCodigo = false);
    }
  }

  // ------------------------------------------------------ acciones de sesión

  Future<String?> iniciarSesion(String email, String pass) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email.trim(), password: pass);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensaje(e);
    } catch (_) {
      return 'Ocurrió un error. Intenta de nuevo.';
    }
  }

  Future<String?> registrar({
    required String rolElegido,
    required String nombre,
    required String empresa,
    required String telefono,
    required String email,
    required String pass,
  }) async {
    _registrando = true;
    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email.trim(), password: pass);
      final u = cred.user!;
      await _crearPerfil(u,
          nombre: nombre,
          empresa: empresa,
          telefono: telefono,
          rolElegido: rolElegido);
      if (rolElegido == 'proveedor') {
        try {
          await _crearDirectorio(u, empresa, telefono);
        } catch (e) {
          debugPrint('Directorio: $e'); // se repara solo al abrir la app
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensaje(e);
    } on FirebaseException catch (e) {
      debugPrint('Perfil: $e');
      return 'Tu cuenta se creó pero no se pudo guardar el perfil. '
          'Inicia sesión de nuevo.';
    } catch (_) {
      return 'Ocurrió un error. Intenta de nuevo.';
    } finally {
      _registrando = false;
    }
  }

  Future<String?> recuperarPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mensaje(e);
    } catch (_) {
      return 'Ocurrió un error. Intenta de nuevo.';
    }
  }

  Future<void> cerrarSesion() => FirebaseAuth.instance.signOut();

  void actualizarPerfil({
    required String nombre,
    required String empresa,
    required String telefono,
    required String direccion,
    String giro = '',
  }) {
    final u = user;
    final p = perfil;
    if (u == null || p == null) return;
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(u.uid), {
      'nombre': nombre.trim(),
      'empresa': empresa.trim(),
      'telefono': telefono.trim(),
      'direccion': direccion.trim(),
      'giro': giro.trim(),
    });
    if (p.rol == 'proveedor' && p.codigo.isNotEmpty) {
      batch.update(_db.collection('directorio').doc(p.codigo), {
        'empresa': empresa.trim(),
        'giro': giro.trim(),
        'telefono': telefono.trim(),
      });
    }
    batch.commit().catchError(
        (Object e) => reportarError('No se pudo guardar tu perfil.'));
  }

  // ---------------------------------------------------- administración

  Stream<List<UsuarioModel>> streamUsuarios() {
    return _db.collection('users').snapshots().map((s) {
      final l = s.docs.map(UsuarioModel.fromDoc).toList()
        ..sort((a, b) =>
            a.titulo.toLowerCase().compareTo(b.titulo.toLowerCase()));
      return l;
    });
  }

  void _adminEscribir(Future<void> f) {
    f.catchError((Object e) {
      debugPrint('Admin: $e');
      reportarError('No se pudo guardar el cambio.');
    });
  }

  void ascenderAdmin(UsuarioModel u) =>
      _adminEscribir(_db.collection('users').doc(u.uid).update({'rol': 'admin'}));

  void quitarAdmin(UsuarioModel u) => _adminEscribir(
      _db.collection('users').doc(u.uid).update({'rol': u.rolBase}));

  void setVerificado(UsuarioModel u, bool v) {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(u.uid), {'verificado': v});
    if (u.codigo.isNotEmpty) {
      batch.update(_db.collection('directorio').doc(u.codigo), {'verificado': v});
    }
    _adminEscribir(batch.commit());
  }

  void setActivo(UsuarioModel u, bool activo) {
    final batch = _db.batch();
    batch.update(_db.collection('users').doc(u.uid), {'activo': activo});
    if (u.codigo.isNotEmpty) {
      batch.update(_db.collection('directorio').doc(u.codigo), {'activo': activo});
    }
    _adminEscribir(batch.commit());
  }

  String _mensaje(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El correo no es válido.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo.';
      case 'weak-password':
        return 'La contraseña es muy débil (mínimo 6 caracteres).';
      case 'network-request-failed':
        return 'Sin conexión a internet.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento.';
      case 'user-disabled':
        return 'Esta cuenta está deshabilitada.';
      case 'operation-not-allowed':
        return 'Este método de acceso no está activado en Firebase.';
      default:
        return 'No se pudo completar la acción (${e.code}).';
    }
  }
}
