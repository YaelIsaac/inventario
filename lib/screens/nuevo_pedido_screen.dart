import 'package:flutter/material.dart';

import '../models/catalogo_item_model.dart';
import '../models/pedido_model.dart';
import '../models/vinculo_model.dart';
import '../services/auth_service.dart';
import '../services/catalogo_service.dart';
import '../services/inventario_service.dart';
import '../services/pedidos_service.dart';
import '../theme.dart';

/// El negocio arma un pedido con el catálogo de UN proveedor.
class NuevoPedidoScreen extends StatefulWidget {
  final VinculoModel vinculo;
  const NuevoPedidoScreen({super.key, required this.vinculo});

  @override
  State<NuevoPedidoScreen> createState() => _NuevoPedidoScreenState();
}

class _NuevoPedidoScreenState extends State<NuevoPedidoScreen> {
  final Map<String, double> _cant = {};
  List<CatalogoItemModel> _catalogo = [];
  String _busqueda = '';
  late final Stream<List<CatalogoItemModel>> _stream =
      CatalogoService.streamDe(widget.vinculo.proveedorId);

  double get _total {
    var t = 0.0;
    for (final i in _catalogo) {
      t += i.precio * (_cant[i.id] ?? 0);
    }
    return t;
  }

  int get _lineas => _cant.values.where((c) => c > 0).length;

  void _cambiar(CatalogoItemModel i, double delta) {
    setState(() {
      final n = (_cant[i.id] ?? 0) + delta;
      if (n <= 0) {
        _cant.remove(i.id);
      } else {
        _cant[i.id] = n;
      }
    });
  }

  Future<void> _editarCantidad(CatalogoItemModel i) async {
    final c = TextEditingController(text: fmtNum(_cant[i.id] ?? 0));
    final r = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(i.nombre),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: 'Cantidad (${i.unidad})'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, parseNum(c.text)),
              child: const Text('Aceptar')),
        ],
      ),
    );
    c.dispose();
    if (r != null && r >= 0) {
      setState(() {
        if (r == 0) {
          _cant.remove(i.id);
        } else {
          _cant[i.id] = r;
        }
      });
    }
  }

  void _revisar() {
    final perfil = AuthService.instance.perfil;
    if (perfil == null) return;
    final items = <PedidoItem>[];
    for (final i in _catalogo) {
      final c = _cant[i.id] ?? 0;
      if (c > 0) {
        items.add(PedidoItem(
            catalogoId: i.id,
            nombre: i.nombre,
            unidad: i.unidad,
            categoria: i.categoria,
            precio: i.precio,
            cantidad: c));
      }
    }
    if (items.isEmpty) return;
    final fecha = TextEditingController();
    final notas = TextEditingController();
    final direccion = TextEditingController(text: perfil.direccion);
    final total = items.fold(0.0, (s, i) => s + i.subtotal);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pedido para ${widget.vinculo.proveedorNombre}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...items.map((i) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(children: [
                      Expanded(
                          child: Text('${fmtNum(i.cantidad)} ${i.unidad} × ${i.nombre}')),
                      Text(fmtPrecio(i.subtotal)),
                    ]),
                  )),
              const Divider(),
              Row(children: [
                const Expanded(
                    child: Text('Total',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Text(fmtPrecio(total),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: direccion,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration:
                    const InputDecoration(labelText: 'Dirección de entrega'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fecha,
                decoration: const InputDecoration(
                    labelText: '¿Para cuándo lo necesitas? (opcional)',
                    hintText: 'Ej. Jueves por la mañana'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notas,
                maxLines: 2,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Notas (opcional)'),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kRojo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.send),
                  label: Text('Enviar pedido • ${fmtPrecio(total)}'),
                  onPressed: () {
                    final err = PedidosService.instance.crearPedido(
                      proveedorId: widget.vinculo.proveedorId,
                      negocioId: perfil.uid,
                      proveedorNombre: widget.vinculo.proveedorNombre,
                      negocioNombre: perfil.titulo,
                      negocioTelefono: perfil.telefono,
                      direccionEntrega: direccion.text,
                      fechaDeseada: fecha.text,
                      notas: notas.text,
                      items: items,
                    );
                    final messenger = ScaffoldMessenger.of(context);
                    if (err != null) {
                      messenger.showSnackBar(SnackBar(content: Text(err)));
                      return;
                    }
                    Navigator.pop(ctx); // hoja
                    Navigator.pop(context); // pantalla
                    messenger.showSnackBar(const SnackBar(
                        content: Text('¡Pedido enviado! Te avisaremos cuando avance.')));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      fecha.dispose();
      notas.dispose();
      direccion.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vinculo;
    // Productos que tengo con poco stock y que este proveedor me surte.
    final bajos = InventarioService.instance.productosBajos
        .where((p) => p.proveedorId == v.proveedorId || p.proveedorId.isEmpty)
        .map((p) => p.nombre.trim().toLowerCase())
        .toSet();

    return Scaffold(
      appBar: AppBar(title: Text('Pedir a ${v.proveedorNombre}')),
      body: StreamBuilder<List<CatalogoItemModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(
                icono: Icons.error_outline,
                titulo: 'No se pudo cargar el catálogo',
                subtitulo: 'Revisa tu conexión.');
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          _catalogo = snap.data!;
          final q = _busqueda.toLowerCase();
          final disponibles = _catalogo
              .where((i) => i.disponible && i.nombre.toLowerCase().contains(q))
              .toList();

          final filas = <Widget>[];
          String? ultimaCat;
          for (final i in disponibles) {
            if (i.categoria != ultimaCat) {
              ultimaCat = i.categoria;
              filas.add(Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: Text(i.categoria,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ));
            }
            final c = _cant[i.id] ?? 0;
            final esBajo = bajos.contains(i.nombre.trim().toLowerCase());
            filas.add(Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                title: Row(
                  children: [
                    Flexible(
                        child: Text(i.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                    if (esBajo)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Chip(
                          label: Text('Te hace falta',
                              style: TextStyle(fontSize: 9, color: Colors.white)),
                          backgroundColor: Colors.red,
                          visualDensity: VisualDensity.compact,
                          side: BorderSide.none,
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                    '${fmtPrecio(i.precio)} / ${i.unidad}'
                    '${i.descripcion.isEmpty ? '' : '\n${i.descripcion}'}'),
                trailing: c == 0
                    ? IconButton.filled(
                        style: IconButton.styleFrom(backgroundColor: kRojo),
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: () => _cambiar(i, 1),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _cambiar(i, -1)),
                          GestureDetector(
                            onTap: () => _editarCantidad(i),
                            child: Text(fmtNum(c),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline)),
                          ),
                          IconButton(
                              icon: const Icon(Icons.add_circle, color: kRojo),
                              onPressed: () => _cambiar(i, 1)),
                        ],
                      ),
              ),
            ));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  onChanged: (t) => setState(() => _busqueda = t),
                  decoration: InputDecoration(
                    hintText: 'Buscar en su catálogo...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              Expanded(
                child: _catalogo.where((i) => i.disponible).isEmpty
                    ? const EmptyState(
                        icono: Icons.inventory_2_outlined,
                        titulo: 'Catálogo vacío',
                        subtitulo: 'Este proveedor aún no publica productos.')
                    : disponibles.isEmpty
                        ? const EmptyState(
                            icono: Icons.search_off,
                            titulo: 'Sin resultados',
                            subtitulo: 'Prueba con otra búsqueda.')
                        : ListView(
                            padding: const EdgeInsets.only(bottom: 20),
                            children: filas),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                  BoxShadow(blurRadius: 4, color: Colors.black12)
                ]),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$_lineas producto(s)',
                                style: const TextStyle(color: Colors.grey)),
                            Text(fmtPrecio(_total),
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRojo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                        ),
                        onPressed: _lineas == 0 ? null : _revisar,
                        child: const Text('Revisar pedido'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
