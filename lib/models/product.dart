class Product {
  final String id;
  final String codigo;
  final String nombre;
  final String categoria;
  final double precio;
  final int stockActual;
  final int stockMinimo;
  final String? proveedorId;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Product({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.stockActual,
    required this.stockMinimo,
    this.proveedorId,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      codigo: json['codigo'] ?? '',
      nombre: json['nombre'] ?? '',
      categoria: json['categoria'] ?? '',
      precio: (json['precio'] ?? 0.0).toDouble(),
      stockActual: json['stock_actual'] ?? json['stockActual'] ?? 0,
      stockMinimo: json['stock_minimo'] ?? json['stockMinimo'] ?? 0,
      proveedorId: json['proveedor_id'] ?? json['proveedorId'],
      fechaCreacion: json['fecha_creacion'] != null
          ? DateTime.parse(json['fecha_creacion'])
          : json['fechaCreacion'] != null
              ? DateTime.parse(json['fechaCreacion'])
              : DateTime.now(),
      fechaActualizacion: json['fecha_actualizacion'] != null
          ? DateTime.parse(json['fecha_actualizacion'])
          : json['fechaActualizacion'] != null
              ? DateTime.parse(json['fechaActualizacion'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'categoria': categoria,
      'precio': precio,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'proveedor_id': proveedorId,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_actualizacion': fechaActualizacion.toIso8601String(),
    };
  }

  Product copyWith({
    String? id,
    String? codigo,
    String? nombre,
    String? categoria,
    double? precio,
    int? stockActual,
    int? stockMinimo,
    String? proveedorId,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Product(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      precio: precio ?? this.precio,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      proveedorId: proveedorId ?? this.proveedorId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  // Validaciones
  bool get tieneStockBajo => stockActual <= stockMinimo;
  
  bool get tieneStockDisponible => stockActual > 0;
  
  double get valorInventario => precio * stockActual;
  
  // Validar que el producto tenga datos válidos
  bool isValid() {
    return codigo.isNotEmpty &&
        nombre.isNotEmpty &&
        categoria.isNotEmpty &&
        precio >= 0 &&
        stockActual >= 0 &&
        stockMinimo >= 0;
  }

  // Obtener mensaje de estado del stock
  String get estadoStock {
    if (stockActual == 0) return 'Sin stock';
    if (tieneStockBajo) return 'Stock bajo';
    return 'Stock normal';
  }
}

