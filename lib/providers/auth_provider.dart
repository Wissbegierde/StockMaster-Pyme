import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/auth_service_mock.dart';
import '../services/firebase_auth_service.dart';
import '../services/interfaces/auth_service_interface.dart';
import '../config/app_config.dart';

class AuthProvider with ChangeNotifier {
  // Factory pattern: crear el servicio según la configuración
  final AuthServiceInterface _authService = _createAuthService();
  
  /// Factory method para crear el servicio correcto según la configuración
  static AuthServiceInterface _createAuthService() {
    switch (AppConfig.backendType) {
      case BackendType.mock:
        return AuthServiceMock();
      case BackendType.http:
        return AuthService();
      case BackendType.firebase:
        return FirebaseAuthService();
    }
  }
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Inicializar el provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      if (await _authService.isAuthenticated()) {
        _currentUser = await _authService.getCurrentUser();
      }
    } catch (e) {
      _setError('Error al inicializar la autenticación: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authService.login(email, password);
      
      if (response.success && response.user != null) {
        _currentUser = response.user;
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Registro
  Future<bool> register(String nombre, String email, String password, String rol) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _authService.register(nombre, email, password, rol);
      
      if (response.success && response.user != null) {
        _currentUser = response.user;
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error inesperado: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Error al cerrar sesión: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Enviar correo de verificación
  Future<bool> sendEmailVerification() async {
    debugPrint('[AuthProvider] sendEmailVerification called');
    try {
      final result = await _authService.sendEmailVerification();
      debugPrint('[AuthProvider] sendEmailVerification result: $result');
      if (!result) {
        _setError('No se pudo enviar el correo. El correo puede estar ya verificado.');
      }
      return result;
    } catch (e) {
      debugPrint('[AuthProvider] Error en sendEmailVerification: $e');
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  // Verificar correo con código
  Future<bool> verifyEmail(String code) async {
    try {
      return await _authService.verifyEmail(code);
    } catch (e) {
      _setError('Error al verificar correo: ${e.toString()}');
      return false;
    }
  }

  // Verificar si el correo está verificado
  Future<bool> isEmailVerified() async {
    try {
      return await _authService.isEmailVerified();
    } catch (e) {
      return false;
    }
  }

  // Validar formulario de login
  String? validateLoginForm(String email, String password) {
    if (email.isEmpty) {
      return 'El email es requerido';
    }
    if (!_authService.isValidEmail(email)) {
      return 'El email no es válido';
    }
    if (password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (!_authService.isValidPassword(password)) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  // Validar formulario de registro
  String? validateRegisterForm(String nombre, String email, String password, String confirmPassword, String rol) {
    if (nombre.isEmpty) {
      return 'El nombre es requerido';
    }
    if (!_authService.isValidName(nombre)) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (email.isEmpty) {
      return 'El email es requerido';
    }
    if (!_authService.isValidEmail(email)) {
      return 'El email no es válido';
    }
    if (password.isEmpty) {
      return 'La contraseña es requerida';
    }
    if (!_authService.isValidPassword(password)) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    if (confirmPassword.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (password != confirmPassword) {
      return 'Las contraseñas no coinciden';
    }
    if (rol.isEmpty) {
      return 'Selecciona un rol';
    }
    return null;
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
