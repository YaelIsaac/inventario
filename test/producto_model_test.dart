import 'package:flutter_test/flutter_test.dart';
import 'package:inventario/models/producto_model.dart';
import 'package:inventario/theme.dart';

void main() {
  ProductoModel crear(double cant, double min) => ProductoModel(
        id: '1',
        nombre: 'Queso',
        categoria: 'Ingredientes',
        unidadMedida: 'kg',
        cantidad: cant,
        stockMinimo: min,
      );

  test('estado del producto', () {
    expect(crear(10, 5).estado, 'En stock');
    expect(crear(5, 5).estado, 'Stock bajo');
    expect(crear(0, 5).estado, 'Agotado');
    expect(crear(0, 0).agotado, true);
  });

  test('formato y lectura de números', () {
    expect(fmtNum(2), '2');
    expect(fmtNum(1.5), '1.5');
    expect(fmtNum(1.25), '1.25');
    expect(parseNum('1,5'), 1.5);
    expect(parseNum('abc'), isNull);
  });
}
