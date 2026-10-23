import 'package:flutter/material.dart';

import '../services/inventario_service.dart';
import '../services/pedidos_service.dart';
import '../theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int dias = 30; // 0 = todo

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([InventarioService.instance, PedidosService.instance]),
      builder: (context, _) {
        final desde = dias == 0
            ? null
            : DateTime.now().subtract(Duration(days: dias));
        // El stock inicial no cuenta como compra ni como consumo.
        final movs = InventarioService.instance.movimientos
            .where((m) => !m.inicial && (desde == null || m.fecha.isAfter(desde)))
            .toList();

        final entregados = PedidosService.instance.pedidos
            .where((p) =>
                p.estado == 'entregado' &&
                (desde == null || p.creado.isAfter(desde)))
            .toList();
        final ventas = entregados.fold(0.0, (s, p) => s + p.total);

        final entradas = movs.where((m) => m.esEntrada).length;
        final salidas = movs.where((m) => !m.esEntrada).length;

        // Consumo total por producto (suma de salidas).
        final consumo = <String, double>{};
        final unidad = <String, String>{};
        final nombre = <String, String>{};
        for (final m in movs.where((m) => !m.esEntrada)) {
          consumo[m.productoId] = (consumo[m.productoId] ?? 0) + m.cantidad;
          unidad[m.productoId] = m.unidad;
          nombre[m.productoId] = m.productoNombre;
        }
        final top = consumo.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final maximo = top.isEmpty ? 1.0 : top.first.value;

        return Scaffold(
          appBar: AppBar(title: const Text('PizzaStock - Reportes')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
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
                        onSelected: (_) =>
                            setState(() => dias = op[0] as int),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildReportCard('$entradas', 'Total entradas',
                        Colors.green[50]!, Colors.green),
                    const SizedBox(width: 10),
                    _buildReportCard('$salidas', 'Total salidas',
                        Colors.red[50]!, Colors.red),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildReportCard(fmtPrecio(ventas), 'Compras a proveedores',
                        Colors.amber[50]!, Colors.orange),
                    const SizedBox(width: 10),
                    _buildReportCard('${entregados.length}', 'Pedidos recibidos',
                        Colors.blue[50]!, Colors.blue),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Productos más consumidos',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (top.isEmpty)
                  const Text('Aún no hay salidas en este periodo.',
                      style: TextStyle(color: Colors.grey)),
                ...top.take(5).map((e) => _buildConsumptionBar(
                      nombre[e.key] ?? '',
                      e.value / maximo,
                      '${fmtNum(e.value)} ${unidad[e.key] ?? ''}',
                    )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportCard(
      String value, String label, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textColor)),
            const SizedBox(height: 5),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumptionBar(String name, double progress, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
              ),
              Text(total, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              color: kRojo,
              backgroundColor: Colors.grey[200]),
        ],
      ),
    );
  }
}
