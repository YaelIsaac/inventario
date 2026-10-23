import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class AdminResumenScreen extends StatefulWidget {
  const AdminResumenScreen({super.key});

  @override
  State<AdminResumenScreen> createState() => _AdminResumenScreenState();
}

class _AdminResumenScreenState extends State<AdminResumenScreen> {
  late Future<Map<String, int>> _datos = _cargar();

  Future<int> _contar(Query<Map<String, dynamic>> q) async {
    final r = await q.count().get();
    return r.count ?? 0;
  }

  Future<Map<String, int>> _cargar() async {
    final db = FirebaseFirestore.instance;
    final users = db.collection('users');
    final r = await Future.wait<int>([
      _contar(users.where('rol', isEqualTo: 'proveedor')),
      _contar(users.where('rol', isEqualTo: 'negocio')),
      _contar(users.where('rol', isEqualTo: 'admin')),
      _contar(users
          .where('rol', isEqualTo: 'proveedor')
          .where('verificado', isEqualTo: false)),
      _contar(users.where('activo', isEqualTo: false)),
      _contar(db.collection('vinculos').where('estado', isEqualTo: 'activo')),
      _contar(db.collection('pedidos')),
      _contar(db.collection('pedidos').where('estado', isEqualTo: 'entregado')),
    ]);
    return {
      'Proveedores': r[0],
      'Negocios': r[1],
      'Administradores': r[2],
      'Proveedores por verificar': r[3],
      'Cuentas suspendidas': r[4],
      'Relaciones activas': r[5],
      'Pedidos totales': r[6],
      'Pedidos entregados': r[7],
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PizzaStock - Plataforma'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _datos = _cargar()),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: AuthService.instance.cerrarSesion,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, int>>(
        future: _datos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return const EmptyState(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar las estadísticas',
                subtitulo: 'Revisa tu conexión y las reglas de Firestore.');
          }
          final d = snap.data!;
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: d.entries.map((e) {
              final alerta = (e.key == 'Proveedores por verificar' ||
                      e.key == 'Cuentas suspendidas') &&
                  e.value > 0;
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: alerta ? Colors.amber[50] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(blurRadius: 3, color: Colors.black12)
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${e.value}',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: alerta ? Colors.orange : kRojo)),
                    Text(e.key,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
