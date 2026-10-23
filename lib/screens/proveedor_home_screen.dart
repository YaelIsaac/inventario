import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navegacion.dart';
import '../services/auth_service.dart';
import '../services/pedidos_service.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';
import '../widgets/pedido_widgets.dart';

class ProveedorHomeScreen extends StatelessWidget {
  const ProveedorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        AuthService.instance,
        PedidosService.instance,
        VinculosService.instance,
      ]),
      builder: (context, _) {
        final perfil = AuthService.instance.perfil;
        final ps = PedidosService.instance;
        final vs = VinculosService.instance;
        final nuevos = ps.pedidos.where((p) => p.estado == 'nuevo').toList();
        final enCurso =
            ps.pedidos.where((p) => p.estado == 'aceptado' || p.estado == 'enviado').length;

        return Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  decoration: const BoxDecoration(
                    color: kRojo,
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping,
                          color: Colors.amber, size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(perfil?.titulo ?? 'PizzaStock',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold)),
                                ),
                                if (perfil?.verificado ?? false)
                                  const Padding(
                                    padding: EdgeInsets.only(left: 6),
                                    child: Icon(Icons.verified,
                                        color: Colors.lightBlueAccent, size: 20),
                                  ),
                              ],
                            ),
                            const Text('Panel de proveedor',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _tarjeta('${nuevos.length}', 'Pedidos nuevos',
                              Colors.blue[50]!, Colors.blue),
                          const SizedBox(width: 10),
                          _tarjeta('$enCurso', 'En curso', Colors.amber[50]!,
                              Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _tarjeta('${vs.activos.length}', 'Clientes activos',
                              Colors.green[50]!, Colors.green),
                          const SizedBox(width: 10),
                          _tarjeta(fmtPrecio(ps.saldoTotal > 0 ? ps.saldoTotal : 0),
                              'Por cobrar', Colors.red[50]!, kRojo),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (vs.pendientes.isNotEmpty)
                        Card(
                          color: Colors.amber[50],
                          child: ListTile(
                            leading: const Icon(Icons.person_add, color: Colors.orange),
                            title: Text(
                                '${vs.pendientes.length} solicitud(es) de clientes'),
                            subtitle: const Text('Toca para revisarlas'),
                            onTap: () => provTab.value = 2,
                          ),
                        ),
                      if ((perfil?.codigo ?? '').isNotEmpty)
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.qr_code, color: kRojo),
                            title: const Text('Tu código de proveedor'),
                            subtitle: const Text(
                                'Dáselo a tus negocios para que te agreguen'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(perfil!.codigo,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 2)),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 18),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: perfil.codigo));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Código copiado')));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      const Text('Pedidos por atender',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      if (!ps.cargado)
                        const Center(child: CircularProgressIndicator())
                      else if (nuevos.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.check_circle, color: Colors.green),
                            title: Text('Todo al día'),
                            subtitle: Text('No hay pedidos nuevos.'),
                          ),
                        ),
                    ],
                  ),
                ),
                ...nuevos.take(5).map((p) => PedidoTile(pedido: p, proveedor: true)),
                const SizedBox(height: 20),
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
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(etiqueta,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}
