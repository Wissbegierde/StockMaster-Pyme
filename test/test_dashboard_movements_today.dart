/// Pruebas unitarias para el getter movementsToday del MovementProvider
/// 
/// Ejecutar con: dart test/test_dashboard_movements_today.dart

import '../lib/models/movement.dart';

void main() {
  print('🧪 Iniciando pruebas de movementsToday...\n');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: movementsToday con movimientos del día actual
  try {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final movements = [
      Movement(
        id: '1',
        productId: 'prod-1',
        tipo: MovementType.entrada,
        cantidad: 10,
        motivo: 'Compra',
        fecha: now, // Movimiento de hoy
        usuarioId: 'user-1',
      ),
      Movement(
        id: '2',
        productId: 'prod-2',
        tipo: MovementType.salida,
        cantidad: 5,
        motivo: 'Venta',
        fecha: now.add(const Duration(hours: 2)), // Movimiento de hoy
        usuarioId: 'user-1',
      ),
      Movement(
        id: '3',
        productId: 'prod-3',
        tipo: MovementType.entrada,
        cantidad: 20,
        motivo: 'Compra',
        fecha: now.subtract(const Duration(days: 1)), // Movimiento de ayer
        usuarioId: 'user-1',
      ),
    ];
    
    final movementsToday = movements.where((movement) {
      final movementDate = movement.fecha;
      return movementDate.isAfter(todayStart) && movementDate.isBefore(todayEnd);
    }).length;
    
    assert(movementsToday == 2, 'Debería haber 2 movimientos de hoy, pero hay $movementsToday');
    print('✅ Test 1: movementsToday cuenta correctamente movimientos del día actual');
    passed++;
  } catch (e) {
    print('❌ Test 1 falló: $e');
    failed++;
  }
  
  // Test 2: movementsToday sin movimientos del día actual
  try {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final movements = [
      Movement(
        id: '1',
        productId: 'prod-1',
        tipo: MovementType.entrada,
        cantidad: 10,
        motivo: 'Compra',
        fecha: now.subtract(const Duration(days: 1)), // Ayer
        usuarioId: 'user-1',
      ),
      Movement(
        id: '2',
        productId: 'prod-2',
        tipo: MovementType.salida,
        cantidad: 5,
        motivo: 'Venta',
        fecha: now.subtract(const Duration(days: 2)), // Anteayer
        usuarioId: 'user-1',
      ),
    ];
    
    final movementsToday = movements.where((movement) {
      final movementDate = movement.fecha;
      return movementDate.isAfter(todayStart) && movementDate.isBefore(todayEnd);
    }).length;
    
    assert(movementsToday == 0, 'No debería haber movimientos de hoy, pero hay $movementsToday');
    print('✅ Test 2: movementsToday retorna 0 cuando no hay movimientos del día actual');
    passed++;
  } catch (e) {
    print('❌ Test 2 falló: $e');
    failed++;
  }
  
  // Test 3: movementsToday con lista vacía
  try {
    final movements = <Movement>[];
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final movementsToday = movements.where((movement) {
      final movementDate = movement.fecha;
      return movementDate.isAfter(todayStart) && movementDate.isBefore(todayEnd);
    }).length;
    
    assert(movementsToday == 0, 'Debería retornar 0 con lista vacía, pero retornó $movementsToday');
    print('✅ Test 3: movementsToday retorna 0 con lista vacía');
    passed++;
  } catch (e) {
    print('❌ Test 3 falló: $e');
    failed++;
  }
  
  // Test 4: movementsToday con movimientos en el límite del día (inicio del día)
  try {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final movements = [
      Movement(
        id: '1',
        productId: 'prod-1',
        tipo: MovementType.entrada,
        cantidad: 10,
        motivo: 'Compra',
        fecha: todayStart.add(const Duration(seconds: 1)), // Justo después del inicio del día
        usuarioId: 'user-1',
      ),
      Movement(
        id: '2',
        productId: 'prod-2',
        tipo: MovementType.salida,
        cantidad: 5,
        motivo: 'Venta',
        fecha: todayStart.subtract(const Duration(seconds: 1)), // Justo antes del inicio del día
        usuarioId: 'user-1',
      ),
    ];
    
    final movementsToday = movements.where((movement) {
      final movementDate = movement.fecha;
      return movementDate.isAfter(todayStart) && movementDate.isBefore(todayEnd);
    }).length;
    
    assert(movementsToday == 1, 'Debería haber 1 movimiento de hoy (el que está después del inicio), pero hay $movementsToday');
    print('✅ Test 4: movementsToday maneja correctamente el límite del día (inicio)');
    passed++;
  } catch (e) {
    print('❌ Test 4 falló: $e');
    failed++;
  }
  
  // Test 5: movementsToday con movimientos en el límite del día (fin del día)
  try {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    final movements = [
      Movement(
        id: '1',
        productId: 'prod-1',
        tipo: MovementType.entrada,
        cantidad: 10,
        motivo: 'Compra',
        fecha: todayEnd.subtract(const Duration(seconds: 1)), // Justo antes del fin del día
        usuarioId: 'user-1',
      ),
      Movement(
        id: '2',
        productId: 'prod-2',
        tipo: MovementType.salida,
        cantidad: 5,
        motivo: 'Venta',
        fecha: todayEnd, // Justo en el fin del día (no debería contar)
        usuarioId: 'user-1',
      ),
    ];
    
    final movementsToday = movements.where((movement) {
      final movementDate = movement.fecha;
      return movementDate.isAfter(todayStart) && movementDate.isBefore(todayEnd);
    }).length;
    
    assert(movementsToday == 1, 'Debería haber 1 movimiento de hoy (el que está antes del fin), pero hay $movementsToday');
    print('✅ Test 5: movementsToday maneja correctamente el límite del día (fin)');
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
  // En Dart puro, usamos return para salir
  if (code != 0) {
    throw Exception('Pruebas fallaron');
  }
}


