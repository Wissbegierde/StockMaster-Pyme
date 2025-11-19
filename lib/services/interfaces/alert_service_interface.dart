import '../../models/alert.dart';

/// Interfaz para el servicio de alertas
abstract class AlertServiceInterface {
  /// Obtener todas las alertas
  Future<List<Alert>> getAll();
  
  /// Obtener una alerta por ID
  Future<Alert?> getById(String id);
  
  /// Obtener alertas no leídas
  Future<List<Alert>> getUnread();
  
  /// Crear una nueva alerta
  Future<Alert> create(Alert alert);
  
  /// Marcar una alerta como leída
  Future<bool> markAsRead(String id);
  
  /// Marcar todas las alertas como leídas
  Future<bool> markAllAsRead();
  
  /// Eliminar una alerta
  Future<bool> delete(String id);
}

