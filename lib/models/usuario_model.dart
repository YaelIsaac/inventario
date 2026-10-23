import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String uid;
  final String nombre; // persona de contacto
  final String empresa; // nombre del negocio / proveedor
  final String email;
  final String telefono;
  final String direccion;
  final String giro; // qué productos maneja (proveedor)
  final String rol; // 'admin' | 'proveedor' | 'negocio'
  final String rolBase; // rol al que regresa si deja de ser admin
  final String codigo; // código del proveedor
  final bool verificado;
  final bool activo;
  final DateTime? creado;

  const UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.empresa,
    required this.email,
    required this.telefono,
    required this.direccion,
    required this.giro,
    required this.rol,
    required this.rolBase,
    required this.codigo,
    required this.verificado,
    required this.activo,
    this.creado,
  });

  bool get esAdmin => rol == 'admin';
  bool get esProveedor => rol == 'proveedor';
  bool get esNegocio => rol == 'negocio';

  String get titulo => empresa.isNotEmpty ? empresa : nombre;

  String get etiquetaRol {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'proveedor':
        return 'Proveedor';
      default:
        return 'Negocio';
    }
  }

  factory UsuarioModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final ts = d['creado'];
    return UsuarioModel(
      uid: doc.id,
      nombre: (d['nombre'] as String?) ?? '',
      empresa: (d['empresa'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      telefono: (d['telefono'] as String?) ?? '',
      direccion: (d['direccion'] as String?) ?? '',
      giro: (d['giro'] as String?) ?? '',
      rol: (d['rol'] as String?) ?? 'negocio',
      rolBase: (d['rolBase'] as String?) ?? 'negocio',
      codigo: (d['codigo'] as String?) ?? '',
      verificado: (d['verificado'] as bool?) ?? false,
      activo: (d['activo'] as bool?) ?? true,
      creado: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
