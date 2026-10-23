import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notificacion_service.dart';
import '../theme.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    setState(() => _error = null);
    try {
      final minimo = Future.delayed(const Duration(seconds: 2));
      await Firebase.initializeApp();
      await NotificacionService.instance.init();
      AuthService.instance.iniciar();
      await minimo;
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kRojo,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_pizza, size: 100, color: Colors.white),
              const SizedBox(height: 20),
              const Text(
                'PizzaStock',
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text('Tu inventario, siempre en control',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 40),
              if (_error == null)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
              else ...[
                const Text(
                  'No se pudo conectar con la base de datos.\n'
                  'Revisa tu internet y que Firebase esté configurado '
                  '(ver README).',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(_error!,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: kRojo),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  onPressed: _iniciar,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
