import 'package:flutter/material.dart';

import '../models/usuario_model.dart';
import '../services/auth_service.dart';
import '../theme.dart';

class AdminCuentasScreen extends StatefulWidget {
  const AdminCuentasScreen({super.key});

  @override
  State<AdminCuentasScreen> createState() => _AdminCuentasScreenState();
}

class _AdminCuentasScreenState extends State<AdminCuentasScreen> {
  String _busqueda = '';
  String _filtro = 'todos';
  late final Stream<List<UsuarioModel>> _stream =
      AuthService.instance.streamUsuarios();

  bool _pasa(UsuarioModel u) {
    switch (_filtro) {
      case 'proveedor':
        return u.rol == 'proveedor';
      case 'negocio':
        return u.rol == 'negocio';
      case 'admin':
        return u.rol == 'admin';
      case 'verificar':
        return u.rol == 'proveedor' && !u.verificado;
      case 'suspendidas':
        return !u.activo;
      default:
        return true;
    }
  }

  void _detalle(BuildContext context, UsuarioModel u, List<UsuarioModel> todos) {
    final esYo = u.uid == AuthService.instance.user?.uid;
    final admins = todos.where((x) => x.esAdmin).length;
    final ultimoAdmin = u.esAdmin && admins <= 1;
    final auth = AuthService.instance;
    final messenger = ScaffoldMessenger.of(context);

    Widget boton(String texto, IconData icono, Color color, VoidCallback f) =>
        SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
              icon: Icon(icono),
              label: Text(texto),
              onPressed: f,
            ),
          ),
        );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(u.titulo.isEmpty ? '(Sin nombre)' : u.titulo,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Rol: ${u.etiquetaRol}'),
              if (u.nombre.isNotEmpty) Text('Contacto: ${u.nombre}'),
              Text('Correo: ${u.email}'),
              Text('Teléfono: ${u.telefono.isEmpty ? '—' : u.telefono}'),
              if (u.direccion.isNotEmpty) Text('Dirección: ${u.direccion}'),
              if (u.esProveedor && u.giro.isNotEmpty) Text('Maneja: ${u.giro}'),
              if (u.esProveedor && u.codigo.isNotEmpty) Text('Código: ${u.codigo}'),
              if (u.creado != null) Text('Registro: ${fmtFecha(u.creado!)}'),
              Text('Estado: ${u.activo ? 'Activa' : 'Suspendida'}'
                  '${u.esProveedor ? (u.verificado ? ' • Verificado' : ' • Sin verificar') : ''}'),
              const SizedBox(height: 16),
              if (u.esProveedor)
                boton(
                  u.verificado ? 'Quitar verificación' : 'Verificar proveedor',
                  Icons.verified,
                  u.verificado ? Colors.grey : Colors.blue,
                  () {
                    auth.setVerificado(u, !u.verificado);
                    Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                        content: Text(u.verificado
                            ? 'Verificación quitada'
                            : '${u.titulo} verificado')));
                  },
                ),
              if (esYo)
                const Text('No puedes modificar tu propia cuenta.',
                    style: TextStyle(color: Colors.grey))
              else ...[
                boton(
                  u.activo ? 'Suspender cuenta' : 'Reactivar cuenta',
                  u.activo ? Icons.block : Icons.check_circle,
                  u.activo ? Colors.red : Colors.green,
                  () {
                    auth.setActivo(u, !u.activo);
                    Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                        content: Text(
                            u.activo ? 'Cuenta suspendida' : 'Cuenta reactivada')));
                  },
                ),
                if (u.esAdmin && ultimoAdmin)
                  const Text('Es el único administrador; no se puede descender.',
                      style: TextStyle(color: Colors.grey))
                else
                  boton(
                    u.esAdmin
                        ? 'Quitar administrador (vuelve a ${u.rolBase == 'proveedor' ? 'proveedor' : 'negocio'})'
                        : 'Ascender a administrador',
                    u.esAdmin ? Icons.arrow_downward : Icons.arrow_upward,
                    u.esAdmin ? Colors.orange : kRojo,
                    () {
                      if (u.esAdmin) {
                        auth.quitarAdmin(u);
                      } else {
                        auth.ascenderAdmin(u);
                      }
                      Navigator.pop(ctx);
                      messenger.showSnackBar(SnackBar(
                          content: Text(u.esAdmin
                              ? 'Ya no es administrador'
                              : '${u.titulo} ahora es administrador')));
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cuentas registradas')),
      body: StreamBuilder<List<UsuarioModel>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(
                icono: Icons.error_outline,
                titulo: 'No se pudieron cargar las cuentas',
                subtitulo: 'Revisa tu conexión y las reglas de Firestore.');
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final todos = snap.data!;
          final q = _busqueda.toLowerCase();
          final lista = todos
              .where((u) =>
                  _pasa(u) &&
                  (u.titulo.toLowerCase().contains(q) ||
                      u.nombre.toLowerCase().contains(q) ||
                      u.email.toLowerCase().contains(q)))
              .toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: TextField(
                  onChanged: (v) => setState(() => _busqueda = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o correo...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    for (final f in const [
                      ['todos', 'Todas'],
                      ['proveedor', 'Proveedores'],
                      ['negocio', 'Negocios'],
                      ['admin', 'Administradores'],
                      ['verificar', 'Por verificar'],
                      ['suspendidas', 'Suspendidas'],
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f[1]),
                          selected: _filtro == f[0],
                          selectedColor: kRojo,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                              color: _filtro == f[0] ? Colors.white : Colors.black),
                          onSelected: (_) => setState(() => _filtro = f[0]),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: lista.isEmpty
                    ? const EmptyState(
                        icono: Icons.group_off,
                        titulo: 'Sin resultados',
                        subtitulo: 'No hay cuentas con ese filtro.')
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemCount: lista.length,
                        itemBuilder: (_, i) {
                          final u = lista[i];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: !u.activo
                                    ? Colors.grey
                                    : (u.esAdmin ? kRojo : Colors.red[50]),
                                child: Icon(
                                    u.esAdmin
                                        ? Icons.admin_panel_settings
                                        : (u.esProveedor
                                            ? Icons.local_shipping
                                            : Icons.store),
                                    color: (u.esAdmin || !u.activo)
                                        ? Colors.white
                                        : kRojo),
                              ),
                              title: Row(
                                children: [
                                  Flexible(
                                      child: Text(
                                          u.titulo.isEmpty ? '(Sin nombre)' : u.titulo,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold))),
                                  if (u.esProveedor && u.verificado)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(Icons.verified,
                                          size: 16, color: Colors.blue),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                  '${u.email}\n${u.etiquetaRol}${u.activo ? '' : ' • Suspendida'}'),
                              isThreeLine: true,
                              onTap: () => _detalle(context, u, todos),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
