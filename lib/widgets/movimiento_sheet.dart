import 'package:flutter/material.dart';

import '../models/producto_model.dart';
import '../services/inventario_service.dart';
import '../theme.dart';

/// Hoja inferior para registrar una entrada o salida de un producto.
Future<void> mostrarMovimientoSheet(
  BuildContext context,
  ProductoModel producto, {
  required bool entrada,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final cantidadCtrl = TextEditingController();
  final notaCtrl = TextEditingController();
  String? error;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheet) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entrada ? 'Entrada' : 'Salida'}: ${producto.nombre}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Actual: ${fmtNum(producto.cantidad)} ${producto.unidadMedida}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cantidadCtrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cantidad (${producto.unidadMedida})',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notaCtrl,
                maxLength: 120,
                decoration: const InputDecoration(
                    labelText: 'Nota (opcional)',
                    hintText: 'Ej. Factura #1234'),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRojo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar'),
                  onPressed: () {
                    final cant = parseNum(cantidadCtrl.text);
                    if (cant == null) {
                      setSheet(() => error = 'Escribe un número válido.');
                      return;
                    }
                    final err = InventarioService.instance.registrarMovimiento(
                      producto: producto,
                      entrada: entrada,
                      cantidad: cant,
                      nota: notaCtrl.text,
                    );
                    if (err != null) {
                      setSheet(() => error = err);
                      return;
                    }
                    Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                      content: Text(
                          '${entrada ? 'Entrada' : 'Salida'} registrada: ${producto.nombre}'),
                    ));
                  },
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}
