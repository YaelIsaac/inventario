import 'package:flutter/material.dart';

import '../navegacion.dart';
import '../services/pedidos_service.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';
import 'catalogo_screen.dart';
import 'clientes_screen.dart';
import 'proveedor_home_screen.dart';
import 'proveedor_mas_screen.dart';
import 'proveedor_pedidos_screen.dart';

/// Navegación del PROVEEDOR.
class ProveedorNavigation extends StatefulWidget {
  const ProveedorNavigation({super.key});

  @override
  State<ProveedorNavigation> createState() => _ProveedorNavigationState();
}

class _ProveedorNavigationState extends State<ProveedorNavigation> {
  final List<Widget> _screens = const [
    ProveedorHomeScreen(),
    ProveedorPedidosScreen(),
    ClientesScreen(),
    CatalogoScreen(),
    ProveedorMasScreen(),
  ];

  @override
  void initState() {
    super.initState();
    provTab.value = 0;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: provTab,
      builder: (context, index, _) {
        return Scaffold(
          body: IndexedStack(index: index, children: _screens),
          bottomNavigationBar: ListenableBuilder(
            listenable: Listenable.merge(
                [PedidosService.instance, VinculosService.instance]),
            builder: (context, _) {
              final nuevos = PedidosService.instance.nuevos;
              final solicitudes = VinculosService.instance.pendientes.length;
              return BottomNavigationBar(
                currentIndex: index,
                selectedItemColor: kRojo,
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                onTap: (i) => provTab.value = i,
                items: [
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.home), label: 'Inicio'),
                  BottomNavigationBarItem(
                    icon: Badge(
                        label: Text('$nuevos'),
                        isLabelVisible: nuevos > 0,
                        child: const Icon(Icons.receipt_long)),
                    label: 'Pedidos',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                        label: Text('$solicitudes'),
                        isLabelVisible: solicitudes > 0,
                        child: const Icon(Icons.groups)),
                    label: 'Clientes',
                  ),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.inventory_2), label: 'Catálogo'),
                  const BottomNavigationBarItem(
                      icon: Icon(Icons.menu), label: 'Más'),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
