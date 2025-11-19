/// Configuración de la aplicación
/// Permite cambiar entre modo desarrollo (mock), HTTP y Firebase
enum BackendType {
  mock,    // Usar servicios mock para desarrollo
  http,    // Usar backend HTTP REST
  firebase // Usar Firebase Firestore
}

class AppConfig {
  // Tipo de backend a usar
  // Cambiar según necesites: BackendType.mock, BackendType.http, o BackendType.firebase
  static const BackendType backendType = BackendType.firebase;
  
  // URL del backend (solo se usa si backendType = BackendType.http)
  static const String backendUrl = 'http://localhost:3000/api';
  
  // Getters de compatibilidad (para código existente)
  @Deprecated('Usar backendType en su lugar')
  static bool get useMockServices => backendType == BackendType.mock;
}

