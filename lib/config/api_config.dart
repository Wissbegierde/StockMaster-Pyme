/// Configuración centralizada de la API
/// Facilita el cambio entre diferentes backends (HTTP, Firebase, etc.)
class ApiConfig {
  // URL base del backend
  // Cambiar esta URL cuando se migre a producción o Firebase
  static const String baseUrl = 'http://localhost:3000/api';
  
  // Endpoints
  static const String authEndpoint = '$baseUrl/auth';
  static const String productsEndpoint = '$baseUrl/products';
  static const String suppliersEndpoint = '$baseUrl/suppliers';
  static const String movementsEndpoint = '$baseUrl/movements';
  static const String dashboardEndpoint = '$baseUrl/dashboard';
  
  // Headers comunes
  static Map<String, String> getHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Timeout para peticiones (en segundos)
  static const Duration requestTimeout = Duration(seconds: 30);
}

