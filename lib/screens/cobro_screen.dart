import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/errores.dart';
import '../theme.dart';

/// El proveedor escribe su cuenta para transferencias (solo texto).
class CobroScreen extends StatefulWidget {
  const CobroScreen({super.key});

  @override
  State<CobroScreen> createState() => _CobroScreenState();
}

class _CobroScreenState extends State<CobroScreen> {
  final _form = GlobalKey<FormState>();
  final _titular = TextEditingController();
  final _banco = TextEditingController();
  final _cuenta = TextEditingController();
  final _instrucciones = TextEditingController();
  bool _cargando = true;

  DocumentReference<Map<String, dynamic>>? get _ref {
    final uid = AuthService.instance.user?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('cobros').doc(uid);
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final d = await _ref?.get();
      final m = d?.data() ?? <String, dynamic>{};
      _titular.text = (m['titular'] as String?) ?? '';
      _banco.text = (m['banco'] as String?) ?? '';
      _cuenta.text = (m['cuenta'] as String?) ?? '';
      _instrucciones.text = (m['instrucciones'] as String?) ?? '';
    } catch (_) {
      // sin conexión: se muestra vacío
    }
    if (mounted) setState(() => _cargando = false);
  }

  @override
  void dispose() {
    for (final c in [_titular, _banco, _cuenta, _instrucciones]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuenta para transferencias')),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'Solo tus clientes vinculados verán estos datos al pagar. '
                        'Ellos podrán enviarte la foto del comprobante desde su pedido.',
                        style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titular,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'Titular de la cuenta'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _banco,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Banco'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cuenta,
                      decoration: const InputDecoration(
                          labelText: 'Número de cuenta / CLABE / tarjeta'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Escribe el número de cuenta'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _instrucciones,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: const InputDecoration(
                          labelText: 'Instrucciones (opcional)',
                          hintText: 'Ej. Pon el nombre de tu negocio en el concepto'),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: kRojo,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14)),
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                        onPressed: () {
                          if (!_form.currentState!.validate()) return;
                          _ref?.set({
                            'titular': _titular.text.trim(),
                            'banco': _banco.text.trim(),
                            'cuenta': _cuenta.text.trim(),
                            'instrucciones': _instrucciones.text.trim(),
                          }).catchError((Object e) =>
                              reportarError('No se pudo guardar los datos.'));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Datos guardados')));
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
