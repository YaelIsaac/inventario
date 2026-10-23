import 'package:flutter/material.dart';

import '../services/pedidos_service.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';

class ProveedorReportsScreen extends StatefulWidget {
  const ProveedorReportsScreen({super.key});

  @override
  State<ProveedorReportsScreen> createState() => _ProveedorReportsScreenState();
}

class _ProveedorReportsScreenState extends State<ProveedorReportsScreen> {
  int dias = 30; // 0 = todo

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [PedidosService.instance, VinculosService.instance]),
      builder: (context, _) {
        final ps = PedidosService.instance;
        final desde =
            dias == 0 ? null : DateTime.now().subtract(Duration(days: dias));
        bool enPeriodo(DateTime d) => desde == null || d.isAfter(desde);

        final entregados = ps.pedidos
            .where((p) => p.estado == 'entregado' && enPeriodo(p.creado))
            .toList();
        final ventas = entregados.fold(0.0, (s, p) => s + p.total);
        final cobrado = ps.abonos
            .where((a) => enPeriodo(a.fecha))
            .fold(0.0, (s, a) => s + a.monto);

        // Ventas por cliente.
        final porCliente = <String, double>{};
        for (final p in entregados) {
          porCliente[p.negocioNombre] =
              (porCliente[p.negocioNombre] ?? 0) + p.total;
        }
        final topClientes = porCliente.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Productos más vendidos.
        final porProducto = <String, double>{};
        final unidad = <String, String>{};
        for (final p in entregados) {
          for (final i in p.items) {
            porProducto[i.nombre] = (porProducto[i.nombre] ?? 0) + i.cantidad;
            unidad[i.nombre] = i.unidad;
          }
        }
        final topProductos = porProducto.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Clientes activos que llevan más de 30 días sin pedir.
        final limite = DateTime.now().subtract(const Duration(days: 30));
        final inactivos = VinculosService.instance.activos.where((v) {
          final suyos = ps.pedidosCon(v.negocioId)
              .where((p) => p.estado != 'cancelado' && p.estado != 'rechazado');
          if (suyos.isEmpty) return true;
          return suyos.every((p) => p.creado.isBefore(limite));
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Reportes')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    for (final op in const [
                      [7, '7 días'],
                      [30, '30 días'],
                      [0, 'Todo'],
                    ])
                      ChoiceChip(
                        label: Text(op[1] as String),
                        selected: dias == op[0],
                        selectedColor: kRojo,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                            color: dias == op[0] ? Colors.white : Colors.black),
                        onSelected: (_) => setState(() => dias = op[0] as int),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _tarjeta(fmtPrecio(ventas), 'Ventas entregadas',
                        Colors.green[50]!, Colors.green),
                    const SizedBox(width: 10),
                    _tarjeta('${entregados.length}', 'Pedidos entregados',
                        Colors.blue[50]!, Colors.blue),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _tarjeta(fmtPrecio(cobrado), 'Cobrado (abonos)',
                        Colors.amber[50]!, Colors.orange),
                    const SizedBox(width: 10),
                    _tarjeta(
                        fmtPrecio(ps.saldoTotal > 0 ? ps.saldoTotal : 0),
                        'Por cobrar (total)',
                        Colors.red[50]!,
                        kRojo),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Ventas por cliente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (topClientes.isEmpty)
                  const Text('Aún no hay ventas en este periodo.',
                      style: TextStyle(color: Colors.grey)),
                ...topClientes.take(6).map((e) => _barra(
                    e.key, e.value / topClientes.first.value, fmtPrecio(e.value))),
                const SizedBox(height: 20),
                const Text('Productos más vendidos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (topProductos.isEmpty)
                  const Text('Aún no hay productos vendidos.',
                      style: TextStyle(color: Colors.grey)),
                ...topProductos.take(6).map((e) => _barra(
                    e.key,
                    e.value / topProductos.first.value,
                    '${fmtNum(e.value)} ${unidad[e.key] ?? ''}')),
                const SizedBox(height: 20),
                const Text('Clientes sin pedir en 30 días',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                if (inactivos.isEmpty)
                  const Text('Todos tus clientes activos han pedido recientemente.',
                      style: TextStyle(color: Colors.grey)),
                ...inactivos.map((v) => Card(
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.schedule, color: Colors.orange),
                        title: Text(v.negocioNombre),
                        subtitle: Text(v.negocioTelefono.isEmpty
                            ? v.negocioEmail
                            : v.negocioTelefono),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tarjeta(String valor, String etiqueta, Color bg, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(valor,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(etiqueta,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _barra(String nombre, double progreso, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(nombre,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500))),
              Text(total, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              color: kRojo,
              backgroundColor: Colors.grey[200]),
        ],
      ),
    );
  }
}
