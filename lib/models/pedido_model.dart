import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PedidoItem {
  final String catalogoId;
  final String nombre;
  final String unidad;
  final String categoria;
  final double precio;
  final double cantidad;

  const PedidoItem({
    required this.catalogoId,
    required this.nombre,
    required this.unidad,
    required this.categoria,
    required this.precio,
    required this.cantidad,
  });

  double get subtotal => precio * cantidad;

  Map<String, dynamic> toMap() => {
        'catalogoId': catalogoId,
        'nombre': nombre,
        'unidad': unidad,
        'categoria': categoria,
        'precio': precio,
        'cantidad': cantidad,
      };

  factory PedidoItem.fromMap(Map<String, dynamic> m) => PedidoItem(
        catalogoId: (m['catalogoId'] as String?) ?? '',
        nombre: (m['nombre'] as String?) ?? '',
        unidad: (m['unidad'] as String?) ?? '',
        categoria: (m['categoria'] as String?) ?? '',
        precio: (m['precio'] as num?)?.toDouble() ?? 0,
        cantidad: (m['cantidad'] as num?)?.toDouble() ?? 1,
      );
}

String etiquetaEstado(String e) {
  switch (e) {
    case 'nuevo':
      return 'Nuevo';
    case 'aceptado':
      return 'Aceptado';
    case 'enviado':
      return 'Enviado';
    case 'entregado':
      return 'Entregado';
    case 'rechazado':
      return 'Rechazado';
    case 'cancelado':
      return 'Cancelado';
    default:
      return e;
  }
}

Color colorEstado(String e) {
  switch (e) {
    case 'nuevo':
      return Colors.blue;
    case 'aceptado':
      return Colors.orange;
    case 'enviado':
      return Colors.purple;
    case 'entregado':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

class PedidoModel {
  final String id;
  final String proveedorId;
  final String negocioId;
  final String proveedorNombre;
  final String negocioNombre;
  final String negocioTelefono;
  final String direccionEntrega;
  final String notas;
  final String fechaDeseada;
  final List<PedidoItem> items;
  final double total;
  final String estado; // nuevo|aceptado|enviado|entregado|rechazado|cancelado
  final bool tieneComprobante;
  final bool inventarioActualizado;
  final DateTime creado;

  const PedidoModel({
    required this.id,
    required this.proveedorId,
    required this.negocioId,
    required this.proveedorNombre,
    required this.negocioNombre,
    required this.negocioTelefono,
    required this.direccionEntrega,
    required this.notas,
    required this.fechaDeseada,
    required this.items,
    required this.total,
    required this.estado,
    required this.tieneComprobante,
    required this.inventarioActualizado,
    required this.creado,
  });

  bool get activo =>
      estado == 'nuevo' || estado == 'aceptado' || estado == 'enviado';
  String get codigo =>
      (id.length >= 5 ? id.substring(0, 5) : id).toUpperCase();
  int get totalArticulos => items.length;

  String? get siguienteEstado {
    switch (estado) {
      case 'nuevo':
        return 'aceptado';
      case 'aceptado':
        return 'enviado';
      case 'enviado':
        return 'entregado';
      default:
        return null;
    }
  }

  factory PedidoModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final ts = d['creado'];
    final raw = (d['items'] as List?) ?? const [];
    return PedidoModel(
      id: doc.id,
      proveedorId: (d['proveedorId'] as String?) ?? '',
      negocioId: (d['negocioId'] as String?) ?? '',
      proveedorNombre: (d['proveedorNombre'] as String?) ?? '',
      negocioNombre: (d['negocioNombre'] as String?) ?? '',
      negocioTelefono: (d['negocioTelefono'] as String?) ?? '',
      direccionEntrega: (d['direccionEntrega'] as String?) ?? '',
      notas: (d['notas'] as String?) ?? '',
      fechaDeseada: (d['fechaDeseada'] as String?) ?? '',
      items: raw
          .map((e) => PedidoItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      total: (d['total'] as num?)?.toDouble() ?? 0,
      estado: (d['estado'] as String?) ?? 'nuevo',
      tieneComprobante: (d['tieneComprobante'] as bool?) ?? false,
      inventarioActualizado: (d['inventarioActualizado'] as bool?) ?? false,
      creado: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
