/// Modelo de Proveedor
/// Representa un proveedor de productos para el inventario
class Supplier {
  final String id;
  final String nombre;
  final String contacto;
  final String telefono;
  final String? email;
  final String? direccion;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Supplier({
    required this.id,
    required this.nombre,
    required this.contacto,
    required this.telefono,
    this.email,
    this.direccion,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  /// Crear Supplier desde JSON
  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      contacto: json['contacto'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'],
      direccion: json['direccion'],
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : json['fechaCreacion'] != null
              ? DateTime.parse(json['fechaCreacion'])
              : json['created_at'] != null
                  ? DateTime.parse(json['created_at'])
                  : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'])
          : json['fechaActualizacion'] != null
              ? DateTime.parse(json['fechaActualizacion'])
              : json['updated_at'] != null
                  ? DateTime.parse(json['updated_at'])
                  : DateTime.now(),
    );
  }

  /// Convertir Supplier a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'contacto': contacto,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  /// Crear una copia del Supplier con campos modificados
  Supplier copyWith({
    String? id,
    String? nombre,
    String? contacto,
    String? telefono,
    String? email,
    String? direccion,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Supplier(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      contacto: contacto ?? this.contacto,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  /// Validar que el proveedor tenga datos válidos
  /// [requireId] indica si el ID es requerido (por defecto false para nuevos proveedores)
  bool isValid({bool requireId = false}) {
    if (requireId && id.isEmpty) return false;
    if (nombre.trim().isEmpty || nombre.trim().length < 3) return false;
    if (contacto.trim().isEmpty || contacto.trim().length < 3) return false;
    if (telefono.trim().isEmpty || telefono.trim().length < 8) return false;
    
    // Validar email si se proporciona
    if (email != null && email!.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email!)) return false;
    }
    
    return true;
  }

  /// Obtener mensaje de error de validación
  /// [requireId] indica si el ID es requerido
  String? getValidationError({bool requireId = false}) {
    if (requireId && id.isEmpty) {
      return 'El ID es requerido';
    }
    if (nombre.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (nombre.trim().length < 3) {
      return 'El nombre debe tener al menos 3 caracteres';
    }
    if (contacto.trim().isEmpty) {
      return 'El contacto es requerido';
    }
    if (contacto.trim().length < 3) {
      return 'El contacto debe tener al menos 3 caracteres';
    }
    if (telefono.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    if (telefono.trim().length < 8) {
      return 'El teléfono debe tener al menos 8 caracteres';
    }
    if (email != null && email!.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email!)) {
        return 'El email no es válido';
      }
    }
    return null;
  }

  /// Obtener información de contacto completa
  String get contactoCompleto {
    final partes = <String>[];
    if (contacto.isNotEmpty) partes.add(contacto);
    if (telefono.isNotEmpty) partes.add(telefono);
    if (email != null && email!.isNotEmpty) partes.add(email!);
    return partes.join(' • ');
  }

  /// Verificar si tiene email
  bool get tieneEmail => email != null && email!.isNotEmpty;

  /// Verificar si tiene dirección
  bool get tieneDireccion => direccion != null && direccion!.isNotEmpty;
}

