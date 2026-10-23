import 'package:flutter/material.dart';

import '../models/vinculo_model.dart';
import '../services/vinculos_service.dart';
import '../theme.dart';

class AgregarProveedorScreen extends StatefulWidget {
  const AgregarProveedorScreen({super.key});

  @override
  State<AgregarProveedorScreen> createState() => _AgregarProveedorScreenState();
}

class _AgregarProveedorScreenState extends State<AgregarProveedorScreen> {
  final _codigo = TextEditingController();
  String _busqueda = '';
  bool _buscando = false;
  late final Stream<List<DirectorioModel>> _stream =
      VinculosService.streamDirectorio();

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  void _aviso(String? err, String ok) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(err ?? ok)));
  }

  Future<void> _porCodigo() async {
    setState(() => _buscando = true);
    final err = await VinculosService.instance.solicitarPorCodigo(_codigo.text);
    if (!mounted) return;
    setState(() => _buscando = false);
    _aviso(err, 'Solicitud enviada. El proveedor debe aprobarla.');
    if (err == null) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar proveedor')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('¿Tu proveedor te dio un código?',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codigo,
                            textCapitalization: TextCapitalization.characters,
                            maxLength: 8,
                            decoration: const InputDecoration(
                                hintText: 'Ej. K7M2QX', counterText: ''),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kRojo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16)),
                          onPressed: _buscando ? null : _porCodigo,
                          child: _buscando
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : const Text('Solicitar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: InputDecoration(
                hintText: 'O busca un proveedor por nombre...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<DirectorioModel>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const EmptyState(
                      icono: Icons.error_outline,
                      titulo: 'No se pudo cargar el directorio',
                      subtitulo: 'Revisa tu conexión.');
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final q = _busqueda.toLowerCase();
                final lista = snap.data!
                    .where((d) =>
                        d.empresa.toLowerCase().contains(q) ||
                        d.giro.toLowerCase().contains(q))
                    .toList();
                if (lista.isEmpty) {
                  return const EmptyState(
                      icono: Icons.search_off,
                      titulo: 'Sin resultados',
                      subtitulo: 'Aún no hay proveedores con esa búsqueda.');
                }
                return ListenableBuilder(
                  listenable: VinculosService.instance,
                  builder: (context, _) => ListView.builder(
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final d = lista[i];
                      final v = VinculosService.instance.conProveedor(d.proveedorId);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                              backgroundColor: Colors.red[50],
                              child: const Icon(Icons.local_shipping, color: kRojo)),
                          title: Row(
                            children: [
                              Flexible(
                                  child: Text(d.empresa,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold))),
                              if (d.verificado)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(Icons.verified,
                                      size: 16, color: Colors.blue),
                                ),
                            ],
                          ),
                          subtitle: Text(
                              d.giro.isEmpty ? 'Sin descripción' : d.giro),
                          trailing: v != null
                              ? Text(etiquetaVinculo(v.estado),
                                  style: const TextStyle(color: Colors.grey))
                              : TextButton(
                                  onPressed: () {
                                    final err = VinculosService.instance.solicitar(d);
                                    _aviso(err,
                                        'Solicitud enviada a ${d.empresa}.');
                                  },
                                  child: const Text('Solicitar')),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
