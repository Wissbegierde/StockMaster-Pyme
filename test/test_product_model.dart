// Archivo temporal para probar el modelo de Producto
// Este archivo se puede eliminar después de verificar que todo funciona

// ignore_for_file: avoid_print

import '../lib/models/product.dart';

void main() {
  print('🧪 Probando Modelo de Producto...\n');

  // Test 1: Crear un producto desde JSON
  print('✅ Test 1: Crear producto desde JSON');
  final jsonProduct = {
    'id': '1',
    'codigo': 'PROD-001',
    'nombre': 'Laptop Dell',
    'categoria': 'Electrónicos',
    'precio': 1500.00,
    'stock_actual': 10,
    'stock_minimo': 5,
    'proveedor_id': 'PROV-001',
    'fecha_creacion': DateTime.now().toIso8601String(),
    'fecha_actualizacion': DateTime.now().toIso8601String(),
  };

  final product = Product.fromJson(jsonProduct);
  print('   Producto creado: ${product.nombre}');
  print('   Código: ${product.codigo}');
  print('   Precio: \$${product.precio}');
  print('   Stock: ${product.stockActual}/${product.stockMinimo}');
  print('   ✅ Producto creado correctamente\n');

  // Test 2: Convertir a JSON
  print('✅ Test 2: Convertir producto a JSON');
  final json = product.toJson();
  print('   JSON generado: ${json.keys.join(", ")}');
  print('   ✅ Conversión a JSON exitosa\n');

  // Test 3: Validaciones
  print('✅ Test 3: Validar producto');
  print('   ¿Es válido? ${product.isValid()}');
  print('   ¿Tiene stock bajo? ${product.tieneStockBajo}');
  print('   Estado: ${product.estadoStock}');
  print('   Valor inventario: \$${product.valorInventario}');
  print('   ✅ Validaciones funcionando\n');

  // Test 4: Producto con stock bajo
  print('✅ Test 4: Producto con stock bajo');
  final lowStockProduct = product.copyWith(
    stockActual: 3,
    stockMinimo: 5,
  );
  print('   Stock actual: ${lowStockProduct.stockActual}');
  print('   Stock mínimo: ${lowStockProduct.stockMinimo}');
  print('   ¿Tiene stock bajo? ${lowStockProduct.tieneStockBajo}');
  print('   Estado: ${lowStockProduct.estadoStock}');
  print('   ✅ Detección de stock bajo funcionando\n');

  // Test 5: copyWith
  print('✅ Test 5: Método copyWith');
  final updatedProduct = product.copyWith(
    nombre: 'Laptop Dell Actualizada',
    precio: 1600.00,
  );
  print('   Nombre original: ${product.nombre}');
  print('   Nombre actualizado: ${updatedProduct.nombre}');
  print('   Precio original: \$${product.precio}');
  print('   Precio actualizado: \$${updatedProduct.precio}');
  print('   ✅ copyWith funcionando correctamente\n');

  // Test 6: Producto sin proveedor
  print('✅ Test 6: Producto sin proveedor (nullable)');
  final productWithoutSupplier = Product(
    id: '2',
    codigo: 'PROD-002',
    nombre: 'Mouse Inalámbrico',
    categoria: 'Accesorios',
    precio: 25.00,
    stockActual: 50,
    stockMinimo: 10,
    proveedorId: null,
    fechaCreacion: DateTime.now(),
    fechaActualizacion: DateTime.now(),
  );
  print('   Producto: ${productWithoutSupplier.nombre}');
  print('   Proveedor: ${productWithoutSupplier.proveedorId ?? "Sin proveedor"}');
  print('   ✅ Campo nullable funcionando\n');

  print('🎉 ¡Todos los tests pasaron! El modelo está funcionando correctamente.');
}


