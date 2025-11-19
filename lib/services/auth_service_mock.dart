import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import 'interfaces/auth_service_interface.dart';

/// Servicio mock de autenticación para desarrollo sin backend
/// Simula respuestas del servidor para probar la UI
class AuthServiceMock implements AuthServiceInterface {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  
  // Usuarios simulados en memoria
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'nombre': 'Admin',
      'email': 'admin@test.com',
      'password': 'admin123',
      'rol': 'admin',
    },
    {
      'id': '2',
      'nombre': 'Empleado',
      'email': 'empleado@test.com',
      'password': 'empleado123',
      'rol': 'empleado',
    },
  ];

  // Simular delay de red
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<AuthResponse> login(String email, String password) async {
    await _simulateDelay();
    
    // Buscar usuario
    final user = _mockUsers.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => {},
    );

    if (user.isEmpty) {
      return AuthResponse(
        success: false,
        message: 'Email o contraseña incorrectos',
      );
    }

    // Crear token simulado
    final token = 'mock_token_${user['id']}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Guardar datos
    await _saveAuthData(token, {
      'id': user['id'],
      'nombre': user['nombre'],
      'email': user['email'],
      'rol': user['rol'],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return AuthResponse(
      success: true,
      message: 'Login exitoso',
      user: User(
        id: user['id'] as String,
        nombre: user['nombre'] as String,
        email: user['email'] as String,
        rol: user['rol'] as String,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      token: token,
    );
  }

  Future<AuthResponse> register(String nombre, String email, String password, String rol) async {
    await _simulateDelay();
    
    // Verificar si el email ya existe
    final emailExists = _mockUsers.any((u) => u['email'] == email);
    if (emailExists) {
      return AuthResponse(
        success: false,
        message: 'El email ya está registrado',
      );
    }

    // Crear nuevo usuario
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'nombre': nombre,
      'email': email,
      'password': password,
      'rol': rol,
    };
    
    _mockUsers.add(newUser);

    // Crear token simulado
    final token = 'mock_token_${newUser['id']}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Guardar datos
    await _saveAuthData(token, {
      'id': newUser['id'],
      'nombre': newUser['nombre'],
      'email': newUser['email'],
      'rol': newUser['rol'],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return AuthResponse(
      success: true,
      message: 'Registro exitoso',
      user: User(
        id: newUser['id'] as String,
        nombre: newUser['nombre'] as String,
        email: newUser['email'] as String,
        rol: newUser['rol'] as String,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      token: token,
    );
  }

  Future<void> logout() async {
    await _simulateDelay();
    await _clearAuthData();
  }

  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.startsWith('mock_token_');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, jsonEncode(userData));
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  @override
  Future<bool> sendEmailVerification() async {
    // No aplica para Mock
    return false;
  }

  @override
  Future<bool> verifyEmail(String code) async {
    // No aplica para Mock
    return false;
  }

  @override
  Future<bool> isEmailVerified() async {
    // No aplica para Mock, siempre verificado
    return true;
  }
}

