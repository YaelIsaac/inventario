import 'package:cloud_firestore/cloud_firestore.dart';

/// Producto que ofrece un proveedor.
class CatalogoItemModel {
  final String id;
  final String proveedorId;
  final String nombre;
  final String descripcion;
  final String categoria;
  final String unidad;
  final double precio;
  final bool disponible;

  const CatalogoItemModel({
    required this.id,
    required this.proveedorId,
    required this.nombre,
    required this.descripcion,
    required this.categoria,
    required this.unidad,
    required this.precio,
    required this.disponible,
  });

  factory CatalogoItemModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return CatalogoItemModel(
      id: doc.id,
      proveedorId: (d['proveedorId'] as String?) ?? '',
      nombre: (d['nombre'] as String?) ?? 'Sin nombre',
      descripcion: (d['descripcion'] as String?) ?? '',
      categoria: (d['categoria'] as String?) ?? 'General',
      unidad: (d['unidad'] as String?) ?? 'pzas',
      precio: (d['precio'] as num?)?.toDouble() ?? 0,
      disponible: (d['disponible'] as bool?) ?? true,
    );
  }
}
