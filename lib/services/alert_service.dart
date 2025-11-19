import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/alert.dart';
import '../services/auth_service.dart';
import 'interfaces/alert_service_interface.dart';

/// Servicio HTTP para alertas
/// Implementa AlertServiceInterface para facilitar migración a Firebase
class AlertService implements AlertServiceInterface {
  final AuthService _authService = AuthService();

  /// Obtener el token de autenticación
  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  /// Manejar errores de respuesta HTTP
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      try {
        final data = jsonDecode(response.body);
        final message = data['message'] ?? 'Error en la petición';
        throw Exception(message);
      } catch (e) {
        throw Exception('Error en la petición: ${response.statusCode}');
      }
    }
  }

  @override
  Future<List<Alert>> getAll() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/alerts');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      _handleError(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> alertsJson = data['data'] ?? data['alerts'] ?? data;
        
        return alertsJson
            .map((json) => Alert.fromJson(json))
            .toList();
      }

      throw Exception('Error al obtener alertas');
    } catch (e) {
      throw Exception('Error al obtener alertas: ${e.toString()}');
    }
  }

  @override
  Future<Alert?> getById(String id) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/alerts/$id');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 404) {
        return null;
      }

      _handleError(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Alert.fromJson(data['data'] ?? data);
      }

      throw Exception('Error al obtener alerta');
    } catch (e) {
      throw Exception('Error al obtener alerta: ${e.toString()}');
    }
  }

  @override
  Future<List<Alert>> getUnread() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/alerts/unread');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      _handleError(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> alertsJson = data['data'] ?? data['alerts'] ?? data;
        
        return alertsJson
            .map((json) => Alert.fromJson(json))
            .toList();
      }

      throw Exception('Error al obtener alertas no leídas');
    } catch (e) {
      throw Exception('Error al obtener alertas no leídas: ${e.toString()}');
    }
  }

  @override
  Future<Alert> create(Alert alert) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/alerts');

      final response = await http.post(
        uri,
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(alert.toJson()),
      ).timeout(ApiConfig.requestTimeout);

      _handleError(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Alert.fromJson(data['data'] ?? data);
      }

      throw Exception('Error al crear alerta');
    } catch (e) {
      throw Exception('Error al crear alerta: ${e.toString()}');
    }
  }

  @override
  Future<bool> markAsRead(String id) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/alerts/$id/read');

      final response = await http.put(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      _handleError(response);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al marcar alerta como leída: ${e.toString()}');
    }
  }

  @override
  Future<bool> markAllAsRead() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/alerts/read-all');

      final response = await http.put(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      _handleError(response);

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error al marcar todas las alertas como leídas: ${e.toString()}');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.baseUrl}/alerts/$id');

      final response = await http.delete(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 404) {
        return false;
      }

      _handleError(response);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error al eliminar alerta: ${e.toString()}');
    }
  }
}

