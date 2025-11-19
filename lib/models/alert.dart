// Modelo independiente de Flutter para facilitar testing

/// Enum para los tipos de alerta
enum AlertType {
  stockBajo,
  movimientoImportante,
  productoAgotado,
}

/// Modelo de Alerta
/// Representa una notificación o alerta en el sistema
class Alert {
  final String id;
  final AlertType tipo;
  final String titulo;
  final String mensaje;
  final String? productoId; // Opcional: si la alerta está relacionada con un producto
  final bool leida;
  final DateTime fechaCreacion;
  final DateTime? fechaLectura; // Opcional: cuando se marcó como leída

  Alert({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.productoId,
    this.leida = false,
    required this.fechaCreacion,
    this.fechaLectura,
  });

  /// Crear Alert desde JSON
  factory Alert.fromJson(Map<String, dynamic> json) {
    // Convertir string a enum
    AlertType tipoEnum;
    final tipoStr = json['tipo'] ?? json['type'] ?? '';
    switch (tipoStr.toString().toLowerCase()) {
      case 'stock_bajo':
      case 'stockbajo':
      case 'low_stock':
        tipoEnum = AlertType.stockBajo;
        break;
      case 'movimiento_importante':
      case 'movimientoimportante':
      case 'important_movement':
        tipoEnum = AlertType.movimientoImportante;
        break;
      case 'producto_agotado':
      case 'productoagotado':
      case 'out_of_stock':
        tipoEnum = AlertType.productoAgotado;
        break;
      default:
        tipoEnum = AlertType.stockBajo; // Default
    }

    return Alert(
      id: json['id'] ?? '',
      tipo: tipoEnum,
      titulo: json['titulo'] ?? json['title'] ?? '',
      mensaje: json['mensaje'] ?? json['message'] ?? '',
      productoId: json['producto_id'] ?? json['productoId'] ?? json['product_id'],
      leida: json['leida'] ?? json['read'] ?? false,
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : DateTime.now(),
      fechaLectura: json['fecha_lectura'] != null
          ? DateTime.parse(json['fecha_lectura'])
          : json['read_at'] != null
              ? DateTime.parse(json['read_at'])
              : null,
    );
  }

  /// Convertir Alert a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': _tipoToString(tipo),
      'titulo': titulo,
      'mensaje': mensaje,
      if (productoId != null) 'producto_id': productoId,
      'leida': leida,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      if (fechaLectura != null) 'fecha_lectura': fechaLectura!.toIso8601String(),
    };
  }

  /// Crear copia con cambios
  Alert copyWith({
    String? id,
    AlertType? tipo,
    String? titulo,
    String? mensaje,
    String? productoId,
    bool? leida,
    DateTime? fechaCreacion,
    DateTime? fechaLectura,
  }) {
    return Alert(
      id: id ?? this.id,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      productoId: productoId ?? this.productoId,
      leida: leida ?? this.leida,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaLectura: fechaLectura ?? this.fechaLectura,
    );
  }

  /// Validar que la alerta sea válida
  bool isValid() {
    return id.isNotEmpty &&
        titulo.isNotEmpty &&
        mensaje.isNotEmpty;
  }

  /// Obtener mensaje de error de validación
  String? getValidationError() {
    if (id.isEmpty) return 'El ID es requerido';
    if (titulo.isEmpty) return 'El título es requerido';
    if (mensaje.isEmpty) return 'El mensaje es requerido';
    return null;
  }

  /// Helper para convertir tipo a string
  String _tipoToString(AlertType tipo) {
    switch (tipo) {
      case AlertType.stockBajo:
        return 'stock_bajo';
      case AlertType.movimientoImportante:
        return 'movimiento_importante';
      case AlertType.productoAgotado:
        return 'producto_agotado';
    }
  }

  /// Obtener etiqueta del tipo de alerta
  String getTipoLabel() {
    switch (tipo) {
      case AlertType.stockBajo:
        return 'Stock Bajo';
      case AlertType.movimientoImportante:
        return 'Movimiento Importante';
      case AlertType.productoAgotado:
        return 'Producto Agotado';
    }
  }

  /// Obtener color hexadecimal del tipo
  String getTipoColorHex() {
    switch (tipo) {
      case AlertType.stockBajo:
        return '#F59E0B'; // Amarillo/Naranja
      case AlertType.movimientoImportante:
        return '#3B82F6'; // Azul
      case AlertType.productoAgotado:
        return '#EF4444'; // Rojo
    }
  }
}

