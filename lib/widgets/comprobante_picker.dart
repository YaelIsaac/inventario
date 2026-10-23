import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Pide una foto (cámara o galería), la comprime y la devuelve en base64.
/// Devuelve null si el usuario cancela o la imagen no es válida.
Future<String?> elegirComprobante(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final origen = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Elegir de la galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (origen == null) return null;
  try {
    final foto = await ImagePicker()
        .pickImage(source: origen, maxWidth: 1000, imageQuality: 60);
    if (foto == null) return null;
    final bytes = await foto.readAsBytes();
    final b64 = base64Encode(bytes);
    // Firestore admite ~1 MB por documento.
    if (b64.length > 900000) {
      messenger.showSnackBar(const SnackBar(
          content: Text('La imagen es muy pesada. Toma una foto más sencilla.')));
      return null;
    }
    return b64;
  } catch (_) {
    messenger.showSnackBar(const SnackBar(
        content: Text('No se pudo abrir la cámara o la galería.')));
    return null;
  }
}

/// Muestra un comprobante guardado en base64.
Widget imagenDeComprobante(String b64, {double? alto}) {
  try {
    return Image.memory(base64Decode(b64), height: alto, fit: BoxFit.contain);
  } catch (_) {
    return const Text('No se pudo mostrar la imagen.');
  }
}
