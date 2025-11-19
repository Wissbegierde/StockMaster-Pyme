// Modelo independiente de Flutter para facilitar testing

/// Enum para los tipos de movimiento de inventario
enum MovementType {
  entrada,  // Aumenta stock
  salida,   // Disminuye stock
}

/// Modelo de Movimiento de Inventario
/// Representa una entrada o salida de stock de un producto
class Movement {
  final String id;
  final String productId;
  final MovementType tipo;
  final int cantidad;
  final String motivo;
  final String usuarioId;
  final DateTime fecha;
  final String? productoNombre;  // Opcional: nombre del producto (para mostrar en listas)
  final String? usuarioNombre;   // Opcional: nombre del usuario (para mostrar en listas)
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  Movement({
    required this.id,
    required this.productId,
    required this.tipo,
    required this.cantidad,
    required this.motivo,
    required this.usuarioId,
    required this.fecha,
    this.productoNombre,
    this.usuarioNombre,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  /// Crear Movement desde JSON
  factory Movement.fromJson(Map<String, dynamic> json) {
    // Convertir string a enum
    MovementType tipoEnum;
    final tipoStr = json['tipo'] ?? json['type'] ?? '';
    switch (tipoStr.toString().toLowerCase()) {
      case 'entrada':
      case 'entry':
      case 'in':
        tipoEnum = MovementType.entrada;
        break;
      case 'salida':
      case 'exit':
      case 'out':
        tipoEnum = MovementType.salida;
        break;
      default:
        tipoEnum = MovementType.entrada; // Default
    }

    return Movement(
      id: json['id'] ?? '',
      productId: json['product_id'] ?? json['productId'] ?? '',
      tipo: tipoEnum,
      cantidad: json['cantidad'] ?? json['quantity'] ?? 0,
      motivo: json['motivo'] ?? json['reason'] ?? '',
      usuarioId: json['usuario_id'] ?? json['usuarioId'] ?? json['user_id'] ?? json['userId'] ?? '',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'])
          : json['date'] != null
              ? DateTime.parse(json['date'])
              : DateTime.now(),
      productoNombre: json['producto_nombre'] ?? json['productoNombre'] ?? json['product_name'],
      usuarioNombre: json['usuario_nombre'] ?? json['usuarioNombre'] ?? json['user_name'],
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'])
          : json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  /// Convertir Movement a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'tipo': _tipoToString(tipo),
      'cantidad': cantidad,
      'motivo': motivo,
      'usuario_id': usuarioId,
      'fecha': fecha.toIso8601String(),
      if (productoNombre != null) 'producto_nombre': productoNombre,
      if (usuarioNombre != null) 'usuario_nombre': usuarioNombre,
      if (fechaCreacion != null) 'fecha_creacion': fechaCreacion!.toIso8601String(),
      if (fechaActualizacion != null) 'fecha_actualizacion': fechaActualizacion!.toIso8601String(),
    };
  }

  /// Convertir enum a string
  String _tipoToString(MovementType tipo) {
    switch (tipo) {
      case MovementType.entrada:
        return 'entrada';
      case MovementType.salida:
        return 'salida';
    }
  }

  /// Crear copia del Movement con campos modificados
  Movement copyWith({
    String? id,
    String? productId,
    MovementType? tipo,
    int? cantidad,
    String? motivo,
    String? usuarioId,
    DateTime? fecha,
    String? productoNombre,
    String? usuarioNombre,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Movement(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      motivo: motivo ?? this.motivo,
      usuarioId: usuarioId ?? this.usuarioId,
      fecha: fecha ?? this.fecha,
      productoNombre: productoNombre ?? this.productoNombre,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  /// Obtener color (código hexadecimal) según el tipo de movimiento
  /// Retorna un String con el código hexadecimal del color
  String getColorHex() {
    switch (tipo) {
      case MovementType.entrada:
        return '#10B981'; // Verde
      case MovementType.salida:
        return '#EF4444'; // Rojo
    }
  }
  
  /// Obtener color como int (para usar con Color(value) en Flutter)
  int getColorValue() {
    switch (tipo) {
      case MovementType.entrada:
        return 0xFF10B981; // Verde
      case MovementType.salida:
        return 0xFFEF4444; // Rojo
    }
  }

  /// Obtener icono según el tipo de movimiento
  String getIcon() {
    switch (tipo) {
      case MovementType.entrada:
        return '↑'; // Flecha arriba
      case MovementType.salida:
        return '↓'; // Flecha abajo
    }
  }

  /// Obtener etiqueta legible del tipo
  String getLabel() {
    switch (tipo) {
      case MovementType.entrada:
        return 'Entrada';
      case MovementType.salida:
        return 'Salida';
    }
  }

  /// Obtener cantidad con signo según el tipo
  String getCantidadConSigno() {
    switch (tipo) {
      case MovementType.entrada:
        return '+$cantidad';
      case MovementType.salida:
        return '-$cantidad';
    }
  }

  /// Validar que el movimiento tenga datos válidos
  /// [requireId] indica si el ID es requerido (false por defecto, ya que el backend lo genera)
  bool isValid({bool requireId = false}) {
    if (requireId && id.isEmpty) return false;
    // Validar fecha: no permitir fechas futuras (más de 1 minuto en el futuro para tolerar diferencias de reloj)
    final now = DateTime.now();
    final fechaValida = fecha.isBefore(now.add(const Duration(minutes: 1)));
    
    return productId.isNotEmpty &&
        cantidad > 0 &&
        motivo.trim().isNotEmpty &&
        motivo.trim().length >= 3 &&
        usuarioId.isNotEmpty &&
        fechaValida;
  }

  /// Obtener mensaje de validación
  /// [requireId] indica si el ID es requerido (false por defecto, ya que el backend lo genera)
  String? getValidationError({bool requireId = false}) {
    if (requireId && id.isEmpty) return 'El ID es requerido';
    if (productId.isEmpty) return 'El producto es requerido';
    if (cantidad <= 0) return 'La cantidad debe ser mayor a 0';
    if (motivo.trim().isEmpty) return 'El motivo es requerido';
    if (motivo.trim().length < 3) return 'El motivo debe tener al menos 3 caracteres';
    if (usuarioId.isEmpty) return 'El usuario es requerido';
    
    // Validar fecha: no permitir fechas futuras
    final now = DateTime.now();
    if (fecha.isAfter(now.add(const Duration(minutes: 1)))) {
      return 'La fecha no puede ser futura';
    }
    
    return null;
  }

  /// Calcular el nuevo stock después de este movimiento
  /// [stockActual] es el stock actual del producto
  int calcularNuevoStock(int stockActual) {
    switch (tipo) {
      case MovementType.entrada:
        return stockActual + cantidad;
      case MovementType.salida:
        return stockActual - cantidad;
    }
  }

  /// Verificar si este movimiento resultaría en stock negativo
  /// [stockActual] es el stock actual del producto
  bool resultariaEnStockNegativo(int stockActual) {
    final nuevoStock = calcularNuevoStock(stockActual);
    return nuevoStock < 0;
  }
}

