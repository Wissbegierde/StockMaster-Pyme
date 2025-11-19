/// Pruebas unitarias para DashboardServiceMock
/// 
/// Ejecutar con: dart test/test_dashboard_service.dart

import '../lib/services/dashboard_service_mock.dart';

Future<void> main() async {
  print('🧪 Iniciando pruebas de DashboardServiceMock...\n');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: getStats retorna estadísticas válidas
  try {
    final service = DashboardServiceMock();
    final stats = await service.getStats();
    
    assert(stats.totalProducts >= 0, 'Total productos debería ser >= 0');
    assert(stats.lowStockCount >= 0, 'Stock bajo debería ser >= 0');
    assert(stats.totalInventoryValue >= 0, 'Valor inventario debería ser >= 0');
    assert(stats.movementsToday >= 0, 'Movimientos hoy debería ser >= 0');
    print('✅ Test 1: getStats retorna estadísticas válidas');
    passed++;
  } catch (e) {
    print('❌ Test 1 falló: $e');
    failed++;
  }
  
  // Test 2: getLowStockCount retorna un número
  try {
    final service = DashboardServiceMock();
    final count = await service.getLowStockCount();
    
    assert(count is int, 'Debería retornar un int');
    assert(count >= 0, 'El conteo debería ser >= 0');
    print('✅ Test 2: getLowStockCount retorna un número');
    passed++;
  } catch (e) {
    print('❌ Test 2 falló: $e');
    failed++;
  }
  
  // Test 3: getTotalInventoryValue retorna un número
  try {
    final service = DashboardServiceMock();
    final value = await service.getTotalInventoryValue();
    
    assert(value is double, 'Debería retornar un double');
    assert(value >= 0, 'El valor debería ser >= 0');
    print('✅ Test 3: getTotalInventoryValue retorna un número');
    passed++;
  } catch (e) {
    print('❌ Test 3 falló: $e');
    failed++;
  }
  
  // Test 4: getMovementsToday retorna un número
  try {
    final service = DashboardServiceMock();
    final count = await service.getMovementsToday();
    
    assert(count is int, 'Debería retornar un int');
    assert(count >= 0, 'El conteo debería ser >= 0');
    print('✅ Test 4: getMovementsToday retorna un número');
    passed++;
  } catch (e) {
    print('❌ Test 4 falló: $e');
    failed++;
  }
  
  // Test 5: getStats retorna valores consistentes
  try {
    final service = DashboardServiceMock();
    final stats = await service.getStats();
    final lowStockCount = await service.getLowStockCount();
    final totalValue = await service.getTotalInventoryValue();
    final movementsToday = await service.getMovementsToday();
    
    // Los valores individuales deberían coincidir con los del objeto stats
    // (en el mock pueden ser diferentes, pero deberían ser válidos)
    assert(stats.lowStockCount == lowStockCount, 'lowStockCount debería coincidir');
    assert(stats.totalInventoryValue == totalValue, 'totalInventoryValue debería coincidir');
    assert(stats.movementsToday == movementsToday, 'movementsToday debería coincidir');
    print('✅ Test 5: getStats retorna valores consistentes');
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


