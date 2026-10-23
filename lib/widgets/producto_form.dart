import 'package:flutter/material.dart';

import '../models/producto_model.dart';
import '../services/inventario_service.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';

const List<String> _categoriasBase = [
  'Ingredientes',
  'Empaques',
  'Bebidas',
  'Limpieza',
];
const List<String> _unidadesBase = [
  'kg', 'g', 'L', 'ml', 'pzas', 'cajas', 'paquetes',
];

/// Formulario para crear un producto nuevo (o editar uno existente).
/// Sirve para cualquier cosa: queso, cajas, fresas, vasitos...
class ProductoForm extends StatefulWidget {
  final ProductoModel? producto;
  final VoidCallback? onGuardado;

  const ProductoForm({super.key, this.producto, this.onGuardado});

  @override
  State<ProductoForm> createState() => _ProductoFormState();
}

class _ProductoFormState extends State<ProductoForm> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _categoria = TextEditingController();
  final _unidad = TextEditingController();
  final _cantidad = TextEditingController();
  final _minimo = TextEditingController();
  final _descripcion = TextEditingController();
  String _proveedorId = '';

  bool get _editando => widget.producto != null;

  @override
  void initState() {
    super.initState();
    final p = widget.producto;
    if (p != null) {
      _nombre.text = p.nombre;
      _categoria.text = p.categoria;
      _unidad.text = p.unidadMedida;
      _minimo.text = fmtNum(p.stockMinimo);
      _descripcion.text = p.descripcion;
      _proveedorId = p.proveedorId;
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _categoria.dispose();
    _unidad.dispose();
    _cantidad.dispose();
    _minimo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  String? _numeroValido(String? v, {bool obligatorio = true}) {
    if (v == null || v.trim().isEmpty) {
      return obligatorio ? 'Campo obligatorio' : null;
    }
    final n = parseNum(v);
    if (n == null) return 'Número no válido';
    if (n < 0) return 'No puede ser negativo';
    return null;
  }

  String _nombreProveedor() {
    if (_proveedorId.isEmpty) return '';
    final v = VinculosService.instance.conProveedor(_proveedorId);
    return v?.proveedorNombre ?? widget.producto?.proveedorNombre ?? '';
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final svc = InventarioService.instance;
    final String? error;
    if (_editando) {
      error = svc.actualizarProducto(
        id: widget.producto!.id,
        nombre: _nombre.text,
        categoria: _categoria.text,
        unidad: _unidad.text,
        stockMinimo: parseNum(_minimo.text) ?? 0,
        descripcion: _descripcion.text,
        proveedorId: _proveedorId,
        proveedorNombre: _nombreProveedor(),
      );
    } else {
      error = svc.agregarProducto(
        nombre: _nombre.text,
        categoria: _categoria.text,
        unidad: _unidad.text,
        cantidad: parseNum(_cantidad.text) ?? 0,
        stockMinimo: parseNum(_minimo.text) ?? 0,
        descripcion: _descripcion.text,
        proveedorId: _proveedorId,
        proveedorNombre: _nombreProveedor(),
      );
    }
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    messenger.showSnackBar(SnackBar(
      content: Text(_editando
          ? 'Producto actualizado'
          : 'Producto "${_nombre.text.trim()}" registrado'),
    ));
    if (!_editando) {
      // Se deja el formulario limpio para seguir agregando productos.
      for (final c in [
        _nombre, _categoria, _unidad, _cantidad, _minimo, _descripcion
      ]) {
        c.clear();
      }
      _form.currentState!.reset();
    }
    widget.onGuardado?.call();
  }

  Widget _sugerencias(List<String> opciones, TextEditingController destino) {
    return Wrap(
      spacing: 8,
      children: opciones
          .map((o) => ActionChip(
                label: Text(o),
                onPressed: () => setState(() => destino.text = o),
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final existentes = InventarioService.instance.categorias;
    final categorias = {..._categoriasBase, ...existentes}.toList();

    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nombre del producto',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nombre,
            maxLength: 60,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                hintText: 'Ej. Queso, Fresas, Vasitos...'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 8),
          const Text('Categoría',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _categoria,
            maxLength: 30,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                hintText: 'Escribe una o elige abajo'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
          ),
          _sugerencias(categorias, _categoria),
          const SizedBox(height: 16),
          const Text('Unidad de medida',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _unidad,
            maxLength: 15,
            textInputAction: TextInputAction.next,
            decoration:
                const InputDecoration(hintText: 'kg, pzas, cajas, L...'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
          ),
          _sugerencias(_unidadesBase, _unidad),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_editando) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cantidad inicial',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _cantidad,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(hintText: 'Ej. 10'),
                        validator: _numeroValido,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stock mínimo',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _minimo,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(hintText: 'Ej. 3'),
                      validator: _numeroValido,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Te avisaremos cuando baje de este mínimo.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          const Text('Proveedor (opcional)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Builder(builder: (context) {
            final activos = VinculosService.instance.activos;
            final ids = activos.map((v) => v.proveedorId).toSet();
            return DropdownButtonFormField<String>(
              key: ValueKey('prov-$_proveedorId-${activos.length}'),
              initialValue: _proveedorId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: '', child: Text('Sin proveedor')),
                ...activos.map((v) => DropdownMenuItem(
                    value: v.proveedorId,
                    child: Text(v.proveedorNombre,
                        overflow: TextOverflow.ellipsis))),
                if (_proveedorId.isNotEmpty && !ids.contains(_proveedorId))
                  DropdownMenuItem(
                      value: _proveedorId,
                      child: Text(widget.producto?.proveedorNombre ?? 'Proveedor')),
              ],
              onChanged: (v) => setState(() => _proveedorId = v ?? ''),
            );
          }),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Sirve para pedirle rápido cuando se esté acabando.',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 16),
          const Text('Descripción (opcional)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descripcion,
            maxLines: 2,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'Proveedor, presentación, notas...'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kRojo,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(_editando ? 'Guardar cambios' : 'Registrar producto',
                  style: const TextStyle(color: Colors.white, fontSize: 16)),
              onPressed: _guardar,
            ),
          ),
        ],
      ),
    );
  }
}
