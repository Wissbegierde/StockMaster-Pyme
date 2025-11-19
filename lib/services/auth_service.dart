import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import 'interfaces/auth_service_interface.dart';

class AuthService implements AuthServiceInterface {
  static const String baseUrl = 'http://localhost:3000/api/auth'; // Cambiar por la URL real del backend
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';

  // Login
  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200 && data['success']) {
        // Guardar token y datos del usuario
        await _saveAuthData(data['token'], data['user']);
        return AuthResponse.fromJson(data);
      } else {
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Error al iniciar sesión',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  // Registro
  Future<AuthResponse> register(String nombre, String email, String password, String rol) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
          'rol': rol,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 201 && data['success']) {
        // Guardar token y datos del usuario
        await _saveAuthData(data['token'], data['user']);
        return AuthResponse.fromJson(data);
      } else {
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Error al registrarse',
        );
      }
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error de conexión: ${e.toString()}',
      );
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      }
    } catch (e) {
      print('Error al cerrar sesión: $e');
    } finally {
      await _clearAuthData();
    }
  }

  // Verificar si el usuario está autenticado
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }

  // Obtener token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Obtener usuario actual
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(userKey);
    if (userJson != null) {
      return User.fromJson(jsonDecode(userJson));
    }
    return null;
  }

  // Guardar datos de autenticación
  Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, jsonEncode(userData));
  }

  // Limpiar datos de autenticación
  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
  }

  // Validar email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // Validar contraseña
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  // Validar nombre
  bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  @override
  Future<bool> sendEmailVerification() async {
    // No aplica para HTTP
    return false;
  }

  @override
  Future<bool> verifyEmail(String code) async {
    // No aplica para HTTP
    return false;
  }

  @override
  Future<bool> isEmailVerified() async {
    // No aplica para HTTP
    return true;
  }
}
