import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/abono_model.dart';
import '../models/pedido_model.dart';
import '../theme.dart';
import 'errores.dart';
import 'notificacion_service.dart';

/// Pedidos entre negocio y proveedor, abonos y estado de cuenta.
class PedidosService extends ChangeNotifier {
  PedidosService._();
  static final PedidosService instance = PedidosService._();

  List<PedidoModel> pedidos = [];
  List<AbonoModel> abonos = [];
  bool cargado = false;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subP;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subA;
  bool _esProveedor = false;
  bool _primera = false;
  final Map<String, String> _estadoPrevio = {};

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('pedidos');

  int get nuevos => pedidos.where((p) => p.estado == 'nuevo').length;
  int get activos => pedidos.where((p) => p.activo).length;

  PedidoModel? porId(String id) {
    for (final p in pedidos) {
      if (p.id == id) return p;
    }
    return null;
  }

  void iniciarProveedor(String uid) => _iniciar('proveedorId', uid, true);
  void iniciarNegocio(String uid) => _iniciar('negocioId', uid, false);

  void _iniciar(String campo, String uid, bool proveedor) {
    detener();
    _esProveedor = proveedor;
    _subP = _col
        .where(campo, isEqualTo: uid)
        .snapshots(includeMetadataChanges: true)
        .listen(_onPedidos, onError: _onError);
    _subA = _db
        .collection('abonos')
        .where(campo, isEqualTo: uid)
        .snapshots()
        .listen((s) {
      abonos = s.docs.map(AbonoModel.fromDoc).toList()
        ..sort((a, b) => b.fecha.compareTo(a.fecha));
      notifyListeners();
    }, onError: _onError);
  }

  void detener() {
    _subP?.cancel();
    _subA?.cancel();
    _subP = null;
    _subA = null;
    _primera = false;
    _estadoPrevio.clear();
    pedidos = [];
    abonos = [];
    cargado = false;
    notifyListeners();
  }

  void _onError(Object e) {
    debugPrint('Pedidos: $e');
    reportarError('No se pudieron sincronizar los pedidos.');
  }

  void _onPedidos(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map(PedidoModel.fromDoc).toList()
      ..sort((a, b) => b.creado.compareTo(a.creado));

    if (_primera) {
      for (final ch in snap.docChanges) {
        if (ch.doc.metadata.hasPendingWrites) continue; // cambio propio
        final p = PedidoModel.fromDoc(ch.doc);
        final id = p.id.hashCode & 0x7fffffff;
        if (_esProveedor) {
          if (ch.type == DocumentChangeType.added) {
            NotificacionService.instance.mostrar(
              id: id,
              titulo: 'Nuevo pedido #${p.codigo}',
              cuerpo: '${p.negocioNombre} • ${fmtPrecio(p.total)}',
            );
          } else if (ch.type == DocumentChangeType.modified &&
              p.estado == 'cancelado' &&
              _estadoPrevio[p.id] != 'cancelado') {
            NotificacionService.instance.mostrar(
              id: id,
              titulo: 'Pedido cancelado #${p.codigo}',
              cuerpo: '${p.negocioNombre} canceló su pedido.',
            );
          }
        } else if (ch.type == DocumentChangeType.modified) {
          final antes = _estadoPrevio[p.id];
          if (antes != null && antes != p.estado) {
            NotificacionService.instance.mostrar(
              id: id,
              titulo: 'Pedido #${p.codigo} • ${p.proveedorNombre}',
              cuerpo: etiquetaEstado(p.estado),
            );
          }
        }
      }
    }
    _primera = true;
    _estadoPrevio
      ..clear()
      ..addEntries(lista.map((p) => MapEntry(p.id, p.estado)));
    pedidos = lista;
    cargado = true;
    notifyListeners();
  }

  void _escribir(Future<void> f) {
    f.catchError((Object e) {
      debugPrint('Error al guardar: $e');
      reportarError('No se pudo guardar el cambio. Intenta de nuevo.');
    });
  }

  // ------------------------------------------------------- estado de cuenta

  double _entregado(String otroId) => pedidos
      .where((p) =>
          p.estado == 'entregado' &&
          (_esProveedor ? p.negocioId == otroId : p.proveedorId == otroId))
      .fold(0.0, (s, p) => s + p.total);

  double _abonado(String otroId) => abonos
      .where((a) => _esProveedor ? a.negocioId == otroId : a.proveedorId == otroId)
      .fold(0.0, (s, a) => s + a.monto);

  /// Lo que falta por pagar con esa contraparte (positivo = hay deuda).
  double saldoCon(String otroId) => _entregado(otroId) - _abonado(otroId);

  double get saldoTotal {
    final entregado = pedidos
        .where((p) => p.estado == 'entregado')
        .fold(0.0, (s, p) => s + p.total);
    final abonado = abonos.fold(0.0, (s, a) => s + a.monto);
    return entregado - abonado;
  }

  List<PedidoModel> pedidosCon(String otroId) => pedidos
      .where((p) => _esProveedor ? p.negocioId == otroId : p.proveedorId == otroId)
      .toList();

  List<AbonoModel> abonosCon(String otroId) => abonos
      .where((a) => _esProveedor ? a.negocioId == otroId : a.proveedorId == otroId)
      .toList();

  // ------------------------------------------------------------- acciones

  String? crearPedido({
    required String proveedorId,
    required String negocioId,
    required String proveedorNombre,
    required String negocioNombre,
    required String negocioTelefono,
    required String direccionEntrega,
    required String fechaDeseada,
    required String notas,
    required List<PedidoItem> items,
  }) {
    if (items.isEmpty) return 'Agrega al menos un producto.';
    final total = items.fold(0.0, (s, i) => s + i.subtotal);
    _escribir(_col.doc().set({
      'proveedorId': proveedorId,
      'negocioId': negocioId,
      'proveedorNombre': proveedorNombre,
      'negocioNombre': negocioNombre,
      'negocioTelefono': negocioTelefono.trim(),
      'direccionEntrega': direccionEntrega.trim(),
      'fechaDeseada': fechaDeseada.trim(),
      'notas': notas.trim(),
      'items': items.map((i) => i.toMap()).toList(),
      'total': total,
      'estado': 'nuevo',
      'tieneComprobante': false,
      'inventarioActualizado': false,
      'creado': Timestamp.now(),
    }));
    return null;
  }

  void cambiarEstado(String id, String estado) =>
      _escribir(_col.doc(id).update({'estado': estado}));

  void marcarInventarioActualizado(String id) =>
      _escribir(_col.doc(id).update({'inventarioActualizado': true}));

  void adjuntarComprobante(PedidoModel p, String b64) {
    final batch = _db.batch();
    batch.set(_db.collection('comprobantes').doc(p.id), {
      'negocioId': p.negocioId,
      'proveedorId': p.proveedorId,
      'imagen': b64,
      'creado': Timestamp.now(),
    });
    batch.update(_col.doc(p.id), {'tieneComprobante': true});
    _escribir(batch.commit());
  }

  Future<String?> cargarComprobante(String pedidoId) async {
    try {
      final d = await _db.collection('comprobantes').doc(pedidoId).get();
      return d.data()?['imagen'] as String?;
    } catch (e) {
      debugPrint('Comprobante: $e');
      return null;
    }
  }

  String? registrarAbono({
    required String proveedorId,
    required String negocioId,
    required double monto,
    String nota = '',
  }) {
    if (monto <= 0) return 'El monto debe ser mayor que cero.';
    _escribir(_db.collection('abonos').doc().set({
      'proveedorId': proveedorId,
      'negocioId': negocioId,
      'monto': monto,
      'nota': nota.trim(),
      'fecha': Timestamp.now(),
    }));
    return null;
  }

  void eliminarAbono(String id) =>
      _escribir(_db.collection('abonos').doc(id).delete());
}
