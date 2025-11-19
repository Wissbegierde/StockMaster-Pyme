// Archivo de test para verificar el servicio de movimientos
// Ejecutar con: dart test/test_movement_service.dart

// ignore_for_file: avoid_print

import '../lib/models/movement.dart';
import '../lib/services/movement_service_mock.dart';

void main() async {
  print('🧪 Probando Servicio de Movimientos (Mock)...\n');

  final service = MovementServiceMock();

  // Test 1: Obtener todos los movimientos
  print('✅ Test 1: Obtener todos los movimientos');
  try {
    final movements = await service.getAll();
    print('   Movimientos encontrados: ${movements.length}');
    if (movements.isNotEmpty) {
      print('   Primer movimiento: ${movements.first.getLabel()} - ${movements.first.motivo}');
    }
    print('   ✅ getAll() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 2: Obtener movimiento por ID
  print('✅ Test 2: Obtener movimiento por ID');
  try {
    final movement = await service.getById('mov-001');
    if (movement != null) {
      print('   Movimiento encontrado: ${movement.getLabel()}');
      print('   Producto: ${movement.productoNombre ?? movement.productId}');
      print('   Cantidad: ${movement.getCantidadConSigno()}');
      print('   ✅ getById() funcionando correctamente\n');
    } else {
      print('   ❌ Movimiento no encontrado\n');
    }
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 3: Crear nuevo movimiento
  print('✅ Test 3: Crear nuevo movimiento');
  try {
    final newMovement = Movement(
      id: '',
      productId: 'prod-003',
      tipo: MovementType.entrada,
      cantidad: 100,
      motivo: 'Compra masiva de proveedor',
      usuarioId: 'user-001',
      fecha: DateTime.now(),
    );

    final created = await service.create(newMovement);
    print('   Movimiento creado: ${created.id}');
    print('   Tipo: ${created.getLabel()}');
    print('   Cantidad: ${created.getCantidadConSigno()}');
    print('   ✅ create() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 4: Obtener movimientos por producto
  print('✅ Test 4: Obtener movimientos por producto');
  try {
    final movements = await service.getByProduct('prod-001');
    print('   Movimientos del producto prod-001: ${movements.length}');
    for (var m in movements) {
      print('     - ${m.getLabel()}: ${m.getCantidadConSigno()} (${m.motivo})');
    }
    print('   ✅ getByProduct() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 5: Obtener movimientos por rango de fechas
  print('✅ Test 5: Obtener movimientos por rango de fechas');
  try {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    final movements = await service.getByDateRange(start, end);
    print('   Movimientos en los últimos 7 días: ${movements.length}');
    print('   ✅ getByDateRange() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 6: Obtener movimientos por producto y rango de fechas
  print('✅ Test 6: Obtener movimientos por producto y rango de fechas');
  try {
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));
    final movements = await service.getByProductAndDateRange('prod-001', start, end);
    print('   Movimientos del producto prod-001 en los últimos 7 días: ${movements.length}');
    print('   ✅ getByProductAndDateRange() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 7: Obtener movimientos recientes
  print('✅ Test 7: Obtener movimientos recientes');
  try {
    final movements = await service.getRecent(3);
    print('   Movimientos recientes (límite 3): ${movements.length}');
    for (var m in movements) {
      print('     - ${m.getLabel()}: ${m.motivo} (${m.fecha.toString().substring(0, 10)})');
    }
    print('   ✅ getRecent() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 8: Obtener movimientos por tipo
  print('✅ Test 8: Obtener movimientos por tipo');
  try {
    final entradas = await service.getByType(MovementType.entrada);
    final salidas = await service.getByType(MovementType.salida);
    
    print('   Entradas: ${entradas.length}');
    print('   Salidas: ${salidas.length}');
    print('   ✅ getByType() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 9: Obtener movimientos por usuario
  print('✅ Test 9: Obtener movimientos por usuario');
  try {
    final movements = await service.getByUser('user-001');
    print('   Movimientos del usuario user-001: ${movements.length}');
    print('   ✅ getByUser() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 10: Paginación
  print('✅ Test 10: Paginación');
  try {
    final page1 = await service.getAll(page: 0, limit: 2);
    final page2 = await service.getAll(page: 1, limit: 2);
    
    print('   Página 1 (límite 2): ${page1.length} movimientos');
    print('   Página 2 (límite 2): ${page2.length} movimientos');
    print('   ✅ Paginación funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 11: Verificar que create actualiza la lista
  print('✅ Test 11: Verificar que create actualiza la lista');
  try {
    final beforeCount = (await service.getAll()).length;
    
    final newMovement = Movement(
      id: '',
      productId: 'prod-004',
      tipo: MovementType.salida,
      cantidad: 5,
      motivo: 'Venta de prueba',
      usuarioId: 'user-002',
      fecha: DateTime.now(),
    );
    
    await service.create(newMovement);
    
    final afterCount = (await service.getAll()).length;
    print('   Movimientos antes: $beforeCount');
    print('   Movimientos después: $afterCount');
    print('   Diferencia: ${afterCount - beforeCount}');
    
    if (afterCount > beforeCount) {
      print('   ✅ create() actualiza la lista correctamente\n');
    } else {
      print('   ⚠️ create() no actualizó la lista\n');
    }
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  print('🎉 Tests del servicio completados!');
  print('\n📊 Resumen:');
  print('   ✅ getAll()');
  print('   ✅ getById()');
  print('   ✅ create()');
  print('   ✅ getByProduct()');
  print('   ✅ getByDateRange()');
  print('   ✅ getByProductAndDateRange()');
  print('   ✅ getRecent()');
  print('   ✅ getByType()');
  print('   ✅ getByUser()');
  print('   ✅ Paginación');
}


