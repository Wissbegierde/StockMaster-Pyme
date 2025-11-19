import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/dashboard_stats.dart';
import '../services/auth_service.dart';
import 'interfaces/dashboard_service_interface.dart';

/// Servicio HTTP para dashboard
/// Implementa DashboardServiceInterface para facilitar migración a Firebase
class DashboardService implements DashboardServiceInterface {
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
  Future<DashboardStats> getStats() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.dashboardEndpoint}/stats');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      _handleError(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DashboardStats.fromJson(data['data'] ?? data);
      }

      throw Exception('Error al obtener estadísticas del dashboard');
    } catch (e) {
      throw Exception('Error al obtener estadísticas: ${e.toString()}');
    }
  }

  @override
  Future<int> getLowStockCount() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.dashboardEndpoint}/low-stock');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      _handleError(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['count'] ?? data['count'] ?? 0;
      }

      throw Exception('Error al obtener cantidad de productos con stock bajo');
    } catch (e) {
      throw Exception('Error al obtener stock bajo: ${e.toString()}');
    }
  }

  @override
  Future<double> getTotalInventoryValue() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.dashboardEndpoint}/inventory-value');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      _handleError(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data']?['value'] ?? data['value'] ?? 0.0).toDouble();
      }

      throw Exception('Error al obtener valor del inventario');
    } catch (e) {
      throw Exception('Error al obtener valor del inventario: ${e.toString()}');
    }
  }

  @override
  Future<int> getMovementsToday() async {
    try {
      final token = await _getToken();
      final uri = Uri.parse('${ApiConfig.dashboardEndpoint}/movements-today');

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      _handleError(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']?['count'] ?? data['count'] ?? 0;
      }

      throw Exception('Error al obtener movimientos del día');
    } catch (e) {
      throw Exception('Error al obtener movimientos del día: ${e.toString()}');
    }
  }
}

