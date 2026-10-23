import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pedido_model.dart';
import '../screens/pedido_detail_screen.dart';
import '../theme.dart';

class EstadoPedidoChip extends StatelessWidget {
  final String estado;
  const EstadoPedidoChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(etiquetaEstado(estado),
          style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: colorEstado(estado),
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}

/// Fila de un pedido. [proveedor] = true cuando lo ve el proveedor.
class PedidoTile extends StatelessWidget {
  final PedidoModel pedido;
  final bool proveedor;
  const PedidoTile({super.key, required this.pedido, required this.proveedor});

  @override
  Widget build(BuildContext context) {
    final p = pedido;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red[50],
          child: const Icon(Icons.local_shipping, color: kRojo),
        ),
        title: Text(
            '#${p.codigo} • ${proveedor ? p.negocioNombre : p.proveedorNombre}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
            '${fmtFecha(p.creado)}\n${p.totalArticulos} producto(s) • ${fmtPrecio(p.total)}'),
        isThreeLine: true,
        trailing: EstadoPedidoChip(p.estado),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  PedidoDetailScreen(pedidoId: p.id, proveedor: proveedor)),
        ),
      ),
    );
  }
}

/// Tarjeta de saldo (lo que se debe).
class SaldoCard extends StatelessWidget {
  final double saldo;
  final String etiquetaDeuda;
  const SaldoCard({super.key, required this.saldo, required this.etiquetaDeuda});

  @override
  Widget build(BuildContext context) {
    final aFavor = saldo < 0;
    final cero = saldo.abs() < 0.005;
    final color = cero ? Colors.green : (aFavor ? Colors.blue : Colors.orange);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cero ? 'Sin saldo pendiente' : (aFavor ? 'Saldo a favor' : etiquetaDeuda),
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 4),
          Text(fmtPrecio(saldo.abs()),
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

/// Datos de la cuenta del proveedor para transferencias (solo texto).
class CobroInfoCard extends StatelessWidget {
  final String proveedorId;
  const CobroInfoCard({super.key, required this.proveedorId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('cobros')
          .doc(proveedorId)
          .snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data() ?? <String, dynamic>{};
        final cuenta = (d['cuenta'] as String?) ?? '';
        if (cuenta.trim().isEmpty) {
          return const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('Sin cuenta para transferencias'),
              subtitle: Text('El proveedor aún no registra sus datos de pago.'),
            ),
          );
        }
        final titular = (d['titular'] as String?) ?? '';
        final banco = (d['banco'] as String?) ?? '';
        final instr = (d['instrucciones'] as String?) ?? '';
        return Card(
          color: Colors.amber[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Datos para transferencia',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (titular.isNotEmpty) Text('Titular: $titular'),
                if (banco.isNotEmpty) Text('Banco: $banco'),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText('Cuenta: $cuenta',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      tooltip: 'Copiar',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: cuenta));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cuenta copiada')));
                      },
                    ),
                  ],
                ),
                if (instr.isNotEmpty)
                  Text(instr, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        );
      },
    );
  }
}
