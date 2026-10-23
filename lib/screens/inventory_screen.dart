import 'package:flutter/material.dart';

import '../services/inventario_service.dart';
import '../theme.dart';
import 'detail_screen.dart';
import '../navegacion.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String categoriaFiltro = 'Todos';
  String busqueda = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: InventarioService.instance,
      builder: (context, _) {
        final svc = InventarioService.instance;
        final categorias = ['Todos', ...svc.categorias];
        // Si la categoría filtrada ya no existe, vuelve a "Todos".
        final filtro =
            categorias.contains(categoriaFiltro) ? categoriaFiltro : 'Todos';

        final filtrados = svc.productos.where((p) {
          final okCat = filtro == 'Todos' || p.categoria == filtro;
          final okBusq =
              p.nombre.toLowerCase().contains(busqueda.toLowerCase());
          return okCat && okBusq;
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('PizzaStock - Inventario')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: irANuevoProducto,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo producto'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  onChanged: (val) => setState(() => busqueda = val),
                  decoration: InputDecoration(
                    hintText: 'Buscar producto...',
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
                  children: categorias.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: filtro == cat,
                        selectedColor: kRojo,
                        labelStyle: TextStyle(
                            color: filtro == cat ? Colors.white : Colors.black),
                        checkmarkColor: Colors.white,
                        onSelected: (_) =>
                            setState(() => categoriaFiltro = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: !svc.cargado
                    ? const Center(child: CircularProgressIndicator())
                    : svc.productos.isEmpty
                        ? EmptyState(
                            icono: Icons.inventory_2_outlined,
                            titulo: 'Tu inventario está vacío',
                            subtitulo:
                                'Agrega tu primer producto para empezar.',
                            textoBoton: 'Registrar producto',
                            onPressed: irANuevoProducto,
                          )
                        : filtrados.isEmpty
                            ? const EmptyState(
                                icono: Icons.search_off,
                                titulo: 'Sin resultados',
                                subtitulo:
                                    'Prueba con otro nombre o categoría.',
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 90),
                                itemCount: filtrados.length,
                                itemBuilder: (context, index) {
                                  final p = filtrados[index];
                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.red[50],
                                        child: Icon(
                                            iconoCategoria(p.categoria),
                                            color: kRojo),
                                      ),
                                      title: Text(p.nombre,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Text(
                                          '${fmtNum(p.cantidad)} ${p.unidadMedida} • ${p.categoria}'),
                                      trailing: EstadoChip(p.estado),
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) =>
                                                DetailScreen(productoId: p.id)),
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}
