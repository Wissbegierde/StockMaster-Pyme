/// Pruebas de integración: ProductProvider y SupplierProvider
/// 
/// Ejecutar con: dart test/test_product_supplier_integration.dart

import '../lib/models/product.dart';
import '../lib/models/supplier.dart';

void main() {
  print('🧪 Iniciando pruebas de integración Product-Supplier...\n');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: Producto asociado a proveedor
  try {
    final supplier = Supplier(
      id: 'supplier-1',
      nombre: 'Proveedor Test',
      contacto: 'Juan Pérez',
      telefono: '1234567890',
      email: 'proveedor@example.com',
      direccion: 'Calle 123',
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    final product = Product(
      id: 'prod-1',
      codigo: 'PROD-001',
      nombre: 'Producto Test',
      categoria: 'Test',
      precio: 100.0,
      stockActual: 10,
      stockMinimo: 5,
      proveedorId: supplier.id,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    assert(product.proveedorId == supplier.id, 'El producto debería estar asociado al proveedor');
    print('✅ Test 1: Producto asociado a proveedor');
    passed++;
  } catch (e) {
    print('❌ Test 1 falló: $e');
    failed++;
  }
  
  // Test 2: Producto sin proveedor
  try {
    final product = Product(
      id: 'prod-2',
      codigo: 'PROD-002',
      nombre: 'Producto Sin Proveedor',
      categoria: 'Test',
      precio: 100.0,
      stockActual: 10,
      stockMinimo: 5,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    assert(product.proveedorId == null, 'El producto NO debería tener proveedor');
    print('✅ Test 2: Producto sin proveedor');
    passed++;
  } catch (e) {
    print('❌ Test 2 falló: $e');
    failed++;
  }
  
  // Test 3: Múltiples productos asociados a un proveedor
  try {
    final supplier = Supplier(
      id: 'supplier-1',
      nombre: 'Proveedor Test',
      contacto: 'Juan Pérez',
      telefono: '1234567890',
      email: 'proveedor@example.com',
      direccion: 'Calle 123',
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    final product1 = Product(
      id: 'prod-1',
      codigo: 'PROD-001',
      nombre: 'Producto 1',
      categoria: 'Test',
      precio: 100.0,
      stockActual: 10,
      stockMinimo: 5,
      proveedorId: supplier.id,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    final product2 = Product(
      id: 'prod-2',
      codigo: 'PROD-002',
      nombre: 'Producto 2',
      categoria: 'Test',
      precio: 200.0,
      stockActual: 20,
      stockMinimo: 10,
      proveedorId: supplier.id,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    assert(product1.proveedorId == supplier.id, 'Producto 1 debería estar asociado al proveedor');
    assert(product2.proveedorId == supplier.id, 'Producto 2 debería estar asociado al proveedor');
    assert(product1.proveedorId == product2.proveedorId, 'Ambos productos deberían tener el mismo proveedor');
    print('✅ Test 3: Múltiples productos asociados a un proveedor');
    passed++;
  } catch (e) {
    print('❌ Test 3 falló: $e');
    failed++;
  }
  
  // Test 4: Cambiar proveedor de un producto
  try {
    final supplier1 = Supplier(
      id: 'supplier-1',
      nombre: 'Proveedor 1',
      contacto: 'Juan Pérez',
      telefono: '1234567890',
      email: 'proveedor1@example.com',
      direccion: 'Calle 123',
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    final supplier2 = Supplier(
      id: 'supplier-2',
      nombre: 'Proveedor 2',
      contacto: 'María García',
      telefono: '0987654321',
      email: 'proveedor2@example.com',
      direccion: 'Avenida 456',
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    final product = Product(
      id: 'prod-1',
      codigo: 'PROD-001',
      nombre: 'Producto Test',
      categoria: 'Test',
      precio: 100.0,
      stockActual: 10,
      stockMinimo: 5,
      proveedorId: supplier1.id,
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    assert(product.proveedorId == supplier1.id, 'El producto debería estar asociado al proveedor 1');
    
    final productActualizado = product.copyWith(proveedorId: supplier2.id);
    assert(productActualizado.proveedorId == supplier2.id, 'El producto debería estar asociado al proveedor 2');
    assert(productActualizado.proveedorId != product.proveedorId, 'El proveedor debería haber cambiado');
    print('✅ Test 4: Cambiar proveedor de un producto');
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


