/// Pruebas unitarias para el modelo DashboardStats
/// 
/// Ejecutar con: dart test/test_dashboard_stats_model.dart

import '../lib/models/dashboard_stats.dart';

void main() {
  print('🧪 Iniciando pruebas del modelo DashboardStats...\n');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: Crear DashboardStats válido
  try {
    final stats = DashboardStats(
      totalProducts: 25,
      lowStockCount: 5,
      totalInventoryValue: 125000.50,
      movementsToday: 12,
    );
    
    assert(stats.totalProducts == 25, 'Total productos debería ser correcto');
    assert(stats.lowStockCount == 5, 'Stock bajo debería ser correcto');
    assert(stats.totalInventoryValue == 125000.50, 'Valor inventario debería ser correcto');
    assert(stats.movementsToday == 12, 'Movimientos hoy debería ser correcto');
    print('✅ Test 1: Crear DashboardStats válido');
    passed++;
  } catch (e) {
    print('❌ Test 1 falló: $e');
    failed++;
  }
  
  // Test 2: Serialización JSON
  try {
    final stats = DashboardStats(
      totalProducts: 25,
      lowStockCount: 5,
      totalInventoryValue: 125000.50,
      movementsToday: 12,
    );
    
    final json = stats.toJson();
    assert(json['total_products'] == 25, 'Total productos en JSON debería ser correcto');
    assert(json['low_stock_count'] == 5, 'Stock bajo en JSON debería ser correcto');
    assert(json['total_inventory_value'] == 125000.50, 'Valor inventario en JSON debería ser correcto');
    assert(json['movements_today'] == 12, 'Movimientos hoy en JSON debería ser correcto');
    
    final statsFromJson = DashboardStats.fromJson(json);
    assert(statsFromJson.totalProducts == stats.totalProducts, 'Total productos debería ser igual después de fromJson');
    assert(statsFromJson.lowStockCount == stats.lowStockCount, 'Stock bajo debería ser igual después de fromJson');
    assert(statsFromJson.totalInventoryValue == stats.totalInventoryValue, 'Valor inventario debería ser igual después de fromJson');
    assert(statsFromJson.movementsToday == stats.movementsToday, 'Movimientos hoy debería ser igual después de fromJson');
    print('✅ Test 2: Serialización JSON');
    passed++;
  } catch (e) {
    print('❌ Test 2 falló: $e');
    failed++;
  }
  
  // Test 3: fromJson con diferentes formatos de nombres
  try {
    final json1 = {
      'total_products': 30,
      'low_stock_count': 8,
      'total_inventory_value': 150000.75,
      'movements_today': 15,
    };
    
    final stats1 = DashboardStats.fromJson(json1);
    assert(stats1.totalProducts == 30, 'Debería parsear total_products correctamente');
    assert(stats1.lowStockCount == 8, 'Debería parsear low_stock_count correctamente');
    
    final json2 = {
      'totalProducts': 20,
      'lowStockCount': 3,
      'totalInventoryValue': 100000.25,
      'movementsToday': 10,
    };
    
    final stats2 = DashboardStats.fromJson(json2);
    assert(stats2.totalProducts == 20, 'Debería parsear totalProducts correctamente');
    assert(stats2.lowStockCount == 3, 'Debería parsear lowStockCount correctamente');
    print('✅ Test 3: fromJson con diferentes formatos de nombres');
    passed++;
  } catch (e) {
    print('❌ Test 3 falló: $e');
    failed++;
  }
  
  // Test 4: fromJson con valores por defecto
  try {
    final json = <String, dynamic>{};
    
    final stats = DashboardStats.fromJson(json);
    assert(stats.totalProducts == 0, 'Total productos por defecto debería ser 0');
    assert(stats.lowStockCount == 0, 'Stock bajo por defecto debería ser 0');
    assert(stats.totalInventoryValue == 0.0, 'Valor inventario por defecto debería ser 0.0');
    assert(stats.movementsToday == 0, 'Movimientos hoy por defecto debería ser 0');
    print('✅ Test 4: fromJson con valores por defecto');
    passed++;
  } catch (e) {
    print('❌ Test 4 falló: $e');
    failed++;
  }
  
  // Test 5: copyWith
  try {
    final stats = DashboardStats(
      totalProducts: 25,
      lowStockCount: 5,
      totalInventoryValue: 125000.50,
      movementsToday: 12,
    );
    
    final updatedStats = stats.copyWith(
      totalProducts: 30,
      movementsToday: 15,
    );
    
    assert(updatedStats.totalProducts == 30, 'Total productos debería cambiar');
    assert(updatedStats.movementsToday == 15, 'Movimientos hoy debería cambiar');
    assert(updatedStats.lowStockCount == stats.lowStockCount, 'Stock bajo no debería cambiar');
    assert(updatedStats.totalInventoryValue == stats.totalInventoryValue, 'Valor inventario no debería cambiar');
    print('✅ Test 5: copyWith');
    passed++;
  } catch (e) {
    print('❌ Test 5 falló: $e');
    failed++;
  }
  
  // Resumen
  print('\n📊 Resumen de pruebas:');
  print('✅ Pasadas: $passed');
  print('❌ Fallidas: $failed');
  print('📈 Total: ${passed + failed}');
  
  if (failed == 0) {
    print('\n🎉 ¡Todas las pruebas pasaron!');
    exit(0);
  } else {
    print('\n⚠️  Algunas pruebas fallaron');
    exit(1);
  }
}

// Función auxiliar para salir del programa
void exit(int code) {
  if (code != 0) {
    throw Exception('Pruebas fallaron');
  }
}


