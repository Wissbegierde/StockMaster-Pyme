import '../../models/user.dart';
import '../../models/auth_response.dart';

/// Interfaz abstracta para el servicio de autenticación
/// Permite cambiar fácilmente entre HTTP, Mock y Firebase sin modificar el código que lo usa
abstract class AuthServiceInterface {
  /// Iniciar sesión con email y contraseña
  Future<AuthResponse> login(String email, String password);

  /// Registrar nuevo usuario
  Future<AuthResponse> register(String nombre, String email, String password, String rol);

  /// Cerrar sesión
  Future<void> logout();

  /// Verificar si el usuario está autenticado
  Future<bool> isAuthenticated();

  /// Obtener token de autenticación
  Future<String?> getToken();

  /// Obtener usuario actual
  Future<User?> getCurrentUser();

  /// Validar email
  bool isValidEmail(String email);

  /// Validar contraseña
  bool isValidPassword(String password);

  /// Validar nombre
  bool isValidName(String name);

  /// Enviar correo de verificación (solo Firebase)
  Future<bool> sendEmailVerification();

  /// Verificar código de correo (solo Firebase)
  Future<bool> verifyEmail(String code);

  /// Verificar si el correo está verificado (solo Firebase)
  Future<bool> isEmailVerified();
}

