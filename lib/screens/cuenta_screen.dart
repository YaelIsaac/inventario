import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../theme.dart';

/// Mi cuenta (negocio y proveedor).
class CuentaScreen extends StatefulWidget {
  const CuentaScreen({super.key});

  @override
  State<CuentaScreen> createState() => _CuentaScreenState();
}

class _CuentaScreenState extends State<CuentaScreen> {
  final _form = GlobalKey<FormState>();
  final _empresa = TextEditingController();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _direccion = TextEditingController();
  final _giro = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = AuthService.instance.perfil;
    if (p != null) {
      _empresa.text = p.empresa;
      _nombre.text = p.nombre;
      _telefono.text = p.telefono;
      _direccion.text = p.direccion;
      _giro.text = p.giro;
    }
  }

  @override
  void dispose() {
    for (final c in [_empresa, _nombre, _telefono, _direccion, _giro]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AuthService.instance.perfil;
    final esProv = p?.esProveedor ?? false;
    return Scaffold(
      appBar: AppBar(title: const Text('Mi cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: kRojo,
                  child: Icon(esProv ? Icons.local_shipping : Icons.store,
                      size: 34, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                  child: Text(p?.email ?? '',
                      style: const TextStyle(color: Colors.grey))),
              Center(
                child: Wrap(
                  spacing: 6,
                  children: [
                    Chip(
                        label: Text(p?.etiquetaRol ?? '',
                            style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact),
                    if (esProv && (p?.verificado ?? false))
                      const Chip(
                          avatar: Icon(Icons.verified, size: 16, color: Colors.blue),
                          label: Text('Verificado', style: TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact),
                  ],
                ),
              ),
              if (esProv && (p?.codigo.isNotEmpty ?? false))
                Card(
                  color: Colors.amber[50],
                  child: ListTile(
                    title: const Text('Tu código de proveedor'),
                    subtitle: const Text('Compártelo para que los negocios te encuentren'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(p!.codigo,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2)),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: p.codigo));
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Código copiado')));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _empresa,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                    labelText: esProv ? 'Nombre de la empresa' : 'Nombre del negocio',
                    prefixIcon: const Icon(Icons.business)),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Campo obligatorio' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Tu nombre', prefixIcon: Icon(Icons.person)),
                validator: (v) =>
                    (v == null || v.trim().length < 2) ? 'Escribe tu nombre' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _telefono,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Teléfono', prefixIcon: Icon(Icons.phone)),
                validator: (v) {
                  final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                  return d.length == 10 ? null : 'Escribe 10 dígitos';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _direccion,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                    labelText: esProv ? 'Dirección' : 'Dirección de entrega',
                    prefixIcon: const Icon(Icons.home)),
              ),
              if (esProv) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _giro,
                  maxLines: 2,
                  maxLength: 150,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                      labelText: '¿Qué productos manejas?',
                      hintText: 'Ej. Lácteos, abarrotes, desechables y empaques',
                      prefixIcon: Icon(Icons.inventory_2)),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kRojo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar cambios'),
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    AuthService.instance.actualizarPerfil(
                      nombre: _nombre.text,
                      empresa: _empresa.text,
                      telefono: _telefono.text,
                      direccion: _direccion.text,
                      giro: _giro.text,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Perfil actualizado')));
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                  onPressed: () {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                    AuthService.instance.cerrarSesion();
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
