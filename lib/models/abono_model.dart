import 'package:cloud_firestore/cloud_firestore.dart';

/// Pago que un negocio hizo a un proveedor (lo registra el proveedor).
class AbonoModel {
  final String id;
  final String proveedorId;
  final String negocioId;
  final double monto;
  final String nota;
  final DateTime fecha;

  const AbonoModel({
    required this.id,
    required this.proveedorId,
    required this.negocioId,
    required this.monto,
    required this.nota,
    required this.fecha,
  });

  factory AbonoModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final ts = d['fecha'];
    return AbonoModel(
      id: doc.id,
      proveedorId: (d['proveedorId'] as String?) ?? '',
      negocioId: (d['negocioId'] as String?) ?? '',
      monto: (d['monto'] as num?)?.toDouble() ?? 0,
      nota: (d['nota'] as String?) ?? '',
      fecha: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
