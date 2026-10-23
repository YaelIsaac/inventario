import 'package:flutter/material.dart';

import '../navegacion.dart';
import '../services/inventario_service.dart';
import '../services/pedidos_service.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'inventory_screen.dart';
import 'negocio_mas_screen.dart';
import 'negocio_proveedores_screen.dart';
import 'register_screen.dart';

/// Navegación del NEGOCIO.
class NegocioNavigation extends StatefulWidget {
  const NegocioNavigation({super.key});

  @override
  State<NegocioNavigation> createState() => _NegocioNavigationState();
}

class _NegocioNavigationState extends State<NegocioNavigation> {
  final List<Widget> _screens = const [
    HomeScreen(),
    InventoryScreen(),
    RegisterScreen(),
    NegocioProveedoresScreen(),
    NegocioMasScreen(),
  ];

  @override
  void initState() {
    super.initState();
    navTab.value = 0;
    registroModo.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: navTab,
      builder: (context, index, _) {
        return Scaffold(
          body: IndexedStack(index: index, children: _screens),
          bottomNavigationBar: ListenableBuilder(
            listenable: Listenable.merge(
                [InventarioService.instance, PedidosService.instance]),
            builder: (context, _) {
              final bajos = InventarioService.instance.productosBajos.length;
              final activos = PedidosService.instance.activos;
              return BottomNavigationBar(
                currentIndex: index,
                selectedItemColor: kRojo,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                onTap: (i) {
                  if (i == 2) registroModo.value = 0;
                  navTab.value = i;
                },
                items: [
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.home), label: 'Inicio'),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2), label: 'Inventario'),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.add_circle, size: 36, color: kRojo),
                      label: 'Registrar'),
                  BottomNavigationBarItem(
                    icon: Badge(
                        label: Text('$activos'),
                        isLabelVisible: activos > 0,
                        child: const Icon(Icons.local_shipping)),
                    label: 'Proveedores',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                        label: Text('$bajos'),
                        isLabelVisible: bajos > 0,
                        child: const Icon(Icons.menu)),
                    label: 'Más',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
