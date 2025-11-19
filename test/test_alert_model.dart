/// Pruebas unitarias para el modelo Alert
/// 
/// Ejecutar con: dart test/test_alert_model.dart

import '../lib/models/alert.dart';

void main() {
  print('🧪 Iniciando pruebas del modelo Alert...\n');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: Crear alerta válida
  try {
    final alert = Alert(
      id: 'alert-1',
      tipo: AlertType.stockBajo,
      titulo: 'Stock Bajo',
      mensaje: 'El producto tiene stock bajo',
      productoId: 'prod-1',
      fechaCreacion: DateTime.now(),
    );
    
    assert(alert.isValid(), 'La alerta debería ser válida');
    assert(alert.id == 'alert-1', 'El ID debería ser correcto');
    assert(alert.tipo == AlertType.stockBajo, 'El tipo debería ser stockBajo');
    assert(!alert.leida, 'La alerta no debería estar leída por defecto');
    print('✅ Test 1: Crear alerta válida');
    passed++;
  } catch (e) {
    print('❌ Test 1 falló: $e');
    failed++;
  }
  
  // Test 2: Serialización JSON
  try {
    final alert = Alert(
      id: 'alert-1',
      tipo: AlertType.stockBajo,
      titulo: 'Stock Bajo',
      mensaje: 'El producto tiene stock bajo',
      productoId: 'prod-1',
      fechaCreacion: DateTime(2024, 1, 1, 12, 0),
    );
    
    final json = alert.toJson();
    assert(json['id'] == 'alert-1', 'El ID en JSON debería ser correcto');
    assert(json['tipo'] == 'stock_bajo', 'El tipo en JSON debería ser correcto');
    assert(json['titulo'] == 'Stock Bajo', 'El título en JSON debería ser correcto');
    assert(json['producto_id'] == 'prod-1', 'El productoId en JSON debería ser correcto');
    assert(json['leida'] == false, 'Leida debería ser false en JSON');
    
    final alertFromJson = Alert.fromJson(json);
    assert(alertFromJson.id == alert.id, 'El ID debería ser igual después de fromJson');
    assert(alertFromJson.tipo == alert.tipo, 'El tipo debería ser igual después de fromJson');
    print('✅ Test 2: Serialización JSON');
    passed++;
  } catch (e) {
    print('❌ Test 2 falló: $e');
    failed++;
  }
  
  // Test 3: copyWith
  try {
    final alert = Alert(
      id: 'alert-1',
      tipo: AlertType.stockBajo,
      titulo: 'Stock Bajo',
      mensaje: 'El producto tiene stock bajo',
      fechaCreacion: DateTime.now(),
    );
    
    final alertLeida = alert.copyWith(leida: true, fechaLectura: DateTime.now());
    assert(alertLeida.leida == true, 'La alerta debería estar marcada como leída');
    assert(alertLeida.fechaLectura != null, 'La fecha de lectura debería estar establecida');
    assert(alertLeida.id == alert.id, 'El ID no debería cambiar');
    print('✅ Test 3: copyWith');
    passed++;
  } catch (e) {
    print('❌ Test 3 falló: $e');
    failed++;
  }
  
  // Test 4: Validaciones
  try {
    final alertSinId = Alert(
      id: '',
      tipo: AlertType.stockBajo,
      titulo: 'Título',
      mensaje: 'Mensaje',
      fechaCreacion: DateTime.now(),
    );
    assert(!alertSinId.isValid(), 'La alerta sin ID no debería ser válida');
    assert(alertSinId.getValidationError() == 'El ID es requerido', 'Debería retornar error de ID');
    
    final alertSinTitulo = Alert(
      id: 'alert-1',
      tipo: AlertType.stockBajo,
      titulo: '',
      mensaje: 'Mensaje',
      fechaCreacion: DateTime.now(),
    );
    assert(!alertSinTitulo.isValid(), 'La alerta sin título no debería ser válida');
    assert(alertSinTitulo.getValidationError() == 'El título es requerido', 'Debería retornar error de título');
    
    final alertValida = Alert(
      id: 'alert-1',
      tipo: AlertType.stockBajo,
      titulo: 'Título',
      mensaje: 'Mensaje',
      fechaCreacion: DateTime.now(),
    );
    assert(alertValida.isValid(), 'La alerta válida debería pasar la validación');
    assert(alertValida.getValidationError() == null, 'No debería haber error de validación');
    print('✅ Test 4: Validaciones');
    passed++;
  } catch (e) {
    print('❌ Test 4 falló: $e');
    failed++;
  }
  
  // Test 5: Tipos de alerta
  try {
    final alertStockBajo = Alert(
      id: 'alert-1',
      tipo: AlertType.stockBajo,
      titulo: 'Stock Bajo',
      mensaje: 'Mensaje',
      fechaCreacion: DateTime.now(),
    );
    assert(alertStockBajo.getTipoLabel() == 'Stock Bajo', 'El label debería ser correcto');
    assert(alertStockBajo.getTipoColorHex() == '#F59E0B', 'El color debería ser correcto');
    
    final alertMovimiento = Alert(
      id: 'alert-2',
      tipo: AlertType.movimientoImportante,
      titulo: 'Movimiento',
      mensaje: 'Mensaje',
      fechaCreacion: DateTime.now(),
    );
    assert(alertMovimiento.getTipoLabel() == 'Movimiento Importante', 'El label debería ser correcto');
    assert(alertMovimiento.getTipoColorHex() == '#3B82F6', 'El color debería ser correcto');
    
    final alertAgotado = Alert(
      id: 'alert-3',
      tipo: AlertType.productoAgotado,
      titulo: 'Agotado',
      mensaje: 'Mensaje',
      fechaCreacion: DateTime.now(),
    );
    assert(alertAgotado.getTipoLabel() == 'Producto Agotado', 'El label debería ser correcto');
    assert(alertAgotado.getTipoColorHex() == '#EF4444', 'El color debería ser correcto');
    print('✅ Test 5: Tipos de alerta');
    passed++;
  } catch (e) {
    print('❌ Test 5 falló: $e');
    failed++;
  }
  
  // Test 6: fromJson con diferentes formatos
  try {
    final json1 = {
      'id': 'alert-1',
      'tipo': 'stock_bajo',
      'titulo': 'Título',
      'mensaje': 'Mensaje',
      'producto_id': 'prod-1',
      'leida': false,
      'fecha_creacion': '2024-01-01T12:00:00.000Z',
    };
    final alert1 = Alert.fromJson(json1);
    assert(alert1.tipo == AlertType.stockBajo, 'Debería parsear stock_bajo correctamente');
    
    final json2 = {
      'id': 'alert-2',
      'type': 'low_stock',
      'title': 'Título',
      'message': 'Mensaje',
      'product_id': 'prod-2',
      'read': true,
      'created_at': '2024-01-01T12:00:00.000Z',
      'read_at': '2024-01-01T13:00:00.000Z',
    };
    final alert2 = Alert.fromJson(json2);
    assert(alert2.tipo == AlertType.stockBajo, 'Debería parsear low_stock correctamente');
    assert(alert2.leida == true, 'Debería parsear read correctamente');
    assert(alert2.fechaLectura != null, 'Debería parsear read_at correctamente');
    print('✅ Test 6: fromJson con diferentes formatos');
    passed++;
  } catch (e) {
    print('❌ Test 6 falló: $e');
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


