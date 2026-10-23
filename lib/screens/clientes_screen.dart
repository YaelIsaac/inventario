import 'package:flutter/material.dart';

import '../models/vinculo_model.dart';
import '../services/pedidos_service.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';
import 'cliente_detail_screen.dart';
import 'registrar_negocio_screen.dart';

/// Clientes (negocios) del proveedor.
class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  void _registrar(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const RegistrarNegocioScreen()));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [VinculosService.instance, PedidosService.instance]),
      builder: (context, _) {
        final vs = VinculosService.instance;
        final ps = PedidosService.instance;
        final pendientes = vs.pendientes;
        final otros = vs.vinculos.where((v) => !v.pendiente).toList()
          ..sort((a, b) {
            int peso(VinculoModel v) => v.activo ? 0 : 1;
            final c = peso(a).compareTo(peso(b));
            return c != 0
                ? c
                : a.negocioNombre.toLowerCase().compareTo(b.negocioNombre.toLowerCase());
          });
        final invitados = vs.invitacionesPendientes;

        return Scaffold(
          appBar: AppBar(title: const Text('PizzaStock - Clientes')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _registrar(context),
            icon: const Icon(Icons.person_add),
            label: const Text('Registrar negocio'),
          ),
          body: !vs.cargado
              ? const Center(child: CircularProgressIndicator())
              : (vs.vinculos.isEmpty && invitados.isEmpty)
                  ? EmptyState(
                      icono: Icons.groups_outlined,
                      titulo: 'Aún no tienes clientes',
                      subtitulo:
                          'Registra un negocio con su correo, o comparte tu código para que te agreguen.',
                      textoBoton: 'Registrar negocio',
                      onPressed: () => _registrar(context),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 90, top: 6),
                      children: [
                        if (pendientes.isNotEmpty) ...[
                          _titulo('Solicitudes pendientes'),
                          ...pendientes.map((v) => Card(
                                color: Colors.amber[50],
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(v.negocioNombre,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('${v.contacto} • ${v.negocioTelefono}'),
                                      if (v.negocioDireccion.isNotEmpty)
                                        Text(v.negocioDireccion,
                                            style: const TextStyle(
                                                color: Colors.black54)),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                              onPressed: () => vs.rechazar(v),
                                              child: const Text('Rechazar',
                                                  style:
                                                      TextStyle(color: Colors.red))),
                                          ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.green,
                                                  foregroundColor: Colors.white),
                                              onPressed: () => vs.aprobar(v),
                                              child: const Text('Aprobar')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )),
                        ],
                        if (otros.isNotEmpty) ...[
                          _titulo('Mis clientes'),
                          ...otros.map((v) {
                            final saldo = ps.saldoCon(v.negocioId);
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      v.activo ? Colors.red[50] : Colors.grey[200],
                                  child: Icon(Icons.store,
                                      color: v.activo ? kRojo : Colors.grey),
                                ),
                                title: Text(v.negocioNombre,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(!v.activo
                                    ? etiquetaVinculo(v.estado)
                                    : (saldo > 0.005
                                        ? 'Te debe: ${fmtPrecio(saldo)}'
                                        : (saldo < -0.005
                                            ? 'Saldo a favor: ${fmtPrecio(-saldo)}'
                                            : 'Al corriente'))),
                                trailing:
                                    const Icon(Icons.arrow_forward_ios, size: 14),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ClienteDetailScreen(vinculoId: v.id)),
                                ),
                              ),
                            );
                          }),
                        ],
                        if (invitados.isNotEmpty) ...[
                          _titulo('Registrados, aún sin cuenta'),
                          ...invitados.map((i) => Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                child: ListTile(
                                  leading: CircleAvatar(
                                      backgroundColor: Colors.grey[200],
                                      child: const Icon(Icons.mark_email_unread,
                                          color: Colors.grey)),
                                  title: Text(i.nombre,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      '${i.email}\nSe vinculará solo al crear su cuenta'),
                                  isThreeLine: true,
                                  trailing: IconButton(
                                    tooltip: 'Quitar',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => vs.eliminarInvitacion(i),
                                  ),
                                ),
                              )),
                        ],
                      ],
                    ),
        );
      },
    );
  }

  Widget _titulo(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(t,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey)),
      );
}
