import 'package:flutter/foundation.dart';
import '../models/alert.dart';
import '../services/alert_service.dart';
import '../services/alert_service_mock.dart';
import '../services/firebase_alert_service.dart';
import '../services/interfaces/alert_service_interface.dart';
import '../config/app_config.dart';

class AlertProvider with ChangeNotifier {
  // Factory pattern: crear el servicio según la configuración
  final AlertServiceInterface _alertService = _createAlertService();
  
  /// Factory method para crear el servicio correcto según la configuración
  static AlertServiceInterface _createAlertService() {
    switch (AppConfig.backendType) {
      case BackendType.mock:
        return AlertServiceMock();
      case BackendType.http:
        return AlertService();
      case BackendType.firebase:
        return FirebaseAlertService();
    }
  }
  
  List<Alert> _alerts = [];
  Alert? _selectedAlert;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoadingAlerts = false; // Flag para evitar llamadas simultáneas
  
  // Getters
  List<Alert> get alerts => _alerts;
  Alert? get selectedAlert => _selectedAlert;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Getters calculados
  List<Alert> get unreadAlerts => _alerts.where((alert) => !alert.leida).toList();
  int get unreadCount => unreadAlerts.length;
  
  List<Alert> get readAlerts => _alerts.where((alert) => alert.leida).toList();
  
  // Cargar todas las alertas
  Future<void> loadAlerts() async {
    debugPrint('[AlertProvider] loadAlerts called - _isLoadingAlerts: $_isLoadingAlerts');
    
    // Evitar llamadas simultáneas
    if (_isLoadingAlerts) {
      debugPrint('[AlertProvider] Already loading alerts, skipping...');
      return;
    }
    
    _isLoadingAlerts = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _alerts = await _alertService.getAll();
      debugPrint('[AlertProvider] Alerts loaded: ${_alerts.length}');
    } catch (e) {
      debugPrint('[AlertProvider] Error loading alerts: $e');
      _errorMessage = 'Error al cargar alertas: ${e.toString()}';
    } finally {
      _isLoading = false;
      _isLoadingAlerts = false;
      notifyListeners();
    }
  }
  
  // Cargar una alerta por ID
  Future<void> loadAlertById(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      _selectedAlert = await _alertService.getById(id);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar alerta: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Cargar alertas no leídas
  Future<void> loadUnreadAlerts() async {
    _setLoading(true);
    _clearError();
    
    try {
      _alerts = await _alertService.getUnread();
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar alertas no leídas: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Crear nueva alerta
  Future<bool> createAlert(Alert alert) async {
    _setLoading(true);
    _clearError();
    
    try {
      final created = await _alertService.create(alert);
      _alerts.insert(0, created); // Agregar al inicio
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear alerta: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Marcar alerta como leída
  Future<bool> markAsRead(String id) async {
    _clearError();
    
    try {
      final success = await _alertService.markAsRead(id);
      if (success) {
        final index = _alerts.indexWhere((alert) => alert.id == id);
        if (index != -1) {
          final alert = _alerts[index];
          _alerts[index] = alert.copyWith(
            leida: true,
            fechaLectura: DateTime.now(),
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _setError('Error al marcar alerta como leída: ${e.toString()}');
      return false;
    }
  }
  
  // Marcar todas las alertas como leídas
  Future<bool> markAllAsRead() async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _alertService.markAllAsRead();
      if (success) {
        final now = DateTime.now();
        _alerts = _alerts.map((alert) {
          if (!alert.leida) {
            return alert.copyWith(
              leida: true,
              fechaLectura: now,
            );
          }
          return alert;
        }).toList();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Error al marcar todas las alertas como leídas: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Eliminar alerta
  Future<bool> deleteAlert(String id) async {
    _clearError();
    
    try {
      final success = await _alertService.delete(id);
      if (success) {
        _alerts.removeWhere((alert) => alert.id == id);
        if (_selectedAlert?.id == id) {
          _selectedAlert = null;
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Error al eliminar alerta: ${e.toString()}');
      return false;
    }
  }
  
  // Seleccionar alerta
  void selectAlert(Alert alert) {
    _selectedAlert = alert;
    notifyListeners();
  }
  
  // Limpiar selección
  void clearSelection() {
    _selectedAlert = null;
    notifyListeners();
  }
  
  // Helpers privados
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  void _clearError() {
    _errorMessage = null;
  }
}

