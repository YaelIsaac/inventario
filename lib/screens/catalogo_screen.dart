import 'package:flutter/material.dart';

import '../models/catalogo_item_model.dart';
import '../services/catalogo_service.dart';
import '../theme.dart';

/// Catálogo del proveedor: todos los productos que puede surtir.
class CatalogoScreen extends StatelessWidget {
  const CatalogoScreen({super.key});

  void _abrirForm(BuildContext context, [CatalogoItemModel? item]) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => CatalogoFormScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CatalogoService.instance,
      builder: (context, _) {
        final c = CatalogoService.instance;
        final filas = <Widget>[];
        String? ultima;
        for (final it in c.items) {
          if (it.categoria != ultima) {
            ultima = it.categoria;
            filas.add(Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
              child: Text(it.categoria,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
            ));
          }
          filas.add(Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: ListTile(
              title: Text(it.nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${fmtPrecio(it.precio)} / ${it.unidad}'
                  '${it.descripcion.isEmpty ? '' : '\n${it.descripcion}'}'),
              isThreeLine: it.descripcion.isNotEmpty,
              trailing: Switch(
                value: it.disponible,
                activeThumbColor: Colors.green,
                onChanged: (v) => c.cambiarDisponible(it.id, v),
              ),
              onTap: () => _abrirForm(context, it),
            ),
          ));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('PizzaStock - Catálogo')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _abrirForm(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar producto'),
          ),
          body: !c.cargado
              ? const Center(child: CircularProgressIndicator())
              : c.items.isEmpty
                  ? EmptyState(
                      icono: Icons.inventory_2_outlined,
                      titulo: 'Tu catálogo está vacío',
                      subtitulo:
                          'Agrega todo lo que puedes surtir: lácteos, empaques, frutas, lo que manejes.',
                      textoBoton: 'Agregar producto',
                      onPressed: () => _abrirForm(context),
                    )
                  : ListView(
                      padding: const EdgeInsets.only(bottom: 90),
                      children: filas),
        );
      },
    );
  }
}

const List<String> _categoriasBase = [
  'Lácteos', 'Abarrotes', 'Empaques', 'Bebidas', 'Frutas y verduras', 'Limpieza',
];
const List<String> _unidadesBase = [
  'kg', 'g', 'L', 'ml', 'pzas', 'cajas', 'paquetes',
];

class CatalogoFormScreen extends StatefulWidget {
  final CatalogoItemModel? item;
  const CatalogoFormScreen({super.key, this.item});

  @override
  State<CatalogoFormScreen> createState() => _CatalogoFormScreenState();
}

class _CatalogoFormScreenState extends State<CatalogoFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _descripcion = TextEditingController();
  final _categoria = TextEditingController();
  final _unidad = TextEditingController();
  final _precio = TextEditingController();
  bool _disponible = true;

  bool get _editando => widget.item != null;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    if (i != null) {
      _nombre.text = i.nombre;
      _descripcion.text = i.descripcion;
      _categoria.text = i.categoria;
      _unidad.text = i.unidad;
      _precio.text = fmtNum(i.precio);
      _disponible = i.disponible;
    }
  }

  @override
  void dispose() {
    for (final c in [_nombre, _descripcion, _categoria, _unidad, _precio]) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = CatalogoService.instance.guardarItem(
      id: widget.item?.id,
      nombre: _nombre.text,
      descripcion: _descripcion.text,
      categoria: _categoria.text,
      unidad: _unidad.text,
      precio: parseNum(_precio.text) ?? 0,
      disponible: _disponible,
    );
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    messenger.showSnackBar(SnackBar(
        content: Text(_editando ? 'Catálogo actualizado' : 'Producto agregado')));
    if (_editando) {
      Navigator.pop(context);
    } else {
      // Se deja limpio para seguir agregando productos.
      for (final c in [_nombre, _descripcion, _precio]) {
        c.clear();
      }
      _form.currentState!.reset();
    }
  }

  Future<void> _eliminar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar del catálogo'),
        content: Text('¿Eliminar "${widget.item!.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true && mounted) {
      CatalogoService.instance.eliminarItem(widget.item!.id);
      Navigator.pop(context);
    }
  }

  Widget _chips(List<String> opciones, TextEditingController destino) => Wrap(
        spacing: 8,
        children: opciones
            .map((o) => ActionChip(
                label: Text(o),
                onPressed: () => setState(() => destino.text = o)))
            .toList(),
      );

  @override
  Widget build(BuildContext context) {
    final categorias =
        {..._categoriasBase, ...CatalogoService.instance.categorias}.toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(_editando ? 'Editar producto' : 'Nuevo producto'),
        actions: [
          if (_editando)
            IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete),
                onPressed: _eliminar),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nombre,
                maxLength: 60,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Nombre', hintText: 'Ej. Queso mozzarella'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descripcion,
                maxLines: 2,
                maxLength: 150,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Presentación, marca...'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _categoria,
                maxLength: 30,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Categoría'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              _chips(categorias, _categoria),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _precio,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                          labelText: 'Precio', prefixText: '\$ '),
                      validator: (v) {
                        final n = parseNum(v ?? '');
                        if (n == null) return 'Precio no válido';
                        if (n < 0) return 'No puede ser negativo';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unidad,
                      maxLength: 15,
                      decoration: const InputDecoration(
                          labelText: 'Por cada...', hintText: 'kg, caja...',
                          counterText: ''),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
                    ),
                  ),
                ],
              ),
              _chips(_unidadesBase, _unidad),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Disponible para pedir'),
                value: _disponible,
                activeThumbColor: Colors.green,
                onChanged: (v) => setState(() => _disponible = v),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kRojo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.save),
                  label: Text(_editando ? 'Guardar cambios' : 'Agregar al catálogo'),
                  onPressed: _guardar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
