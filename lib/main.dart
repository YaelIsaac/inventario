import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'services/errores.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PizzaStockApp());
}

class PizzaStockApp extends StatelessWidget {
  const PizzaStockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PizzaStock',
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const SplashScreen(),
    );
  }
}
