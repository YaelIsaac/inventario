import 'package:flutter/material.dart';

import '../services/inventario_service.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';
import '../widgets/movimiento_sheet.dart';
import '../widgets/producto_form.dart';
import 'nuevo_pedido_screen.dart';

class DetailScreen extends StatelessWidget {
  final String productoId;

  const DetailScreen({super.key, required this.productoId});

  Future<void> _confirmarEliminar(BuildContext context, String nombre) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text(
            '¿Eliminar "$nombre"? Su historial de movimientos se conserva.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      InventarioService.instance.eliminarProducto(productoId);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: InventarioService.instance,
      builder: (context, _) {
        final svc = InventarioService.instance;
        final p = svc.productoPorId(productoId);

        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Producto')),
            body: const EmptyState(
              icono: Icons.inventory_2_outlined,
              titulo: 'Producto no disponible',
              subtitulo: 'Pudo haber sido eliminado.',
            ),
          );
        }

        final historial =
            svc.movimientos.where((m) => m.productoId == p.id).take(10).toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(p.nombre),
            actions: [
              IconButton(
                tooltip: 'Editar',
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Editar producto')),
                      body: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Builder(
                          builder: (ctx) => ProductoForm(
                            producto: p,
                            onGuardado: () => Navigator.pop(ctx),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete),
                onPressed: () => _confirmarEliminar(context, p.nombre),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.red[50],
                      child: Icon(iconoCategoria(p.categoria),
                          color: kRojo, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nombre,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          EstadoChip(p.estado),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Categoría: ${p.categoria}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                    'Cantidad actual: ${fmtNum(p.cantidad)} ${p.unidadMedida}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Text(
                    'Stock mínimo requerido: ${fmtNum(p.stockMinimo)} ${p.unidadMedida}',
                    style: const TextStyle(
                        fontSize: 16, color: Colors.redAccent)),
                if (p.descripcion.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('Descripción:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(p.descripcion,
                      style: const TextStyle(
                          fontSize: 15, color: Colors.black87)),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text('Entrada',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () =>
                            mostrarMovimientoSheet(context, p, entrada: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kRojo,
                            padding:
                                const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.remove, color: Colors.white),
                        label: const Text('Salida',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () =>
                            mostrarMovimientoSheet(context, p, entrada: false),
                      ),
                    ),
                  ],
                ),
                if (p.proveedorId.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Builder(builder: (ctx) {
                    final v =
                        VinculosService.instance.conProveedor(p.proveedorId);
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.local_shipping),
                        label: Text('Pedir a ${p.proveedorNombre}'),
                        onPressed: (v != null && v.activo)
                            ? () => Navigator.push(
                                  ctx,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          NuevoPedidoScreen(vinculo: v)),
                                )
                            : null,
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 24),
                const Text('Movimientos recientes',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (historial.isEmpty)
                  const Text('Todavía no hay movimientos.',
                      style: TextStyle(color: Colors.grey)),
                ...historial.map((m) => Card(
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                            m.esEntrada ? Icons.arrow_downward : Icons.arrow_upward,
                            color: m.esEntrada ? Colors.green : Colors.red),
                        title: Text(
                            '${m.esEntrada ? '+' : '-'}${fmtNum(m.cantidad)} ${m.unidad}'
                            '${m.nota.isEmpty ? '' : ' • ${m.nota}'}'),
                        subtitle: Text(fmtFecha(m.fecha)),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
