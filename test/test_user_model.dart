/// Pruebas unitarias para el modelo User
/// 
/// Ejecutar con: dart test/test_user_model.dart

import '../lib/models/user.dart';

void main() {
  print('🧪 Iniciando pruebas del modelo User...\n');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: Crear usuario válido
  try {
    final user = User(
      id: 'user-1',
      nombre: 'Juan Pérez',
      email: 'juan@example.com',
      rol: 'admin',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    assert(user.id == 'user-1', 'El ID debería ser correcto');
    assert(user.nombre == 'Juan Pérez', 'El nombre debería ser correcto');
    assert(user.email == 'juan@example.com', 'El email debería ser correcto');
    assert(user.rol == 'admin', 'El rol debería ser correcto');
    print('✅ Test 1: Crear usuario válido');
    passed++;
  } catch (e) {
    print('❌ Test 1 falló: $e');
    failed++;
  }
  
  // Test 2: Serialización JSON
  try {
    final now = DateTime(2024, 1, 1, 12, 0);
    final user = User(
      id: 'user-1',
      nombre: 'Juan Pérez',
      email: 'juan@example.com',
      rol: 'admin',
      createdAt: now,
      updatedAt: now,
    );
    
    final json = user.toJson();
    assert(json['id'] == 'user-1', 'El ID en JSON debería ser correcto');
    assert(json['nombre'] == 'Juan Pérez', 'El nombre en JSON debería ser correcto');
    assert(json['email'] == 'juan@example.com', 'El email en JSON debería ser correcto');
    assert(json['rol'] == 'admin', 'El rol en JSON debería ser correcto');
    assert(json['created_at'] != null, 'created_at debería estar en JSON');
    assert(json['updated_at'] != null, 'updated_at debería estar en JSON');
    
    final userFromJson = User.fromJson(json);
    assert(userFromJson.id == user.id, 'El ID debería ser igual después de fromJson');
    assert(userFromJson.nombre == user.nombre, 'El nombre debería ser igual después de fromJson');
    assert(userFromJson.email == user.email, 'El email debería ser igual después de fromJson');
    print('✅ Test 2: Serialización JSON');
    passed++;
  } catch (e) {
    print('❌ Test 2 falló: $e');
    failed++;
  }
  
  // Test 3: fromJson con valores por defecto
  try {
    final json = {
      'id': 'user-2',
      'nombre': 'María García',
      'email': 'maria@example.com',
    };
    
    final user = User.fromJson(json);
    assert(user.rol == 'empleado', 'El rol por defecto debería ser empleado');
    assert(user.createdAt != null, 'createdAt debería tener un valor');
    assert(user.updatedAt != null, 'updatedAt debería tener un valor');
    print('✅ Test 3: fromJson con valores por defecto');
    passed++;
  } catch (e) {
    print('❌ Test 3 falló: $e');
    failed++;
  }
  
  // Test 4: copyWith
  try {
    final user = User(
      id: 'user-1',
      nombre: 'Juan Pérez',
      email: 'juan@example.com',
      rol: 'admin',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final updatedUser = user.copyWith(
      nombre: 'Juan Carlos Pérez',
      rol: 'empleado',
    );
    
    assert(updatedUser.nombre == 'Juan Carlos Pérez', 'El nombre debería cambiar');
    assert(updatedUser.rol == 'empleado', 'El rol debería cambiar');
    assert(updatedUser.id == user.id, 'El ID no debería cambiar');
    assert(updatedUser.email == user.email, 'El email no debería cambiar');
    print('✅ Test 4: copyWith');
    passed++;
  } catch (e) {
    print('❌ Test 5 falló: $e');
    failed++;
  }
  
  // Test 5: fromJson con diferentes formatos de fecha
  try {
    final json1 = {
      'id': 'user-3',
      'nombre': 'Pedro López',
      'email': 'pedro@example.com',
      'rol': 'admin',
      'created_at': '2024-01-01T12:00:00.000Z',
      'updated_at': '2024-01-01T12:00:00.000Z',
    };
    
    final user1 = User.fromJson(json1);
    assert(user1.createdAt.year == 2024, 'La fecha debería parsearse correctamente');
    assert(user1.updatedAt.year == 2024, 'La fecha debería parsearse correctamente');
    print('✅ Test 5: fromJson con diferentes formatos de fecha');
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


