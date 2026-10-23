import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/catalogo_item_model.dart';
import 'errores.dart';

/// Catálogo del proveedor: todos los productos que puede surtir.
class CatalogoService extends ChangeNotifier {
  CatalogoService._();
  static final CatalogoService instance = CatalogoService._();

  List<CatalogoItemModel> items = [];
  bool cargado = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;

  FirebaseFirestore get _db => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('catalogo');

  /// Catálogo de cualquier proveedor (lo usa el negocio al hacer un pedido).
  static Stream<List<CatalogoItemModel>> streamDe(String proveedorId) {
    return FirebaseFirestore.instance
        .collection('catalogo')
        .where('proveedorId', isEqualTo: proveedorId)
        .snapshots()
        .map((s) {
      final l = s.docs.map(CatalogoItemModel.fromDoc).toList()
        ..sort((a, b) {
          final c = a.categoria.toLowerCase().compareTo(b.categoria.toLowerCase());
          return c != 0 ? c : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
        });
      return l;
    });
  }

  List<String> get categorias {
    final s = items.map((i) => i.categoria).toSet().toList()..sort();
    return s;
  }

  void iniciar(String uid) {
    if (_uid == uid) return;
    detener();
    _uid = uid;
    _sub = _col.where('proveedorId', isEqualTo: uid).snapshots().listen((snap) {
      items = snap.docs.map(CatalogoItemModel.fromDoc).toList()
        ..sort((a, b) {
          final c = a.categoria.toLowerCase().compareTo(b.categoria.toLowerCase());
          return c != 0 ? c : a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
        });
      cargado = true;
      notifyListeners();
    }, onError: (Object e) => debugPrint('Catálogo: $e'));
  }

  void detener() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    items = [];
    cargado = false;
    notifyListeners();
  }

  void _escribir(Future<void> f) {
    f.catchError((Object e) {
      debugPrint('Error al guardar: $e');
      reportarError('No se pudo guardar el cambio. Intenta de nuevo.');
    });
  }

  String? guardarItem({
    String? id,
    required String nombre,
    required String descripcion,
    required String categoria,
    required String unidad,
    required double precio,
    required bool disponible,
  }) {
    final uid = _uid;
    if (uid == null) return 'Sesión no válida.';
    nombre = nombre.trim();
    if (nombre.isEmpty) return 'Escribe el nombre.';
    if (precio < 0) return 'El precio no es válido.';
    final dup = items.any(
        (i) => i.id != id && i.nombre.toLowerCase() == nombre.toLowerCase());
    if (dup) return 'Ya tienes "$nombre" en tu catálogo.';
    final data = {
      'proveedorId': uid,
      'nombre': nombre,
      'descripcion': descripcion.trim(),
      'categoria': categoria.trim(),
      'unidad': unidad.trim(),
      'precio': precio,
      'disponible': disponible,
    };
    if (id == null) {
      _escribir(_col.doc().set({...data, 'creado': Timestamp.now()}));
    } else {
      _escribir(_col.doc(id).update(data));
    }
    return null;
  }

  void cambiarDisponible(String id, bool v) =>
      _escribir(_col.doc(id).update({'disponible': v}));

  void eliminarItem(String id) => _escribir(_col.doc(id).delete());
}
