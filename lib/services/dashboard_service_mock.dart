import 'dart:async';
import '../models/dashboard_stats.dart';
import 'interfaces/dashboard_service_interface.dart';

class DashboardServiceMock implements DashboardServiceInterface {
  @override
  Future<DashboardStats> getStats() async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Retornar datos de ejemplo
    return DashboardStats(
      totalProducts: 25,
      lowStockCount: 5,
      totalInventoryValue: 125000.50,
      movementsToday: 12,
    );
  }

  @override
  Future<int> getLowStockCount() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 5;
  }

  @override
  Future<double> getTotalInventoryValue() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 125000.50;
  }

  @override
  Future<int> getMovementsToday() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 12;
  }
}

