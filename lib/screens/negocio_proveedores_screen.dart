import 'package:flutter/material.dart';

import '../models/vinculo_model.dart';
import '../services/pedidos_service.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';
import '../widgets/pedido_widgets.dart';
import 'agregar_proveedor_screen.dart';
import 'proveedor_negocio_detail_screen.dart';

/// Pestaña "Proveedores" del negocio: mis proveedores y mis pedidos.
class NegocioProveedoresScreen extends StatelessWidget {
  const NegocioProveedoresScreen({super.key});

  void _agregar(BuildContext context) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const AgregarProveedorScreen()));

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PizzaStock - Proveedores'),
          actions: [
            IconButton(
              tooltip: 'Agregar proveedor',
              icon: const Icon(Icons.person_add),
              onPressed: () => _agregar(context),
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [Tab(text: 'Mis proveedores'), Tab(text: 'Mis pedidos')],
          ),
        ),
        body: TabBarView(
          children: [
            _ListaProveedores(onAgregar: () => _agregar(context)),
            const _ListaPedidos(),
          ],
        ),
      ),
    );
  }
}

class _ListaProveedores extends StatelessWidget {
  final VoidCallback onAgregar;
  const _ListaProveedores({required this.onAgregar});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [VinculosService.instance, PedidosService.instance]),
      builder: (context, _) {
        final vs = VinculosService.instance;
        final ps = PedidosService.instance;
        if (!vs.cargado) return const Center(child: CircularProgressIndicator());
        if (vs.vinculos.isEmpty) {
          return EmptyState(
            icono: Icons.local_shipping_outlined,
            titulo: 'Aún no tienes proveedores',
            subtitulo:
                'Agrega uno con su código, o espera a que un proveedor te registre con tu correo.',
            textoBoton: 'Agregar proveedor',
            onPressed: onAgregar,
          );
        }
        final orden = [...vs.vinculos]..sort((a, b) {
            int peso(VinculoModel v) =>
                v.activo ? 0 : (v.pendiente ? 1 : 2);
            final c = peso(a).compareTo(peso(b));
            return c != 0
                ? c
                : a.proveedorNombre.toLowerCase().compareTo(b.proveedorNombre.toLowerCase());
          });
        return ListView.builder(
          padding: const EdgeInsets.only(top: 6, bottom: 20),
          itemCount: orden.length,
          itemBuilder: (_, i) {
            final v = orden[i];
            final saldo = ps.saldoCon(v.proveedorId);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: v.activo ? Colors.red[50] : Colors.grey[200],
                  child: Icon(Icons.local_shipping,
                      color: v.activo ? kRojo : Colors.grey),
                ),
                title: Text(v.proveedorNombre,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(v.activo
                    ? (saldo.abs() < 0.005
                        ? 'Sin saldo pendiente'
                        : (saldo > 0
                            ? 'Por pagar: ${fmtPrecio(saldo)}'
                            : 'Saldo a favor: ${fmtPrecio(-saldo)}'))
                    : (v.pendiente
                        ? 'Esperando aprobación del proveedor'
                        : etiquetaVinculo(v.estado))),
                trailing: v.pendiente
                    ? TextButton(
                        onPressed: () =>
                            VinculosService.instance.cancelarSolicitud(v),
                        child: const Text('Cancelar'))
                    : const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: v.activo
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  ProveedorNegocioDetailScreen(vinculoId: v.id)),
                        )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

class _ListaPedidos extends StatefulWidget {
  const _ListaPedidos();

  @override
  State<_ListaPedidos> createState() => _ListaPedidosState();
}

class _ListaPedidosState extends State<_ListaPedidos> {
  bool _enCurso = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PedidosService.instance,
      builder: (context, _) {
        final s = PedidosService.instance;
        final lista = s.pedidos.where((p) => p.activo == _enCurso).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('En curso'),
                    selected: _enCurso,
                    selectedColor: kRojo,
                    checkmarkColor: Colors.white,
                    labelStyle:
                        TextStyle(color: _enCurso ? Colors.white : Colors.black),
                    onSelected: (_) => setState(() => _enCurso = true),
                  ),
                  ChoiceChip(
                    label: const Text('Historial'),
                    selected: !_enCurso,
                    selectedColor: kRojo,
                    checkmarkColor: Colors.white,
                    labelStyle:
                        TextStyle(color: !_enCurso ? Colors.white : Colors.black),
                    onSelected: (_) => setState(() => _enCurso = false),
                  ),
                ],
              ),
            ),
            Expanded(
              child: !s.cargado
                  ? const Center(child: CircularProgressIndicator())
                  : lista.isEmpty
                      ? const EmptyState(
                          icono: Icons.receipt_long,
                          titulo: 'Sin pedidos aquí',
                          subtitulo:
                              'Entra a un proveedor y pulsa "Hacer pedido".')
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 20),
                          itemCount: lista.length,
                          itemBuilder: (_, i) =>
                              PedidoTile(pedido: lista[i], proveedor: false),
                        ),
            ),
          ],
        );
      },
    );
  }
}
