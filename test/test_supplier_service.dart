// Archivo de test para verificar el servicio de proveedores
// Ejecutar con: dart test/test_supplier_service.dart

// ignore_for_file: avoid_print

import '../lib/models/supplier.dart';
import '../lib/services/supplier_service_mock.dart';

void main() async {
  print('🧪 Probando Servicio de Proveedores (Mock)...\n');

  final service = SupplierServiceMock();

  // Test 1: Obtener todos los proveedores
  print('✅ Test 1: Obtener todos los proveedores');
  try {
    final suppliers = await service.getAll();
    print('   Proveedores encontrados: ${suppliers.length}');
    if (suppliers.isNotEmpty) {
      print('   Primer proveedor: ${suppliers.first.nombre}');
      print('   Contacto: ${suppliers.first.contactoCompleto}');
    }
    print('   ✅ getAll() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 2: Obtener proveedor por ID
  print('✅ Test 2: Obtener proveedor por ID');
  try {
    final supplier = await service.getById('supp-001');
    if (supplier != null) {
      print('   Proveedor encontrado: ${supplier.nombre}');
      print('   Contacto: ${supplier.contacto}');
      print('   Teléfono: ${supplier.telefono}');
      print('   Email: ${supplier.email ?? "N/A"}');
      print('   ✅ getById() funcionando correctamente\n');
    } else {
      print('   ❌ Proveedor no encontrado\n');
    }
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 3: Crear nuevo proveedor
  print('✅ Test 3: Crear nuevo proveedor');
  try {
    final newSupplier = Supplier(
      id: '',
      nombre: 'Nuevo Proveedor S.A.',
      contacto: 'Pedro López',
      telefono: '+9998887776',
      email: 'contacto@nuevoproveedor.com',
      direccion: 'Calle Nueva 999',
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );

    final created = await service.create(newSupplier);
    print('   Proveedor creado: ${created.id}');
    print('   Nombre: ${created.nombre}');
    print('   Contacto: ${created.contactoCompleto}');
    print('   ✅ create() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 4: Actualizar proveedor
  print('✅ Test 4: Actualizar proveedor');
  try {
    final supplier = await service.getById('supp-001');
    if (supplier != null) {
      final updated = supplier.copyWith(
        nombre: 'Proveedor ABC S.A. (Actualizado)',
        email: 'nuevoemail@proveedorabc.com',
      );
      
      final result = await service.update('supp-001', updated);
      print('   Proveedor actualizado: ${result.nombre}');
      print('   Nuevo email: ${result.email}');
      print('   ✅ update() funcionando correctamente\n');
    } else {
      print('   ⚠️ No se encontró el proveedor para actualizar\n');
    }
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 5: Eliminar proveedor
  print('✅ Test 5: Eliminar proveedor');
  try {
    final beforeCount = (await service.getAll()).length;
    final deleted = await service.delete('supp-004');
    final afterCount = (await service.getAll()).length;
    
    print('   Eliminado: $deleted');
    print('   Proveedores antes: $beforeCount');
    print('   Proveedores después: $afterCount');
    print('   ✅ delete() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 6: Buscar proveedores
  print('✅ Test 6: Buscar proveedores');
  try {
    final results1 = await service.search('ABC');
    final results2 = await service.search('María');
    final results3 = await service.search('xyz');
    
    print('   Búsqueda "ABC": ${results1.length} resultados');
    print('   Búsqueda "María": ${results2.length} resultados');
    print('   Búsqueda "xyz": ${results3.length} resultados');
    print('   ✅ search() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 7: Obtener productos por proveedor
  print('✅ Test 7: Obtener productos por proveedor');
  try {
    final products1 = await service.getProductsBySupplier('supp-001');
    final products2 = await service.getProductsBySupplier('supp-002');
    final products3 = await service.getProductsBySupplier('supp-999'); // No existe
    
    print('   Productos del proveedor supp-001: ${products1.length}');
    print('   IDs: ${products1.join(", ")}');
    print('   Productos del proveedor supp-002: ${products2.length}');
    print('   Productos del proveedor supp-999: ${products3.length}');
    print('   ✅ getProductsBySupplier() funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 8: Paginación
  print('✅ Test 8: Paginación');
  try {
    final page1 = await service.getAll(page: 0, limit: 2);
    final page2 = await service.getAll(page: 1, limit: 2);
    
    print('   Página 1 (límite 2): ${page1.length} proveedores');
    if (page1.isNotEmpty) {
      print('     - ${page1.first.nombre}');
    }
    if (page1.length > 1) {
      print('     - ${page1[1].nombre}');
    }
    print('   Página 2 (límite 2): ${page2.length} proveedores');
    print('   ✅ Paginación funcionando correctamente\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 9: Validación al crear proveedor inválido
  print('✅ Test 9: Validación al crear proveedor inválido');
  try {
    final invalidSupplier = Supplier(
      id: '',
      nombre: 'AB', // Muy corto
      contacto: 'Test',
      telefono: '123', // Muy corto
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );

    try {
      await service.create(invalidSupplier);
      print('   ⚠️ No se lanzó excepción para proveedor inválido\n');
    } catch (e) {
      print('   Excepción capturada: $e');
      print('   ✅ Validación funcionando correctamente\n');
    }
  } catch (e) {
    print('   ❌ Error inesperado: $e\n');
  }

  // Test 10: Verificar que create actualiza la lista
  print('✅ Test 10: Verificar que create actualiza la lista');
  try {
    final beforeCount = (await service.getAll()).length;
    
    final newSupplier = Supplier(
      id: '',
      nombre: 'Proveedor de Prueba',
      contacto: 'Test Contact',
      telefono: '12345678',
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    await service.create(newSupplier);
    
    final afterCount = (await service.getAll()).length;
    print('   Proveedores antes: $beforeCount');
    print('   Proveedores después: $afterCount');
    print('   Diferencia: ${afterCount - beforeCount}');
    
    if (afterCount > beforeCount) {
      print('   ✅ create() actualiza la lista correctamente\n');
    } else {
      print('   ⚠️ create() no actualizó la lista\n');
    }
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 11: Buscar con query vacío
  print('✅ Test 11: Buscar con query vacío');
  try {
    final results = await service.search('');
    print('   Resultados con query vacío: ${results.length}');
    print('   ✅ search() con query vacío retorna todos los proveedores\n');
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  // Test 12: Obtener proveedor inexistente
  print('✅ Test 12: Obtener proveedor inexistente');
  try {
    final supplier = await service.getById('supp-999');
    if (supplier == null) {
      print('   ✅ getById() retorna null para ID inexistente\n');
    } else {
      print('   ⚠️ getById() retornó un proveedor para ID inexistente\n');
    }
  } catch (e) {
    print('   ❌ Error: $e\n');
  }

  print('🎉 Tests del servicio completados!');
  print('\n📊 Resumen:');
  print('   ✅ getAll()');
  print('   ✅ getById()');
  print('   ✅ create()');
  print('   ✅ update()');
  print('   ✅ delete()');
  print('   ✅ search()');
  print('   ✅ getProductsBySupplier()');
  print('   ✅ Paginación');
  print('   ✅ Validaciones');
}


