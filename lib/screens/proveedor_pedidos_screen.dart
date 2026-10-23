import 'package:flutter/material.dart';

import '../services/pedidos_service.dart';
import '../theme.dart';
import '../widgets/pedido_widgets.dart';

class ProveedorPedidosScreen extends StatefulWidget {
  const ProveedorPedidosScreen({super.key});

  @override
  State<ProveedorPedidosScreen> createState() => _ProveedorPedidosScreenState();
}

class _ProveedorPedidosScreenState extends State<ProveedorPedidosScreen> {
  String _filtro = 'nuevos';

  bool _coincide(String estado) {
    switch (_filtro) {
      case 'nuevos':
        return estado == 'nuevo';
      case 'curso':
        return estado == 'aceptado' || estado == 'enviado';
      case 'entregados':
        return estado == 'entregado';
      default:
        return estado == 'cancelado' || estado == 'rechazado';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PedidosService.instance,
      builder: (context, _) {
        final s = PedidosService.instance;
        final lista = s.pedidos.where((p) => _coincide(p.estado)).toList();
        return Scaffold(
          appBar: AppBar(title: const Text('PizzaStock - Pedidos')),
          body: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    for (final f in const [
                      ['nuevos', 'Nuevos'],
                      ['curso', 'En curso'],
                      ['entregados', 'Entregados'],
                      ['otros', 'Cancelados'],
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f[1]),
                          selected: _filtro == f[0],
                          selectedColor: kRojo,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                              color: _filtro == f[0] ? Colors.white : Colors.black),
                          onSelected: (_) => setState(() => _filtro = f[0]),
                        ),
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
                                'Los pedidos de tus negocios aparecerán en esta lista.')
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount: lista.length,
                            itemBuilder: (_, i) =>
                                PedidoTile(pedido: lista[i], proveedor: true),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}
