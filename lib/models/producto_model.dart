import 'package:cloud_firestore/cloud_firestore.dart';

class ProductoModel {
  final String id;
  final String nombre;
  final String categoria;
  final String unidadMedida;
  final double cantidad;
  final double stockMinimo;
  final String descripcion;
  final String proveedorId;
  final String proveedorNombre;

  const ProductoModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.unidadMedida,
    required this.cantidad,
    required this.stockMinimo,
    this.descripcion = '',
    this.proveedorId = '',
    this.proveedorNombre = '',
  });

  bool get agotado => cantidad <= 0;
  bool get stockBajo => cantidad <= stockMinimo;

  String get estado => agotado
      ? 'Agotado'
      : (stockBajo ? 'Stock bajo' : 'En stock');

  factory ProductoModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return ProductoModel(
      id: doc.id,
      nombre: (d['nombre'] as String?) ?? 'Sin nombre',
      categoria: (d['categoria'] as String?) ?? 'General',
      unidadMedida: (d['unidad'] as String?) ?? 'pzas',
      cantidad: (d['cantidad'] as num?)?.toDouble() ?? 0,
      stockMinimo: (d['stockMinimo'] as num?)?.toDouble() ?? 0,
      descripcion: (d['descripcion'] as String?) ?? '',
      proveedorId: (d['proveedorId'] as String?) ?? '',
      proveedorNombre: (d['proveedorNombre'] as String?) ?? '',
    );
  }
}
