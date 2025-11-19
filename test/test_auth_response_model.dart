/// Pruebas unitarias para el modelo AuthResponse
/// 
/// Ejecutar con: dart test/test_auth_response_model.dart

import '../lib/models/auth_response.dart';
import '../lib/models/user.dart';

void main() {
  print('🧪 Iniciando pruebas del modelo AuthResponse...\n');
  
  int passed = 0;
  int failed = 0;
  
  // Test 1: Crear AuthResponse exitoso
  try {
    final user = User(
      id: 'user-1',
      nombre: 'Juan Pérez',
      email: 'juan@example.com',
      rol: 'admin',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final response = AuthResponse(
      success: true,
      message: 'Login exitoso',
      token: 'token-123',
      user: user,
    );
    
    assert(response.success == true, 'Success debería ser true');
    assert(response.message == 'Login exitoso', 'El mensaje debería ser correcto');
    assert(response.token == 'token-123', 'El token debería ser correcto');
    assert(response.user != null, 'El usuario debería existir');
    assert(response.user!.id == 'user-1', 'El ID del usuario debería ser correcto');
    print('✅ Test 1: Crear AuthResponse exitoso');
    passed++;
  } catch (e) {
    print('❌ Test 1 falló: $e');
    failed++;
  }
  
  // Test 2: Crear AuthResponse con error
  try {
    final response = AuthResponse(
      success: false,
      message: 'Credenciales inválidas',
    );
    
    assert(response.success == false, 'Success debería ser false');
    assert(response.message == 'Credenciales inválidas', 'El mensaje debería ser correcto');
    assert(response.token == null, 'El token debería ser null');
    assert(response.user == null, 'El usuario debería ser null');
    print('✅ Test 2: Crear AuthResponse con error');
    passed++;
  } catch (e) {
    print('❌ Test 2 falló: $e');
    failed++;
  }
  
  // Test 3: Serialización JSON - éxito
  try {
    final user = User(
      id: 'user-1',
      nombre: 'Juan Pérez',
      email: 'juan@example.com',
      rol: 'admin',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 1),
    );
    
    final response = AuthResponse(
      success: true,
      message: 'Login exitoso',
      token: 'token-123',
      user: user,
    );
    
    final json = response.toJson();
    assert(json['success'] == true, 'Success en JSON debería ser true');
    assert(json['message'] == 'Login exitoso', 'El mensaje en JSON debería ser correcto');
    assert(json['token'] == 'token-123', 'El token en JSON debería ser correcto');
    assert(json['user'] != null, 'El usuario en JSON debería existir');
    assert(json['user']['id'] == 'user-1', 'El ID del usuario en JSON debería ser correcto');
    
    final responseFromJson = AuthResponse.fromJson(json);
    assert(responseFromJson.success == response.success, 'Success debería ser igual después de fromJson');
    assert(responseFromJson.message == response.message, 'El mensaje debería ser igual después de fromJson');
    assert(responseFromJson.token == response.token, 'El token debería ser igual después de fromJson');
    assert(responseFromJson.user?.id == response.user?.id, 'El ID del usuario debería ser igual después de fromJson');
    print('✅ Test 3: Serialización JSON - éxito');
    passed++;
  } catch (e) {
    print('❌ Test 3 falló: $e');
    failed++;
  }
  
  // Test 4: Serialización JSON - error
  try {
    final response = AuthResponse(
      success: false,
      message: 'Error de autenticación',
    );
    
    final json = response.toJson();
    assert(json['success'] == false, 'Success en JSON debería ser false');
    assert(json['message'] == 'Error de autenticación', 'El mensaje en JSON debería ser correcto');
    assert(json['token'] == null, 'El token en JSON debería ser null');
    assert(json['user'] == null, 'El usuario en JSON debería ser null');
    
    final responseFromJson = AuthResponse.fromJson(json);
    assert(responseFromJson.success == false, 'Success debería ser false después de fromJson');
    assert(responseFromJson.user == null, 'El usuario debería ser null después de fromJson');
    print('✅ Test 4: Serialización JSON - error');
    passed++;
  } catch (e) {
    print('❌ Test 4 falló: $e');
    failed++;
  }
  
  // Test 5: fromJson con valores por defecto
  try {
    final json = {
      'message': 'Mensaje de prueba',
    };
    
    final response = AuthResponse.fromJson(json);
    assert(response.success == false, 'Success por defecto debería ser false');
    assert(response.message == 'Mensaje de prueba', 'El mensaje debería ser correcto');
    assert(response.token == null, 'El token debería ser null');
    assert(response.user == null, 'El usuario debería ser null');
    print('✅ Test 5: fromJson con valores por defecto');
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


