import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _empresa = TextEditingController();
  final _telefono = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _pass2 = TextEditingController();

  bool _registro = false;
  String _rol = 'negocio';
  bool _ocupado = false;
  bool _verPass = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nombre, _empresa, _telefono, _email, _pass, _pass2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    final auth = AuthService.instance;
    final err = _registro
        ? await auth.registrar(
            rolElegido: _rol,
            nombre: _nombre.text,
            empresa: _empresa.text,
            telefono: _telefono.text,
            email: _email.text,
            pass: _pass.text)
        : await auth.iniciarSesion(_email.text, _pass.text);
    if (!mounted) return; // si todo salió bien, la pantalla ya cambió
    setState(() {
      _ocupado = false;
      _error = err;
    });
  }

  Future<void> _olvide() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_email.text.trim().isEmpty) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Escribe tu correo primero.')));
      return;
    }
    final err = await AuthService.instance.recuperarPassword(_email.text);
    messenger.showSnackBar(SnackBar(
        content: Text(
            err ?? 'Te enviamos un correo para restablecer tu contraseña.')));
  }

  @override
  Widget build(BuildContext context) {
    final esProv = _rol == 'proveedor';
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 70, 20, 30),
              decoration: const BoxDecoration(
                color: kRojo,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.local_pizza, size: 72, color: Colors.white),
                  SizedBox(height: 8),
                  Text('PizzaStock',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Inventario para negocios y pedidos a proveedores',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Iniciar sesión')),
                          ButtonSegment(value: true, label: Text('Crear cuenta')),
                        ],
                        selected: {_registro},
                        onSelectionChanged: (s) => setState(() {
                          _registro = s.first;
                          _error = null;
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_registro) ...[
                      const Text('Soy...',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'negocio',
                                icon: Icon(Icons.store),
                                label: Text('Un negocio')),
                            ButtonSegment(
                                value: 'proveedor',
                                icon: Icon(Icons.local_shipping),
                                label: Text('Un proveedor')),
                          ],
                          selected: {_rol},
                          onSelectionChanged: (s) =>
                              setState(() => _rol = s.first),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 14),
                        child: Text(
                            esProv
                                ? 'Surtes productos a negocios: lleva tu catálogo, tus clientes, pedidos y cobros.'
                                : 'Tienes un negocio: lleva tu inventario y pídele a tus proveedores.',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ),
                      TextFormField(
                        controller: _empresa,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                            labelText: esProv
                                ? 'Nombre de tu empresa'
                                : 'Nombre de tu negocio',
                            prefixIcon: const Icon(Icons.business)),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Campo obligatorio'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nombre,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Tu nombre',
                            prefixIcon: Icon(Icons.person)),
                        validator: (v) => (v == null || v.trim().length < 2)
                            ? 'Escribe tu nombre'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _telefono,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                            labelText: 'Teléfono (10 dígitos)',
                            prefixIcon: Icon(Icons.phone)),
                        validator: (v) {
                          final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                          return d.length == 10 ? null : 'Escribe 10 dígitos';
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email)),
                      validator: (v) {
                        final t = (v ?? '').trim();
                        return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t)
                            ? null
                            : 'Correo no válido';
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: !_verPass,
                      textInputAction:
                          _registro ? TextInputAction.next : TextInputAction.done,
                      onFieldSubmitted: (_) => _registro ? null : _enviar(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                              _verPass ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _verPass = !_verPass),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                    if (_registro) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _pass2,
                        obscureText: !_verPass,
                        decoration: const InputDecoration(
                            labelText: 'Confirmar contraseña',
                            prefixIcon: Icon(Icons.lock_outline)),
                        validator: (v) =>
                            v == _pass.text ? null : 'Las contraseñas no coinciden',
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kRojo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _ocupado ? null : _enviar,
                        child: _ocupado
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(_registro ? 'Crear cuenta' : 'Entrar',
                                style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    if (!_registro)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: _olvide,
                            child: const Text('¿Olvidaste tu contraseña?')),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
