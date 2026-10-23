import 'package:flutter/material.dart';

import '../services/vinculos_service.dart';
import '../theme.dart';

class RegistrarNegocioScreen extends StatefulWidget {
  const RegistrarNegocioScreen({super.key});

  @override
  State<RegistrarNegocioScreen> createState() => _RegistrarNegocioScreenState();
}

class _RegistrarNegocioScreenState extends State<RegistrarNegocioScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _nombre = TextEditingController();
  final _contacto = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _notas = TextEditingController();

  @override
  void dispose() {
    for (final c in [_email, _nombre, _contacto, _telefono, _direccion, _notas]) {
      c.dispose();
    }
    super.dispose();
  }

  void _guardar() {
    if (!_form.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final err = VinculosService.instance.invitarNegocio(
      email: _email.text,
      nombre: _nombre.text,
      contacto: _contacto.text,
      telefono: _telefono.text,
      direccion: _direccion.text,
      notas: _notas.text,
    );
    if (err != null) {
      messenger.showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    messenger.showSnackBar(const SnackBar(
        content: Text('Negocio registrado. Se vinculará al usar ese correo.')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar negocio')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'Registra a tu cliente con el correo con el que usará la app. '
                  'Cuando cree su cuenta (o si ya la tiene) quedará vinculado contigo '
                  'automáticamente y podrá pedirte desde tu catálogo.',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Correo del negocio', prefixIcon: Icon(Icons.email)),
                validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch((v ?? '').trim())
                    ? null
                    : 'Correo no válido',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Nombre del negocio', prefixIcon: Icon(Icons.store)),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contacto,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Persona de contacto (opcional)',
                    prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Teléfono (opcional)', prefixIcon: Icon(Icons.phone)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccion,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Dirección de entrega (opcional)',
                    prefixIcon: Icon(Icons.home)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notas,
                maxLines: 2,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                    labelText: 'Notas privadas (opcional)',
                    hintText: 'Ej. Paga a 15 días, recibe de 8 a 12'),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kRojo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.save),
                  label: const Text('Registrar negocio'),
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
