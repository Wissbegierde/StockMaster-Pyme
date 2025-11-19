import '../../models/dashboard_stats.dart';

/// Interfaz para el servicio de dashboard
abstract class DashboardServiceInterface {
  /// Obtener todas las estadísticas del dashboard
  Future<DashboardStats> getStats();
  
  /// Obtener productos con stock bajo
  Future<int> getLowStockCount();
  
  /// Obtener valor total del inventario
  Future<double> getTotalInventoryValue();
  
  /// Obtener cantidad de movimientos del día actual
  Future<int> getMovementsToday();
}

