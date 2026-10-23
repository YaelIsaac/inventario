import 'package:cloud_firestore/cloud_firestore.dart';

class MovimientoModel {
  final String id;
  final String productoId;
  final String productoNombre;
  final String unidad;
  final bool esEntrada;
  final double cantidad;
  final String nota;
  final bool inicial;
  final DateTime fecha;

  const MovimientoModel({
    required this.id,
    required this.productoId,
    required this.productoNombre,
    required this.unidad,
    required this.esEntrada,
    required this.cantidad,
    required this.nota,
    required this.inicial,
    required this.fecha,
  });

  factory MovimientoModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final ts = d['fecha'];
    return MovimientoModel(
      id: doc.id,
      productoId: (d['productoId'] as String?) ?? '',
      productoNombre: (d['productoNombre'] as String?) ?? '',
      unidad: (d['unidad'] as String?) ?? '',
      esEntrada: d['tipo'] == 'entrada',
      cantidad: (d['cantidad'] as num?)?.toDouble() ?? 0,
      nota: (d['nota'] as String?) ?? '',
      inicial: (d['inicial'] as bool?) ?? false,
      fecha: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
