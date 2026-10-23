import 'package:flutter/material.dart';

/// Llave global para mostrar avisos desde cualquier servicio.
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void reportarError(String msg) {
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));
}
