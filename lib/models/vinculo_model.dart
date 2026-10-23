import 'package:cloud_firestore/cloud_firestore.dart';

/// Relación proveedor <-> negocio. Su id siempre es "proveedorId_negocioId".
class VinculoModel {
  final String id;
  final String proveedorId;
  final String negocioId;
  final String proveedorNombre;
  final String negocioNombre;
  final String negocioEmail;
  final String negocioTelefono;
  final String negocioDireccion;
  final String contacto;
  final String notas; // notas privadas del proveedor
  final String estado; // pendiente | activo | inactivo | rechazado
  final DateTime creado;

  const VinculoModel({
    required this.id,
    required this.proveedorId,
    required this.negocioId,
    required this.proveedorNombre,
    required this.negocioNombre,
    required this.negocioEmail,
    required this.negocioTelefono,
    required this.negocioDireccion,
    required this.contacto,
    required this.notas,
    required this.estado,
    required this.creado,
  });

  bool get activo => estado == 'activo';
  bool get pendiente => estado == 'pendiente';

  factory VinculoModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final ts = d['creado'];
    return VinculoModel(
      id: doc.id,
      proveedorId: (d['proveedorId'] as String?) ?? '',
      negocioId: (d['negocioId'] as String?) ?? '',
      proveedorNombre: (d['proveedorNombre'] as String?) ?? '',
      negocioNombre: (d['negocioNombre'] as String?) ?? '',
      negocioEmail: (d['negocioEmail'] as String?) ?? '',
      negocioTelefono: (d['negocioTelefono'] as String?) ?? '',
      negocioDireccion: (d['negocioDireccion'] as String?) ?? '',
      contacto: (d['contacto'] as String?) ?? '',
      notas: (d['notas'] as String?) ?? '',
      estado: (d['estado'] as String?) ?? 'pendiente',
      creado: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

String etiquetaVinculo(String e) {
  switch (e) {
    case 'activo':
      return 'Activo';
    case 'pendiente':
      return 'Pendiente';
    case 'inactivo':
      return 'Inactivo';
    case 'rechazado':
      return 'Rechazado';
    default:
      return e;
  }
}

/// Negocio que el proveedor registró por correo y que aún no tiene cuenta
/// (o aún no se ha vinculado).
class InvitacionModel {
  final String id;
  final String proveedorId;
  final String proveedorNombre;
  final String email;
  final String nombre;
  final String contacto;
  final String telefono;
  final String direccion;
  final String notas;
  final String estado; // pendiente | aceptada

  const InvitacionModel({
    required this.id,
    required this.proveedorId,
    required this.proveedorNombre,
    required this.email,
    required this.nombre,
    required this.contacto,
    required this.telefono,
    required this.direccion,
    required this.notas,
    required this.estado,
  });

  factory InvitacionModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return InvitacionModel(
      id: doc.id,
      proveedorId: (d['proveedorId'] as String?) ?? '',
      proveedorNombre: (d['proveedorNombre'] as String?) ?? '',
      email: (d['email'] as String?) ?? '',
      nombre: (d['nombre'] as String?) ?? '',
      contacto: (d['contacto'] as String?) ?? '',
      telefono: (d['telefono'] as String?) ?? '',
      direccion: (d['direccion'] as String?) ?? '',
      notas: (d['notas'] as String?) ?? '',
      estado: (d['estado'] as String?) ?? 'pendiente',
    );
  }
}

/// Ficha pública de un proveedor (el id del documento es su código).
class DirectorioModel {
  final String codigo;
  final String proveedorId;
  final String empresa;
  final String giro;
  final String telefono;
  final bool verificado;
  final bool activo;

  const DirectorioModel({
    required this.codigo,
    required this.proveedorId,
    required this.empresa,
    required this.giro,
    required this.telefono,
    required this.verificado,
    required this.activo,
  });

  factory DirectorioModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return DirectorioModel(
      codigo: doc.id,
      proveedorId: (d['proveedorId'] as String?) ?? '',
      empresa: (d['empresa'] as String?) ?? '',
      giro: (d['giro'] as String?) ?? '',
      telefono: (d['telefono'] as String?) ?? '',
      verificado: (d['verificado'] as bool?) ?? false,
      activo: (d['activo'] as bool?) ?? true,
    );
  }
}
