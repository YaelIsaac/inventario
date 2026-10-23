import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/vinculo_model.dart';
import '../services/pedidos_service.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';
import '../widgets/pedido_widgets.dart';

/// Un cliente (negocio) visto por el proveedor: datos, estado de cuenta y pedidos.
class ClienteDetailScreen extends StatefulWidget {
  final String vinculoId;
  const ClienteDetailScreen({super.key, required this.vinculoId});

  @override
  State<ClienteDetailScreen> createState() => _ClienteDetailScreenState();
}

class _ClienteDetailScreenState extends State<ClienteDetailScreen> {
  final _notas = TextEditingController();
  bool _notasCargadas = false;

  @override
  void dispose() {
    _notas.dispose();
    super.dispose();
  }

  Future<void> _abonar(String negocioId, String proveedorId, double saldo) async {
    final monto = TextEditingController();
    final nota = TextEditingController();
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar abono'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monto,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(labelText: 'Monto recibido', prefixText: '\$ '),
            ),
            if (saldo > 0.005)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                    onPressed: () => monto.text = fmtNum(saldo),
                    child: Text('Liquidar todo (${fmtPrecio(saldo)})')),
              ),
            TextField(
              controller: nota,
              decoration: const InputDecoration(
                  labelText: 'Nota (opcional)', hintText: 'Ej. Transferencia'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (r == true && mounted) {
      final err = PedidosService.instance.registrarAbono(
        proveedorId: proveedorId,
        negocioId: negocioId,
        monto: parseNum(monto.text) ?? 0,
        nota: nota.text,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(err ?? 'Abono registrado')));
    }
    monto.dispose();
    nota.dispose();
  }

  Future<void> _llamar(String tel) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await launchUrl(Uri(scheme: 'tel', path: tel),
          mode: LaunchMode.externalApplication);
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el teléfono.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge(
          [VinculosService.instance, PedidosService.instance]),
      builder: (context, _) {
        final v = VinculosService.instance.porId(widget.vinculoId);
        if (v == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Cliente')),
            body: const EmptyState(
                icono: Icons.store,
                titulo: 'Cliente no disponible',
                subtitulo: 'Puede que ya no exista.'),
          );
        }
        if (!_notasCargadas) {
          _notas.text = v.notas;
          _notasCargadas = true;
        }
        final ps = PedidosService.instance;
        final saldo = ps.saldoCon(v.negocioId);
        final pedidos = ps.pedidosCon(v.negocioId);
        final abonos = ps.abonosCon(v.negocioId);

        return Scaffold(
          appBar: AppBar(title: Text(v.negocioNombre)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Chip(
                              label: Text(etiquetaVinculo(v.estado),
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white)),
                              backgroundColor:
                                  v.activo ? Colors.green : Colors.grey,
                              visualDensity: VisualDensity.compact,
                              side: BorderSide.none,
                            ),
                          ],
                        ),
                        if (v.contacto.isNotEmpty)
                          Text('Contacto: ${v.contacto}'),
                        Text('Correo: ${v.negocioEmail}'),
                        if (v.negocioTelefono.isNotEmpty)
                          Text('Teléfono: ${v.negocioTelefono}'),
                        if (v.negocioDireccion.isNotEmpty)
                          Text('Dirección: ${v.negocioDireccion}'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            if (v.negocioTelefono.isNotEmpty)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.call),
                                label: const Text('Llamar'),
                                onPressed: () => _llamar(v.negocioTelefono),
                              ),
                            if (v.activo)
                              OutlinedButton.icon(
                                icon: const Icon(Icons.block, color: Colors.red),
                                label: const Text('Desactivar'),
                                onPressed: () =>
                                    VinculosService.instance.desactivar(v),
                              ),
                            if (v.estado == 'inactivo')
                              OutlinedButton.icon(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                label: const Text('Reactivar'),
                                onPressed: () =>
                                    VinculosService.instance.reactivar(v),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notas,
                  maxLines: 2,
                  maxLength: 200,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Notas privadas',
                    suffixIcon: IconButton(
                      tooltip: 'Guardar notas',
                      icon: const Icon(Icons.save),
                      onPressed: () {
                        VinculosService.instance.guardarNotas(v, _notas.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notas guardadas')));
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SaldoCard(saldo: saldo, etiquetaDeuda: 'Te debe'),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    icon: const Icon(Icons.payments),
                    label: const Text('Registrar abono'),
                    onPressed: () => _abonar(v.negocioId, v.proveedorId, saldo),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Abonos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (abonos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('Sin abonos todavía.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ...abonos.map((a) => Card(
                      child: ListTile(
                        dense: true,
                        leading: const Icon(Icons.payments, color: Colors.green),
                        title: Text(fmtPrecio(a.monto)),
                        subtitle: Text(
                            '${fmtFecha(a.fecha)}${a.nota.isEmpty ? '' : ' • ${a.nota}'}'),
                        trailing: IconButton(
                          tooltip: 'Eliminar',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminar abono'),
                                content: Text('¿Eliminar el abono de ${fmtPrecio(a.monto)}?'),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('No')),
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Eliminar',
                                          style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            );
                            if (ok == true) {
                              PedidosService.instance.eliminarAbono(a.id);
                            }
                          },
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                const Text('Pedidos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                if (pedidos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Text('Aún no te ha hecho pedidos.',
                        style: TextStyle(color: Colors.grey)),
                  ),
                ...pedidos.map((p) => PedidoTile(pedido: p, proveedor: true)),
              ],
            ),
          ),
        );
      },
    );
  }
}
