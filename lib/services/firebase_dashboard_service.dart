import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dashboard_stats.dart';
import 'interfaces/dashboard_service_interface.dart';

/// Servicio Firebase para dashboard
/// Implementa DashboardServiceInterface usando Firestore
class FirebaseDashboardService implements DashboardServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<DashboardStats> getStats() async {
    try {
      // Obtener todas las estadísticas en paralelo
      final results = await Future.wait([
        _getTotalProducts(),
        _getLowStockCount(),
        _getTotalInventoryValue(),
        _getMovementsToday(),
      ]);

      return DashboardStats(
        totalProducts: results[0] as int,
        lowStockCount: results[1] as int,
        totalInventoryValue: results[2] as double,
        movementsToday: results[3] as int,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  Future<int> _getTotalProducts() async {
    try {
      final snapshot = await _firestore.collection('products').count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      throw Exception('Error al obtener total de productos: ${e.toString()}');
    }
  }

  Future<int> _getLowStockCount() async {
    try {
      // Obtener todos los productos y contar los que tienen stock bajo
      final snapshot = await _firestore.collection('products').get();
      int count = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final stockActual = data['stock_actual'] ?? data['stockActual'] ?? 0;
        final stockMinimo = data['stock_minimo'] ?? data['stockMinimo'] ?? 0;
        
        if (stockActual < stockMinimo) {
          count++;
        }
      }
      
      return count;
    } catch (e) {
      throw Exception('Error al obtener productos con stock bajo: ${e.toString()}');
    }
  }

  Future<double> _getTotalInventoryValue() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      double totalValue = 0.0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final stockActual = (data['stock_actual'] ?? data['stockActual'] ?? 0).toInt();
        final precio = (data['precio'] ?? 0.0).toDouble();
        
        totalValue += stockActual * precio;
      }
      
      return totalValue;
    } catch (e) {
      throw Exception('Error al calcular valor del inventario: ${e.toString()}');
    }
  }

  Future<int> _getMovementsToday() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      
      final snapshot = await _firestore
          .collection('movements')
          .where('fecha', isGreaterThanOrEqualTo: todayStart.toIso8601String())
          .where('fecha', isLessThan: todayEnd.toIso8601String())
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      // Si falla con el query compuesto, obtener todos y filtrar
      try {
        final snapshot = await _firestore
            .collection('movements')
            .where('fecha', isGreaterThanOrEqualTo: DateTime.now().subtract(const Duration(days: 1)).toIso8601String())
            .get();
        
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));
        
        int count = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final fechaStr = data['fecha'] ?? data['fecha_creacion'];
          if (fechaStr != null) {
            final fecha = DateTime.parse(fechaStr);
            if (fecha.isAfter(todayStart) && fecha.isBefore(todayEnd)) {
              count++;
            }
          }
        }
        
        return count;
      } catch (e2) {
        throw Exception('Error al obtener movimientos del día: ${e2.toString()}');
      }
    }
  }

  @override
  Future<int> getLowStockCount() async {
    return await _getLowStockCount();
  }

  @override
  Future<double> getTotalInventoryValue() async {
    return await _getTotalInventoryValue();
  }

  @override
  Future<int> getMovementsToday() async {
    return await _getMovementsToday();
  }
}

