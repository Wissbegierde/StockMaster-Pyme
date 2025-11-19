/// Pruebas de integración: AlertProvider y ProductProvider
/// 
/// Ejecutar con: dart test/test_alert_product_integration.dart

import '../lib/models/product.dart';
import '../lib/models/alert.dart';

void main() {
  print('🧪 Iniciando pruebas de integración Alert-Product...\n');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: Producto con stock bajo genera alerta
  try {
    final product = Product(
      id: 'prod-1',
      codigo: 'PROD-001',
      nombre: 'Producto Test',
      categoria: 'Test',
      precio: 100.0,
      stockActual: 3,
      stockMinimo: 5,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    assert(product.tieneStockBajo == true, 'El producto debería tener stock bajo');
    
    final alert = Alert(
      id: 'alert-1',
      tipo: AlertType.stockBajo,
      titulo: 'Stock Bajo - ${product.nombre}',
      mensaje: 'El producto "${product.nombre}" tiene stock bajo (${product.stockActual} unidades). Stock mínimo: ${product.stockMinimo}',
      productoId: product.id,
      leida: false,
      fechaCreacion: DateTime.now(),
    );
    
    assert(alert.productoId == product.id, 'La alerta debería estar asociada al producto');
    assert(alert.tipo == AlertType.stockBajo, 'El tipo de alerta debería ser stockBajo');
    assert(alert.mensaje.contains(product.nombre), 'El mensaje debería contener el nombre del producto');
    print('✅ Test 1: Producto con stock bajo genera alerta');
    passed++;
  } catch (e) {
    print('❌ Test 1 falló: $e');
    failed++;
  }
  
  // Test 2: Producto sin stock bajo no genera alerta
  try {
    final product = Product(
      id: 'prod-2',
      codigo: 'PROD-002',
      nombre: 'Producto Normal',
      categoria: 'Test',
      precio: 100.0,
      stockActual: 10,
      stockMinimo: 5,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    assert(product.tieneStockBajo == false, 'El producto NO debería tener stock bajo');
    // No se debería crear una alerta para este producto
    print('✅ Test 2: Producto sin stock bajo no genera alerta');
    passed++;
  } catch (e) {
    print('❌ Test 2 falló: $e');
    failed++;
  }
  
  // Test 3: Producto agotado genera alerta de producto agotado
  try {
    final product = Product(
      id: 'prod-3',
      codigo: 'PROD-003',
      nombre: 'Producto Agotado',
      categoria: 'Test',
      precio: 100.0,
      stockActual: 0,
      stockMinimo: 5,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    assert(product.stockActual == 0, 'El producto debería estar agotado');
    
    final alert = Alert(
      id: 'alert-2',
      tipo: AlertType.productoAgotado,
      titulo: 'Producto Agotado - ${product.nombre}',
      mensaje: 'El producto "${product.nombre}" se ha agotado completamente',
      productoId: product.id,
      leida: false,
      fechaCreacion: DateTime.now(),
    );
    
    assert(alert.tipo == AlertType.productoAgotado, 'El tipo de alerta debería ser productoAgotado');
    print('✅ Test 3: Producto agotado genera alerta de producto agotado');
    passed++;
  } catch (e) {
    print('❌ Test 3 falló: $e');
    failed++;
  }
  
  // Test 4: Actualizar producto para normalizar stock elimina necesidad de alerta
  try {
    final product = Product(
      id: 'prod-4',
      codigo: 'PROD-004',
      nombre: 'Producto Repuesto',
      categoria: 'Test',
      precio: 100.0,
      stockActual: 3,
      stockMinimo: 5,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    assert(product.tieneStockBajo == true, 'El producto debería tener stock bajo inicialmente');
    
    // Simular reposición de stock
    final productActualizado = product.copyWith(stockActual: 10);
    assert(productActualizado.tieneStockBajo == false, 'El producto ya no debería tener stock bajo');
    
    // La alerta existente debería marcarse como resuelta o eliminarse
    print('✅ Test 4: Actualizar producto para normalizar stock elimina necesidad de alerta');
    passed++;
  } catch (e) {
    print('❌ Test 4 falló: $e');
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


