import 'package:flutter/material.dart';

import '../services/inventario_service.dart';
import '../services/notificacion_service.dart';
import '../theme.dart';
import 'detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: InventarioService.instance,
      builder: (context, _) {
        final svc = InventarioService.instance;
        final bajos = svc.productosBajos;
        final recientes = svc.movimientos.take(30).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('PizzaStock - Notificaciones'),
            actions: [
              IconButton(
                tooltip: 'Enviar notificación de prueba',
                icon: const Icon(Icons.notifications_active),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await NotificacionService.instance.mostrar(
                    id: 99,
                    titulo: 'PizzaStock',
                    cuerpo: 'Las notificaciones funcionan correctamente.',
                  );
                  messenger.showSnackBar(const SnackBar(
                      content: Text(
                          'Notificación de prueba enviada. Si no la ves, '
                          'activa los permisos en Ajustes del teléfono.')));
                },
              ),
            ],
          ),
          body: (bajos.isEmpty && recientes.isEmpty)
              ? const EmptyState(
                  icono: Icons.notifications_none,
                  titulo: 'Sin notificaciones',
                  subtitulo:
                      'Aquí verás las alertas de stock bajo y tu actividad.',
                )
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    if (bajos.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Alertas activas',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      ...bajos.map((p) => ListTile(
                            leading: Icon(Icons.warning,
                                color:
                                    p.agotado ? Colors.grey[700] : Colors.red),
                            title: Text(
                                '${p.agotado ? 'Agotado' : 'Stock bajo'}: ${p.nombre}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                'Quedan ${fmtNum(p.cantidad)} ${p.unidadMedida} '
                                '(mín. ${fmtNum(p.stockMinimo)} ${p.unidadMedida})'),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DetailScreen(productoId: p.id)),
                            ),
                          )),
                      const Divider(),
                    ],
                    if (recientes.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text('Actividad reciente',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      ...recientes.map((m) => ListTile(
                            leading: Icon(
                                m.esEntrada
                                    ? Icons.check_circle
                                    : Icons.remove_circle,
                                color: m.esEntrada ? Colors.green : Colors.red),
                            title: Text(
                                m.inicial
                                    ? 'Producto registrado'
                                    : (m.esEntrada
                                        ? 'Entrada registrada'
                                        : 'Salida registrada'),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                '${m.productoNombre} (${m.esEntrada ? '+' : '-'}'
                                '${fmtNum(m.cantidad)} ${m.unidad}) • ${fmtFecha(m.fecha)}'),
                          )),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
