/// Modelo para las estadísticas del dashboard
class DashboardStats {
  final int totalProducts;
  final int lowStockCount;
  final double totalInventoryValue;
  final int movementsToday;

  DashboardStats({
    required this.totalProducts,
    required this.lowStockCount,
    required this.totalInventoryValue,
    required this.movementsToday,
  });

  /// Crear DashboardStats desde JSON
  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalProducts: json['total_products'] ?? json['totalProducts'] ?? 0,
      lowStockCount: json['low_stock_count'] ?? json['lowStockCount'] ?? 0,
      totalInventoryValue: (json['total_inventory_value'] ?? json['totalInventoryValue'] ?? 0.0).toDouble(),
      movementsToday: json['movements_today'] ?? json['movementsToday'] ?? 0,
    );
  }

  /// Convertir DashboardStats a JSON
  Map<String, dynamic> toJson() {
    return {
      'total_products': totalProducts,
      'low_stock_count': lowStockCount,
      'total_inventory_value': totalInventoryValue,
      'movements_today': movementsToday,
    };
  }

  /// Crear copia con cambios
  DashboardStats copyWith({
    int? totalProducts,
    int? lowStockCount,
    double? totalInventoryValue,
    int? movementsToday,
  }) {
    return DashboardStats(
      totalProducts: totalProducts ?? this.totalProducts,
      lowStockCount: lowStockCount ?? this.lowStockCount,
      totalInventoryValue: totalInventoryValue ?? this.totalInventoryValue,
      movementsToday: movementsToday ?? this.movementsToday,
    );
  }
}

