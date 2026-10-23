import 'package:flutter/material.dart';

/// Pestaña activa del NEGOCIO y modo de "Registrar"
/// (0 = movimiento, 1 = nuevo producto).
final ValueNotifier<int> navTab = ValueNotifier<int>(0);
final ValueNotifier<int> registroModo = ValueNotifier<int>(0);

/// Pestañas activas del proveedor y del administrador.
final ValueNotifier<int> provTab = ValueNotifier<int>(0);
final ValueNotifier<int> adminTab = ValueNotifier<int>(0);

void irANuevoProducto() {
  registroModo.value = 1;
  navTab.value = 2;
}
