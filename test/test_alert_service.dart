/// Pruebas unitarias para AlertServiceMock
/// 
/// Ejecutar con: dart test/test_alert_service.dart

import '../lib/services/alert_service_mock.dart';
import '../lib/models/alert.dart';

Future<void> main() async {
  print('🧪 Iniciando pruebas de AlertServiceMock...\n');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: getAll retorna todas las alertas
  try {
    final service = AlertServiceMock();
    final alerts = await service.getAll();
    assert(alerts.isNotEmpty, 'Debería haber alertas de ejemplo');
    assert(alerts.length >= 4, 'Debería haber al menos 4 alertas de ejemplo');
    print('✅ Test 1: getAll retorna todas las alertas');
    passed++;
  } catch (e) {
    print('❌ Test 1 falló: $e');
    failed++;
  }
  
  // Test 2: getUnread retorna solo alertas no leídas
  try {
    final service = AlertServiceMock();
    final unreadAlerts = await service.getUnread();
    assert(unreadAlerts.isNotEmpty, 'Debería haber alertas no leídas');
    assert(unreadAlerts.every((alert) => !alert.leida), 'Todas deberían estar no leídas');
    print('✅ Test 2: getUnread retorna solo alertas no leídas');
    passed++;
  } catch (e) {
    print('❌ Test 2 falló: $e');
    failed++;
  }
  
  // Test 3: getById retorna alerta correcta
  try {
    final service = AlertServiceMock();
    final allAlerts = await service.getAll();
    final firstAlert = allAlerts.first;
    
    final foundAlert = await service.getById(firstAlert.id);
    assert(foundAlert != null, 'Debería encontrar la alerta');
    assert(foundAlert!.id == firstAlert.id, 'El ID debería coincidir');
    print('✅ Test 3: getById retorna alerta correcta');
    passed++;
  } catch (e) {
    print('❌ Test 3 falló: $e');
    failed++;
  }
  
  // Test 4: create crea nueva alerta
  try {
    final service = AlertServiceMock();
    final newAlert = Alert(
      id: '',
      tipo: AlertType.stockBajo,
      titulo: 'Nueva Alerta',
      mensaje: 'Mensaje de prueba',
      fechaCreacion: DateTime.now(),
    );
    
    final created = await service.create(newAlert);
    assert(created.id.isNotEmpty, 'Debería tener un ID generado');
    assert(created.titulo == newAlert.titulo, 'El título debería ser igual');
    
    final allAlerts = await service.getAll();
    assert(allAlerts.any((a) => a.id == created.id), 'La alerta debería estar en la lista');
    print('✅ Test 4: create crea nueva alerta');
    passed++;
  } catch (e) {
    print('❌ Test 4 falló: $e');
    failed++;
  }
  
  // Test 5: markAsRead marca alerta como leída
  try {
    final service = AlertServiceMock();
    final unreadAlerts = await service.getUnread();
    if (unreadAlerts.isNotEmpty) {
      final alertToMark = unreadAlerts.first;
      final success = await service.markAsRead(alertToMark.id);
      assert(success, 'Debería marcar como leída exitosamente');
      
      final updatedAlert = await service.getById(alertToMark.id);
      assert(updatedAlert != null, 'Debería encontrar la alerta');
      assert(updatedAlert!.leida, 'Debería estar marcada como leída');
      assert(updatedAlert!.fechaLectura != null, 'Debería tener fecha de lectura');
      print('✅ Test 5: markAsRead marca alerta como leída');
      passed++;
    } else {
      print('⚠️  Test 5: No hay alertas no leídas para probar');
      passed++;
    }
  } catch (e) {
    print('❌ Test 5 falló: $e');
    failed++;
  }
  
  // Test 6: markAllAsRead marca todas como leídas
  try {
    final service = AlertServiceMock();
    final success = await service.markAllAsRead();
    assert(success, 'Debería marcar todas como leídas exitosamente');
    
    final unreadAlerts = await service.getUnread();
    assert(unreadAlerts.isEmpty, 'No debería haber alertas no leídas');
    print('✅ Test 6: markAllAsRead marca todas como leídas');
    passed++;
  } catch (e) {
    print('❌ Test 6 falló: $e');
    failed++;
  }
  
  // Test 7: delete elimina alerta
  try {
    final service = AlertServiceMock();
    final allAlerts = await service.getAll();
    final alertToDelete = allAlerts.first;
    
    final success = await service.delete(alertToDelete.id);
    assert(success, 'Debería eliminar exitosamente');
    
    final foundAlert = await service.getById(alertToDelete.id);
    assert(foundAlert == null, 'La alerta no debería existir después de eliminar');
    print('✅ Test 7: delete elimina alerta');
    passed++;
  } catch (e) {
    print('❌ Test 7 falló: $e');
    failed++;
  }
  
  // Test 8: getById retorna null para ID inexistente
  try {
    final service = AlertServiceMock();
    final alert = await service.getById('id-inexistente');
    assert(alert == null, 'Debería retornar null para ID inexistente');
    print('✅ Test 8: getById retorna null para ID inexistente');
    passed++;
  } catch (e) {
    print('❌ Test 8 falló: $e');
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


