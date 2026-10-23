import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'admin_navigation.dart';
import 'login_screen.dart';
import 'negocio_navigation.dart';
import 'proveedor_navigation.dart';

/// Decide qué pantalla ver según la sesión y el rol.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService.instance,
      builder: (context, _) {
        final a = AuthService.instance;
        if (!a.listo) return _Mensaje(error: a.errorPerfil);
        switch (a.rol) {
          case 'admin':
            return const AdminNavigation();
          case 'proveedor':
            return const ProveedorNavigation();
          case 'negocio':
            return const NegocioNavigation();
          case 'suspendido':
            return const _Mensaje(
                suspendida: true,
                error: 'Tu cuenta fue suspendida. Contacta al administrador.');
          default:
            return const LoginScreen();
        }
      },
    );
  }
}

class _Mensaje extends StatelessWidget {
  final String? error;
  final bool suspendida;
  const _Mensaje({this.error, this.suspendida = false});

  @override
  Widget build(BuildContext context) {
    final hayUsuario = AuthService.instance.user != null;
    return Scaffold(
      backgroundColor: kRojo,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(suspendida ? Icons.block : Icons.local_pizza,
                  size: 80, color: Colors.white),
              const SizedBox(height: 20),
              if (error == null) ...[
                const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                const SizedBox(height: 12),
                const Text('Cargando tu cuenta...',
                    style: TextStyle(color: Colors.white)),
              ] else
                Text(error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white)),
              if (hayUsuario)
                TextButton(
                  onPressed: AuthService.instance.cerrarSesion,
                  child: const Text('Cerrar sesión',
                      style: TextStyle(color: Colors.white70)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
