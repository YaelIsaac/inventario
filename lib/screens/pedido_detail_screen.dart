import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pedido_model.dart';
import '../services/inventario_service.dart';
import '../services/pedidos_service.dart';
import '../theme.dart';
import '../widgets/comprobante_picker.dart';
import '../widgets/pedido_widgets.dart';

/// Detalle de un pedido. [proveedor] = true si lo ve el proveedor.
class PedidoDetailScreen extends StatelessWidget {
  final String pedidoId;
  final bool proveedor;
  const PedidoDetailScreen(
      {super.key, required this.pedidoId, required this.proveedor});

  Future<void> _abrir(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw Exception('no se pudo abrir');
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo abrir en este teléfono.')));
    }
  }

  Future<bool> _confirmar(BuildContext context, String titulo, String texto,
      String si) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(si, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
    return ok == true;
  }

  void _verComprobante(BuildContext context, PedidoModel p) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FutureBuilder<String?>(
            future: PedidosService.instance.cargarComprobante(p.id),
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()));
              }
              final b64 = snap.data;
              if (b64 == null) {
                return const Text('No se pudo cargar el comprobante.');
              }
              return InteractiveViewer(child: imagenDeComprobante(b64));
            },
          ),
        ),
      ),
    );
  }

  Widget _fila(IconData icono, String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Expanded(child: Text(texto)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PedidosService.instance,
      builder: (context, _) {
        final p = PedidosService.instance.porId(pedidoId);
        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pedido')),
            body: const EmptyState(
                icono: Icons.receipt_long,
                titulo: 'Pedido no disponible',
                subtitulo: 'Puede que ya no exista.'),
          );
        }
        final siguiente = p.siguienteEstado;
        final puedeRechazar = proveedor && p.estado == 'nuevo';
        final puedeCancelar = !proveedor && p.estado == 'nuevo';
        final puedeRecibir =
            !proveedor && p.estado == 'entregado' && !p.inventarioActualizado;

        return Scaffold(
          appBar: AppBar(title: Text('Pedido #${p.codigo}')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    EstadoPedidoChip(p.estado),
                    const SizedBox(width: 8),
                    Text(fmtFecha(p.creado),
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Productos',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        ...p.items.map((i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(children: [
                                Expanded(
                                    child: Text(
                                        '${fmtNum(i.cantidad)} ${i.unidad} × ${i.nombre}')),
                                Text(fmtPrecio(i.subtotal)),
                              ]),
                            )),
                        const Divider(),
                        Row(children: [
                          const Expanded(
                              child: Text('Total',
                                  style: TextStyle(fontWeight: FontWeight.bold))),
                          Text(fmtPrecio(p.total),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                        ]),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(proveedor ? 'Cliente' : 'Proveedor',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        _fila(Icons.business,
                            proveedor ? p.negocioNombre : p.proveedorNombre),
                        if (p.negocioTelefono.isNotEmpty)
                          _fila(Icons.phone, p.negocioTelefono),
                        if (p.direccionEntrega.isNotEmpty)
                          _fila(Icons.home, p.direccionEntrega),
                        if (p.fechaDeseada.isNotEmpty)
                          _fila(Icons.event, 'Para: ${p.fechaDeseada}'),
                        if (p.notas.isNotEmpty) _fila(Icons.notes, p.notas),
                        if (proveedor) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (p.negocioTelefono.isNotEmpty)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.call),
                                  label: const Text('Llamar'),
                                  onPressed: () => _abrir(context,
                                      Uri(scheme: 'tel', path: p.negocioTelefono)),
                                ),
                              if (p.direccionEntrega.isNotEmpty)
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.map),
                                  label: const Text('Ver en mapa'),
                                  onPressed: () => _abrir(
                                      context,
                                      Uri.https('www.google.com', '/maps/search/',
                                          {'api': '1', 'query': p.direccionEntrega})),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!proveedor && p.activo) CobroInfoCard(proveedorId: p.proveedorId),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Comprobante de pago',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        if (p.tieneComprobante)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.image),
                            label: const Text('Ver comprobante'),
                            onPressed: () => _verComprobante(context, p),
                          )
                        else
                          Text(
                              proveedor
                                  ? 'El negocio aún no envía comprobante.'
                                  : 'Aún no has enviado comprobante.',
                              style: const TextStyle(color: Colors.grey)),
                        if (!proveedor &&
                            p.estado != 'cancelado' &&
                            p.estado != 'rechazado') ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kRojo,
                                foregroundColor: Colors.white),
                            icon: const Icon(Icons.upload),
                            label: Text(p.tieneComprobante
                                ? 'Reemplazar comprobante'
                                : 'Enviar comprobante'),
                            onPressed: () async {
                              final b64 = await elegirComprobante(context);
                              if (b64 != null) {
                                PedidosService.instance.adjuntarComprobante(p, b64);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Comprobante enviado')));
                                }
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (proveedor && siguiente != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: const Icon(Icons.arrow_forward),
                      label: Text(siguiente == 'aceptado'
                          ? 'Aceptar pedido'
                          : 'Marcar como: ${etiquetaEstado(siguiente)}'),
                      onPressed: () => PedidosService.instance
                          .cambiarEstado(p.id, siguiente),
                    ),
                  ),
                if (puedeRecibir)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                      icon: const Icon(Icons.inventory),
                      label: const Text('Recibí el pedido: sumar al inventario'),
                      onPressed: () async {
                        final ok = await _confirmar(
                            context,
                            'Sumar al inventario',
                            'Se agregarán estas cantidades a tu inventario '
                                '(y se crearán los productos que no existan).',
                            'Sí, sumar');
                        if (ok) {
                          InventarioService.instance.recibirPedido(p);
                          PedidosService.instance.marcarInventarioActualizado(p.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Inventario actualizado')));
                          }
                        }
                      },
                    ),
                  ),
                if (!proveedor && p.inventarioActualizado)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Row(children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 18),
                      SizedBox(width: 6),
                      Text('Ya sumado a tu inventario'),
                    ]),
                  ),
                if (puedeRechazar)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Rechazar pedido',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        if (await _confirmar(context, 'Rechazar pedido',
                            '¿Rechazar el pedido #${p.codigo}?', 'Sí, rechazar')) {
                          PedidosService.instance.cambiarEstado(p.id, 'rechazado');
                        }
                      },
                    ),
                  ),
                if (puedeCancelar)
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Cancelar pedido',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        if (await _confirmar(context, 'Cancelar pedido',
                            '¿Cancelar el pedido #${p.codigo}?', 'Sí, cancelar')) {
                          PedidosService.instance.cambiarEstado(p.id, 'cancelado');
                        }
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
