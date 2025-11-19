// Archivo de test para verificar el modelo de Supplier
// Ejecutar con: dart test/test_supplier_model.dart

// ignore_for_file: avoid_print

import '../lib/models/supplier.dart';

void main() {
  print('🧪 Probando Modelo de Supplier...\n');

  // Test 1: Crear un proveedor desde JSON
  print('✅ Test 1: Crear proveedor desde JSON');
  final jsonSupplier = {
    'id': 'supp-001',
    'nombre': 'Proveedor ABC S.A.',
    'contacto': 'Juan Pérez',
    'telefono': '+1234567890',
    'email': 'contacto@proveedorabc.com',
    'direccion': 'Calle 123, Ciudad, País',
    'fecha_creacion': DateTime.now().toIso8601String(),
    'fecha_actualizacion': DateTime.now().toIso8601String(),
  };

  final supplier1 = Supplier.fromJson(jsonSupplier);
  print('   ID: ${supplier1.id}');
  print('   Nombre: ${supplier1.nombre}');
  print('   Contacto: ${supplier1.contacto}');
  print('   Teléfono: ${supplier1.telefono}');
  print('   Email: ${supplier1.email ?? "N/A"}');
  print('   Dirección: ${supplier1.direccion ?? "N/A"}');
  print('   Contacto completo: ${supplier1.contactoCompleto}');
  print('   Tiene email: ${supplier1.tieneEmail}');
  print('   Tiene dirección: ${supplier1.tieneDireccion}');
  print('   ✅ Proveedor creado correctamente\n');

  // Test 2: Validación de proveedor válido
  print('✅ Test 2: Validación de proveedor válido');
  final isValid = supplier1.isValid();
  print('   Es válido: $isValid');
  final error = supplier1.getValidationError();
  print('   Error de validación: ${error ?? "Ninguno"}');
  assert(isValid == true, 'El proveedor debería ser válido');
  assert(error == null, 'No debería haber errores de validación');
  print('   ✅ Validación correcta\n');

  // Test 3: Validación de nombre vacío
  print('✅ Test 3: Validación de nombre vacío');
  final supplierInvalid1 = Supplier(
    id: 'supp-002',
    nombre: '',
    contacto: 'María García',
    telefono: '12345678',
    fechaCreacion: DateTime.now(),
    fechaActualizacion: DateTime.now(),
  );
  final isValid1 = supplierInvalid1.isValid();
  final error1 = supplierInvalid1.getValidationError();
  print('   Es válido: $isValid1');
  print('   Error: ${error1 ?? "Ninguno"}');
  assert(isValid1 == false, 'El proveedor no debería ser válido');
  assert(error1 != null, 'Debería haber un error de validación');
  print('   ✅ Validación de nombre vacío correcta\n');

  // Test 4: Validación de nombre muy corto
  print('✅ Test 4: Validación de nombre muy corto');
  final supplierInvalid2 = Supplier(
    id: 'supp-003',
    nombre: 'AB',
    contacto: 'María García',
    telefono: '12345678',
    fechaCreacion: DateTime.now(),
    fechaActualizacion: DateTime.now(),
  );
  final isValid2 = supplierInvalid2.isValid();
  final error2 = supplierInvalid2.getValidationError();
  print('   Es válido: $isValid2');
  print('   Error: ${error2 ?? "Ninguno"}');
  assert(isValid2 == false, 'El proveedor no debería ser válido');
  assert(error2 != null && error2!.contains('3 caracteres'), 'Debería indicar mínimo 3 caracteres');
  print('   ✅ Validación de nombre corto correcta\n');

  // Test 5: Validación de teléfono muy corto
  print('✅ Test 5: Validación de teléfono muy corto');
  final supplierInvalid3 = Supplier(
    id: 'supp-004',
    nombre: 'Proveedor XYZ',
    contacto: 'María García',
    telefono: '123',
    fechaCreacion: DateTime.now(),
    fechaActualizacion: DateTime.now(),
  );
  final isValid3 = supplierInvalid3.isValid();
  final error3 = supplierInvalid3.getValidationError();
  print('   Es válido: $isValid3');
  print('   Error: ${error3 ?? "Ninguno"}');
  assert(isValid3 == false, 'El proveedor no debería ser válido');
  assert(error3 != null && error3!.contains('8 caracteres'), 'Debería indicar mínimo 8 caracteres');
  print('   ✅ Validación de teléfono corto correcta\n');

  // Test 6: Validación de email inválido
  print('✅ Test 6: Validación de email inválido');
  final supplierInvalid4 = Supplier(
    id: 'supp-005',
    nombre: 'Proveedor XYZ',
    contacto: 'María García',
    telefono: '12345678',
    email: 'email-invalido',
    fechaCreacion: DateTime.now(),
    fechaActualizacion: DateTime.now(),
  );
  final isValid4 = supplierInvalid4.isValid();
  final error4 = supplierInvalid4.getValidationError();
  print('   Es válido: $isValid4');
  print('   Error: ${error4 ?? "Ninguno"}');
  assert(isValid4 == false, 'El proveedor no debería ser válido');
  assert(error4 != null && error4!.contains('email'), 'Debería indicar error de email');
  print('   ✅ Validación de email inválido correcta\n');

  // Test 7: Validación de email válido (opcional)
  print('✅ Test 7: Validación con email válido (opcional)');
  final supplierValid = Supplier(
    id: 'supp-006',
    nombre: 'Proveedor XYZ',
    contacto: 'María García',
    telefono: '12345678',
    email: 'contacto@proveedor.com',
    fechaCreacion: DateTime.now(),
    fechaActualizacion: DateTime.now(),
  );
  final isValid5 = supplierValid.isValid();
  final error5 = supplierValid.getValidationError();
  print('   Es válido: $isValid5');
  print('   Error: ${error5 ?? "Ninguno"}');
  assert(isValid5 == true, 'El proveedor debería ser válido');
  assert(error5 == null, 'No debería haber errores');
  print('   ✅ Validación con email válido correcta\n');

  // Test 8: Validación sin email (opcional)
  print('✅ Test 8: Validación sin email (opcional)');
  final supplierSinEmail = Supplier(
    id: 'supp-007',
    nombre: 'Proveedor XYZ',
    contacto: 'María García',
    telefono: '12345678',
    fechaCreacion: DateTime.now(),
    fechaActualizacion: DateTime.now(),
  );
  final isValid6 = supplierSinEmail.isValid();
  final error6 = supplierSinEmail.getValidationError();
  print('   Es válido: $isValid6');
  print('   Error: ${error6 ?? "Ninguno"}');
  assert(isValid6 == true, 'El proveedor debería ser válido sin email');
  assert(error6 == null, 'No debería haber errores');
  print('   ✅ Validación sin email correcta\n');

  // Test 9: Serialización JSON (toJson)
  print('✅ Test 9: Serialización JSON (toJson)');
  final json = supplier1.toJson();
  print('   JSON generado:');
  json.forEach((key, value) {
    print('     $key: $value');
  });
  assert(json['id'] == supplier1.id, 'ID debe coincidir');
  assert(json['nombre'] == supplier1.nombre, 'Nombre debe coincidir');
  assert(json['contacto'] == supplier1.contacto, 'Contacto debe coincidir');
  assert(json['telefono'] == supplier1.telefono, 'Teléfono debe coincidir');
  assert(json['email'] == supplier1.email, 'Email debe coincidir');
  print('   ✅ Serialización JSON correcta\n');

  // Test 10: Deserialización desde JSON (fromJson)
  print('✅ Test 10: Deserialización desde JSON (fromJson)');
  final supplier2 = Supplier.fromJson(json);
  assert(supplier2.id == supplier1.id, 'ID debe coincidir');
  assert(supplier2.nombre == supplier1.nombre, 'Nombre debe coincidir');
  assert(supplier2.contacto == supplier1.contacto, 'Contacto debe coincidir');
  assert(supplier2.telefono == supplier1.telefono, 'Teléfono debe coincidir');
  assert(supplier2.email == supplier1.email, 'Email debe coincidir');
  print('   ✅ Deserialización JSON correcta\n');

  // Test 11: copyWith
  print('✅ Test 11: Método copyWith');
  final supplier3 = supplier1.copyWith(
    nombre: 'Proveedor Modificado',
    email: 'nuevo@email.com',
  );
  assert(supplier3.id == supplier1.id, 'ID debe mantenerse');
  assert(supplier3.nombre == 'Proveedor Modificado', 'Nombre debe cambiar');
  assert(supplier3.contacto == supplier1.contacto, 'Contacto debe mantenerse');
  assert(supplier3.email == 'nuevo@email.com', 'Email debe cambiar');
  print('   Nombre original: ${supplier1.nombre}');
  print('   Nombre modificado: ${supplier3.nombre}');
  print('   ✅ copyWith funciona correctamente\n');

  // Test 12: Validación con requireId
  print('✅ Test 12: Validación con requireId=true');
  final supplierSinId = Supplier(
    id: '',
    nombre: 'Proveedor XYZ',
    contacto: 'María García',
    telefono: '12345678',
    fechaCreacion: DateTime.now(),
    fechaActualizacion: DateTime.now(),
  );
  final isValidSinId = supplierSinId.isValid(requireId: true);
  final errorSinId = supplierSinId.getValidationError(requireId: true);
  print('   Es válido (requireId=true): $isValidSinId');
  print('   Error: ${errorSinId ?? "Ninguno"}');
  assert(isValidSinId == false, 'No debería ser válido sin ID cuando requireId=true');
  assert(errorSinId != null && errorSinId!.contains('ID'), 'Debería indicar error de ID');
  
  final isValidConId = supplier1.isValid(requireId: true);
  print('   Es válido con ID (requireId=true): $isValidConId');
  assert(isValidConId == true, 'Debería ser válido con ID');
  print('   ✅ Validación con requireId correcta\n');

  print('🎉 ¡Todos los tests pasaron correctamente!');
}


