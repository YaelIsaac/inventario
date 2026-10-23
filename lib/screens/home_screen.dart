import 'package:flutter/material.dart';

import '../services/inventario_service.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/pedidos_service.dart';
import 'detail_screen.dart';
import 'notifications_screen.dart';
import '../navegacion.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable:
          Listenable.merge([InventarioService.instance, PedidosService.instance]),
      builder: (context, _) {
        final svc = InventarioService.instance;
        final productosBajos = svc.productosBajos;
        final nombre =
            AuthService.instance.perfil?.nombre.trim().split(' ').first ?? '';
        final ps = PedidosService.instance;

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabecera roja
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  decoration: const BoxDecoration(
                    color: kRojo,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.local_pizza,
                              color: Colors.amber, size: 36),
                          SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PizzaStock',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold)),
                              Text('Tu inventario, siempre en control',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      Tooltip(
                        message: svc.sincronizado
                            ? 'Datos sincronizados'
                            : 'Pendiente de sincronizar',
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(
                            svc.sincronizado
                                ? Icons.cloud_done
                                : Icons.cloud_upload,
                            color: kRojo,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre.isEmpty ? '¡Hola!' : '¡Hola, $nombre!',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const Text('Aquí tienes el resumen de tu inventario hoy.',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),

                      // Tarjetas resumen
                      Row(
                        children: [
                          _buildSummaryCard('${svc.productos.length}',
                              'Productos registrados', Colors.green[50]!,
                              Colors.green),
                          const SizedBox(width: 10),
                          _buildSummaryCard('${productosBajos.length}',
                              'En stock mínimo', Colors.amber[50]!,
                              Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildSummaryCard('${ps.activos}', 'Pedidos en curso',
                              Colors.blue[50]!, Colors.blue),
                          const SizedBox(width: 10),
                          _buildSummaryCard(
                              fmtPrecio(ps.saldoTotal > 0 ? ps.saldoTotal : 0),
                              'Por pagar a proveedores',
                              Colors.red[50]!,
                              kRojo),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (!svc.cargado)
                        const Center(child: CircularProgressIndicator())
                      else if (svc.productos.isEmpty)
                        SizedBox(
                          height: 300,
                          child: EmptyState(
                            icono: Icons.inventory_2_outlined,
                            titulo: 'Aún no tienes productos',
                            subtitulo:
                                'Registra el primero: queso, cajas, fresas, '
                                'vasitos... lo que quieras controlar.',
                            textoBoton: 'Registrar producto',
                            onPressed: irANuevoProducto,
                          ),
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Alertas de reabastecimiento',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            if (productosBajos.isNotEmpty)
                              GestureDetector(
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const NotificationsScreen())),
                                child: const Text('Ver todas',
                                    style: TextStyle(
                                        color: kRojo,
                                        fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (productosBajos.isEmpty)
                          const Card(
                            child: ListTile(
                              leading: Icon(Icons.check_circle,
                                  color: Colors.green),
                              title: Text('Todo en orden'),
                              subtitle:
                                  Text('Ningún producto está bajo su mínimo.'),
                            ),
                          ),
                        ...productosBajos.map((p) => Card(
                              child: ListTile(
                                leading: Icon(Icons.warning,
                                    color: p.agotado
                                        ? Colors.grey[700]
                                        : Colors.red),
                                title: Text(p.nombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    '${fmtNum(p.cantidad)} ${p.unidadMedida}  '
                                    '(mín. ${fmtNum(p.stockMinimo)} ${p.unidadMedida})'),
                                trailing:
                                    const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          DetailScreen(productoId: p.id)),
                                ),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(
      String count, String label, Color bg, Color textColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(count,
                style: TextStyle(
                    fontSize: 24,
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
}
