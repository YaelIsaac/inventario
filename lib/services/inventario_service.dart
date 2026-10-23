import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/movimiento_model.dart';
import '../models/pedido_model.dart';
import '../models/producto_model.dart';
import '../theme.dart';
import 'errores.dart';
import 'notificacion_service.dart';

/// Inventario de UN negocio: vive en negocios/{uid}/productos y /movimientos.
/// Las escrituras se aplican en el caché local y se sincronizan solas.
class InventarioService extends ChangeNotifier {
  InventarioService._();
  static final InventarioService instance = InventarioService._();

  List<ProductoModel> productos = [];
  List<MovimientoModel> movimientos = [];
  bool cargado = false;
  bool sincronizado = true;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subProductos;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subMovimientos;
  String? _uid;
  bool _primeraLectura = false;
  final Map<String, bool> _estadoPrevio = {};

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _colProductos =>
      _db.collection('negocios').doc(_uid).collection('productos');
  CollectionReference<Map<String, dynamic>> get _colMovimientos =>
      _db.collection('negocios').doc(_uid).collection('movimientos');

  List<ProductoModel> get productosBajos =>
      productos.where((p) => p.stockBajo).toList();

  List<String> get categorias {
    final s = productos.map((p) => p.categoria).toSet().toList()..sort();
    return s;
  }

  ProductoModel? productoPorId(String id) {
    for (final p in productos) {
      if (p.id == id) return p;
    }
    return null;
  }

  void iniciar(String uid) {
    if (_uid == uid) return;
    detener();
    _uid = uid;
    _subProductos = _colProductos
        .snapshots(includeMetadataChanges: true)
        .listen(_onProductos, onError: _onError);
    _subMovimientos = _colMovimientos
        .orderBy('fecha', descending: true)
        .limit(500)
        .snapshots()
        .listen(_onMovimientos, onError: _onError);
  }

  void detener() {
    _subProductos?.cancel();
    _subMovimientos?.cancel();
    _subProductos = null;
    _subMovimientos = null;
    _uid = null;
    _primeraLectura = false;
    _estadoPrevio.clear();
    productos = [];
    movimientos = [];
    cargado = false;
    sincronizado = true;
    notifyListeners();
  }

  void _onError(Object e) {
    debugPrint('Error de Firestore: $e');
    reportarError('No se pudo sincronizar con la nube. Revisa tu conexión.');
  }

  void _onProductos(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map(ProductoModel.fromDoc).toList()
      ..sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    sincronizado = !snap.metadata.hasPendingWrites;
    _detectarAlertas(lista);
    productos = lista;
    cargado = true;
    notifyListeners();
  }

  void _onMovimientos(QuerySnapshot<Map<String, dynamic>> snap) {
    movimientos = snap.docs.map(MovimientoModel.fromDoc).toList();
    notifyListeners();
  }

  void _detectarAlertas(List<ProductoModel> nuevos) {
    final notif = NotificacionService.instance;
    if (!_primeraLectura) {
      _primeraLectura = true;
      final bajos = nuevos.where((p) => p.stockBajo).toList();
      if (bajos.isNotEmpty) {
        final nombres = bajos.take(3).map((p) => p.nombre).join(', ');
        final extra = bajos.length > 3 ? ' y ${bajos.length - 3} más' : '';
        notif.mostrar(
          id: 1,
          titulo: 'Productos por reabastecer (${bajos.length})',
          cuerpo: '$nombres$extra',
        );
      }
    } else {
      for (final p in nuevos) {
        // Solo avisa cuando CRUZA el mínimo, no en cada cambio.
        if (p.stockBajo && _estadoPrevio[p.id] == false) {
          notif.mostrar(
            id: p.id.hashCode & 0x7fffffff,
            titulo: p.agotado ? 'Producto agotado' : 'Stock bajo',
            cuerpo: '${p.nombre}: quedan ${fmtNum(p.cantidad)} '
                '${p.unidadMedida} (mín. ${fmtNum(p.stockMinimo)})',
          );
        }
      }
    }
    _estadoPrevio
      ..clear()
      ..addEntries(nuevos.map((p) => MapEntry(p.id, p.stockBajo)));
  }

  void _escribir(Future<void> futuro) {
    futuro.catchError((Object e) {
      debugPrint('Error al guardar: $e');
      reportarError('No se pudo guardar el cambio. Intenta de nuevo.');
    });
  }

  String? agregarProducto({
    required String nombre,
    required String categoria,
    required String unidad,
    required double cantidad,
    required double stockMinimo,
    String descripcion = '',
    String proveedorId = '',
    String proveedorNombre = '',
  }) {
    if (_uid == null) return 'Sesión no válida.';
    nombre = nombre.trim();
    if (nombre.isEmpty) return 'Escribe el nombre del producto.';
    if (_nombreExiste(nombre, null)) {
      return 'Ya existe un producto llamado "$nombre".';
    }
    final ref = _colProductos.doc();
    final batch = _db.batch();
    batch.set(ref, {
      'nombre': nombre,
      'categoria': categoria.trim(),
      'unidad': unidad.trim(),
      'cantidad': cantidad,
      'stockMinimo': stockMinimo,
      'descripcion': descripcion.trim(),
      'proveedorId': proveedorId,
      'proveedorNombre': proveedorNombre,
      'creado': Timestamp.now(),
    });
    if (cantidad > 0) {
      batch.set(_colMovimientos.doc(), {
        'productoId': ref.id,
        'productoNombre': nombre,
        'unidad': unidad.trim(),
        'tipo': 'entrada',
        'cantidad': cantidad,
        'nota': 'Stock inicial',
        'inicial': true,
        'fecha': Timestamp.now(),
      });
    }
    _escribir(batch.commit());
    return null;
  }

  String? actualizarProducto({
    required String id,
    required String nombre,
    required String categoria,
    required String unidad,
    required double stockMinimo,
    String descripcion = '',
    String proveedorId = '',
    String proveedorNombre = '',
  }) {
    nombre = nombre.trim();
    if (nombre.isEmpty) return 'Escribe el nombre del producto.';
    if (_nombreExiste(nombre, id)) {
      return 'Ya existe un producto llamado "$nombre".';
    }
    _escribir(_colProductos.doc(id).update({
      'nombre': nombre,
      'categoria': categoria.trim(),
      'unidad': unidad.trim(),
      'stockMinimo': stockMinimo,
      'descripcion': descripcion.trim(),
      'proveedorId': proveedorId,
      'proveedorNombre': proveedorNombre,
    }));
    return null;
  }

  void eliminarProducto(String id) {
    _escribir(_colProductos.doc(id).delete());
  }

  String? registrarMovimiento({
    required ProductoModel producto,
    required bool entrada,
    required double cantidad,
    String nota = '',
  }) {
    if (cantidad <= 0) return 'La cantidad debe ser mayor que cero.';
    if (!entrada && cantidad > producto.cantidad) {
      return 'Solo hay ${fmtNum(producto.cantidad)} ${producto.unidadMedida} '
          'disponibles.';
    }
    final batch = _db.batch();
    // increment() es atómico: dos teléfonos no se pisan los cambios.
    batch.update(_colProductos.doc(producto.id), {
      'cantidad': FieldValue.increment(entrada ? cantidad : -cantidad),
    });
    batch.set(_colMovimientos.doc(), {
      'productoId': producto.id,
      'productoNombre': producto.nombre,
      'unidad': producto.unidadMedida,
      'tipo': entrada ? 'entrada' : 'salida',
      'cantidad': cantidad,
      'nota': nota.trim(),
      'inicial': false,
      'fecha': Timestamp.now(),
    });
    _escribir(batch.commit());
    return null;
  }

  /// Al recibir un pedido: suma al inventario lo que ya existe (mismo
  /// nombre) y crea los productos nuevos.
  void recibirPedido(PedidoModel p) {
    for (final it in p.items) {
      final n = it.nombre.trim().toLowerCase();
      ProductoModel? existente;
      for (final x in productos) {
        if (x.nombre.trim().toLowerCase() == n) {
          existente = x;
          break;
        }
      }
      if (existente != null) {
        registrarMovimiento(
          producto: existente,
          entrada: true,
          cantidad: it.cantidad,
          nota: 'Pedido #${p.codigo} - ${p.proveedorNombre}',
        );
      } else {
        agregarProducto(
          nombre: it.nombre,
          categoria: it.categoria.isEmpty ? 'General' : it.categoria,
          unidad: it.unidad.isEmpty ? 'pzas' : it.unidad,
          cantidad: it.cantidad,
          stockMinimo: 0,
          proveedorId: p.proveedorId,
          proveedorNombre: p.proveedorNombre,
        );
      }
    }
  }

  bool _nombreExiste(String nombre, String? exceptoId) {
    final n = nombre.toLowerCase();
    return productos
        .any((p) => p.id != exceptoId && p.nombre.toLowerCase() == n);
  }
}
