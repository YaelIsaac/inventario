import 'package:flutter/material.dart';

import '../models/producto_model.dart';
import '../services/inventario_service.dart';
import '../theme.dart';
import '../widgets/producto_form.dart';
import '../navegacion.dart';

/// Pestaña "Registrar": movimiento de un producto existente o producto nuevo.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: registroModo,
      builder: (context, modo, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(modo == 0
                ? 'PizzaStock - Registrar movimiento'
                : 'PizzaStock - Nuevo producto'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                          value: 0,
                          icon: Icon(Icons.swap_vert),
                          label: Text('Movimiento')),
                      ButtonSegment(
                          value: 1,
                          icon: Icon(Icons.add_box),
                          label: Text('Nuevo producto')),
                    ],
                    selected: {modo},
                    onSelectionChanged: (s) => registroModo.value = s.first,
                  ),
                ),
                const SizedBox(height: 20),
                if (modo == 0)
                  const _MovimientoForm()
                else
                  const ProductoForm(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MovimientoForm extends StatefulWidget {
  const _MovimientoForm();

  @override
  State<_MovimientoForm> createState() => _MovimientoFormState();
}

class _MovimientoFormState extends State<_MovimientoForm> {
  bool esEntrada = true;
  String? productoId;
  final cantidadController = TextEditingController();
  final notaController = TextEditingController();
  String? errorCantidad;

  @override
  void dispose() {
    cantidadController.dispose();
    notaController.dispose();
    super.dispose();
  }

  void _registrar(ProductoModel producto) {
    final cant = parseNum(cantidadController.text);
    if (cant == null) {
      setState(() => errorCantidad = 'Escribe un número válido.');
      return;
    }
    final err = InventarioService.instance.registrarMovimiento(
      producto: producto,
      entrada: esEntrada,
      cantidad: cant,
      nota: notaController.text,
    );
    if (err != null) {
      setState(() => errorCantidad = err);
      return;
    }
    setState(() => errorCantidad = null);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text('Movimiento registrado con éxito para ${producto.nombre}')));
    cantidadController.clear();
    notaController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: InventarioService.instance,
      builder: (context, _) {
        final productos = InventarioService.instance.productos;

        if (productos.isEmpty) {
          return SizedBox(
            height: 320,
            child: EmptyState(
              icono: Icons.inventory_2_outlined,
              titulo: 'Primero registra un producto',
              subtitulo: 'Necesitas al menos un producto para mover su stock.',
              textoBoton: 'Nuevo producto',
              onPressed: () => registroModo.value = 1,
            ),
          );
        }

        final seleccionado = productos.firstWhere(
          (p) => p.id == productoId,
          orElse: () => productos.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de movimiento',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Entrada (Compra)'),
                    selected: esEntrada,
                    selectedColor: Colors.green,
                    onSelected: (_) => setState(() {
                      esEntrada = true;
                      errorCantidad = null;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Salida (Merma/Uso)'),
                    selected: !esEntrada,
                    selectedColor: Colors.redAccent,
                    onSelected: (_) => setState(() {
                      esEntrada = false;
                      errorCantidad = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Seleccionar Producto',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              key: ValueKey(seleccionado.id),
              initialValue: seleccionado.id,
              isExpanded: true,
              items: productos
                  .map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.nombre, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (val) => setState(() {
                productoId = val;
                errorCantidad = null;
              }),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                  'Disponible: ${fmtNum(seleccionado.cantidad)} ${seleccionado.unidadMedida}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ),
            const SizedBox(height: 20),
            const Text('Cantidad',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: cantidadController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Ej. 2',
                suffixText: seleccionado.unidadMedida,
                errorText: errorCantidad,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Nota (opcional)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextField(
              controller: notaController,
              maxLength: 120,
              decoration: const InputDecoration(hintText: 'Ej. Factura #1234'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRojo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.save, color: Colors.white),
                label: const Text('Registrar movimiento',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
                onPressed: () => _registrar(seleccionado),
              ),
            ),
          ],
        );
      },
    );
  }
}
