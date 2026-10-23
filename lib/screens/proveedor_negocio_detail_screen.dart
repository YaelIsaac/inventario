import 'package:flutter/material.dart';

import '../models/vinculo_model.dart';
import '../services/pedidos_service.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';
import '../widgets/pedido_widgets.dart';
import 'nuevo_pedido_screen.dart';

/// Un proveedor visto por el negocio: pedir, saldo, pagos y pedidos.
class ProveedorNegocioDetailScreen extends StatelessWidget {
  final String vinculoId;
  const ProveedorNegocioDetailScreen({super.key, required this.vinculoId});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [VinculosService.instance, PedidosService.instance]),
      builder: (context, _) {
        final v = VinculosService.instance.porId(vinculoId);
        if (v == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Proveedor')),
            body: const EmptyState(
                icono: Icons.local_shipping_outlined,
                titulo: 'Proveedor no disponible',
                subtitulo: 'Puede que la relación ya no exista.'),
          );
        }
        final ps = PedidosService.instance;
        final pedidos = ps.pedidosCon(v.proveedorId);
        final abonos = ps.abonosCon(v.proveedorId);

        return Scaffold(
          appBar: AppBar(title: Text(v.proveedorNombre)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!v.activo)
                  Card(
                    color: Colors.amber[50],
                    child: ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: Text('Relación ${etiquetaVinculo(v.estado).toLowerCase()}'),
                      subtitle: const Text('No puedes hacer pedidos por ahora.'),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kRojo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Hacer pedido', style: TextStyle(fontSize: 16)),
                    onPressed: v.activo
                        ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => NuevoPedidoScreen(vinculo: v)),
                            )
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                SaldoCard(
                    saldo: ps.saldoCon(v.proveedorId), etiquetaDeuda: 'Por pagar'),
                const SizedBox(height: 8),
                CobroInfoCard(proveedorId: v.proveedorId),
                const SizedBox(height: 8),
                const Text('Pagos registrados',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (abonos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('El proveedor aún no registra pagos.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ...abonos.map((a) => Card(
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.payments, color: Colors.green),
                        title: Text(fmtPrecio(a.monto)),
                        subtitle: Text(
                            '${fmtFecha(a.fecha)}${a.nota.isEmpty ? '' : ' • ${a.nota}'}'),
                      ),
                    )),
                const SizedBox(height: 16),
                const Text('Pedidos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (pedidos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('Todavía no le has hecho pedidos.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ...pedidos.map((p) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: PedidoTile(pedido: p, proveedor: false),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
