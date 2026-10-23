import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/inventario_service.dart';
import '../theme.dart';
import 'cuenta_screen.dart';
import 'notifications_screen.dart';
import 'reports_screen.dart';

class NegocioMasScreen extends StatelessWidget {
  const NegocioMasScreen({super.key});

  void _ir(BuildContext context, Widget pantalla) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => pantalla));

  @override
  Widget build(BuildContext context) {
    final perfil = AuthService.instance.perfil;
    return Scaffold(
      appBar: AppBar(title: const Text('PizzaStock - Más')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const CircleAvatar(
                  backgroundColor: kRojo,
                  child: Icon(Icons.store, color: Colors.white)),
              title: Text(perfil?.titulo ?? 'Mi negocio'),
              subtitle: Text(perfil?.email ?? ''),
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: InventarioService.instance,
            builder: (context, _) {
              final n = InventarioService.instance.productosBajos.length;
              return _opcion(
                  context,
                  Icons.notifications,
                  'Notificaciones',
                  n > 0 ? '$n producto(s) por reabastecer' : 'Alertas y actividad',
                  const NotificationsScreen());
            },
          ),
          _opcion(context, Icons.bar_chart, 'Reportes',
              'Consumo, entradas, salidas y compras', const ReportsScreen()),
          _opcion(context, Icons.manage_accounts, 'Mi cuenta',
              'Datos del negocio y dirección de entrega', const CuentaScreen()),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesión'),
              onTap: () {
                Navigator.of(context).popUntil((r) => r.isFirst);
                AuthService.instance.cerrarSesion();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _opcion(BuildContext context, IconData icono, String titulo,
      String subtitulo, Widget destino) {
    return Card(
      child: ListTile(
        leading: Icon(icono, color: kRojo),
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitulo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => _ir(context, destino),
      ),
    );
  }
}
