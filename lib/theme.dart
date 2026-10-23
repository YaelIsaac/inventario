import 'package:flutter/material.dart';

const Color kRojo = Color(0xFFB71C1C);
const Color kFondo = Color(0xFFF9F9F9);

ThemeData buildTheme() {
  final borde = OutlineInputBorder(borderRadius: BorderRadius.circular(10));
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: kRojo, primary: kRojo),
    primaryColor: kRojo,
    scaffoldBackgroundColor: kFondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: kRojo,
      foregroundColor: Colors.white,
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: borde,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kRojo,
      foregroundColor: Colors.white,
    ),
  );
}

/// 2 -> "2", 1.5 -> "1.5", 1.25 -> "1.25"
String fmtNum(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  var s = v.toStringAsFixed(2);
  if (s.endsWith('0')) s = s.substring(0, s.length - 1);
  return s;
}

/// Acepta "1,5" y "1.5". Devuelve null si no es un número válido.
double? parseNum(String t) {
  final v = double.tryParse(t.trim().replaceAll(',', '.'));
  if (v == null || v.isNaN || v.isInfinite) return null;
  return v;
}

String fmtPrecio(double v) => '\$${v.toStringAsFixed(2)}';

String fmtFecha(DateTime d) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
}

IconData iconoCategoria(String categoria) {
  final c = categoria.toLowerCase();
  if (c.contains('ingred') || c.contains('comida') || c.contains('alimento')) {
    return Icons.restaurant;
  }
  if (c.contains('empaq') || c.contains('caja') || c.contains('desech')) {
    return Icons.inventory_2;
  }
  if (c.contains('beb')) return Icons.local_drink;
  if (c.contains('limp')) return Icons.cleaning_services;
  return Icons.category;
}

class EmptyState extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String? textoBoton;
  final VoidCallback? onPressed;

  const EmptyState({
    super.key,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    this.textoBoton,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(titulo,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(subtitulo,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            if (textoBoton != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRojo,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: Text(textoBoton!),
                onPressed: onPressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class EstadoChip extends StatelessWidget {
  final String estado;
  const EstadoChip(this.estado, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = estado == 'En stock'
        ? Colors.green
        : (estado == 'Agotado' ? Colors.grey[700]! : Colors.red);
    return Chip(
      label: Text(estado,
          style: const TextStyle(fontSize: 10, color: Colors.white)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
