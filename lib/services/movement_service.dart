import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/movement.dart';
import '../services/auth_service.dart';
import 'interfaces/movement_service_interface.dart';

/// Servicio HTTP para movimientos
/// Implementa MovementServiceInterface para facilitar migración a Firebase
class MovementService implements MovementServiceInterface {
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
      } catch (_) {
        throw Exception('Error en la petición: ${response.statusCode}');
      }
    }
  }

  /// Parsear lista de movimientos desde JSON
  List<Movement> _parseMovementsList(dynamic data) {
    final List<dynamic> movementsJson = data['data'] ?? data['movements'] ?? data;
    return movementsJson
        .map((json) => Movement.fromJson(json))
        .toList();
  }

  @override
  Future<List<Movement>> getAll({int? page, int? limit}) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final uri = Uri.parse(ApiConfig.movementsEndpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMovementsList(data);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener movimientos: ${e.toString()}');
    }
  }

  @override
  Future<Movement?> getById(String id) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.movementsEndpoint}/$id'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final movementJson = data['data'] ?? data['movement'] ?? data;
        return Movement.fromJson(movementJson);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        _handleError(response);
        return null;
      }
    } catch (e) {
      throw Exception('Error al obtener movimiento: ${e.toString()}');
    }
  }

  @override
  Future<Movement> create(Movement movement) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.movementsEndpoint),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(movement.toJson()),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final movementJson = data['data'] ?? data['movement'] ?? data;
        return Movement.fromJson(movementJson);
      } else {
        _handleError(response);
        throw Exception('Error al crear movimiento');
      }
    } catch (e) {
      throw Exception('Error al crear movimiento: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByProduct(String productId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.movementsEndpoint}?product_id=$productId'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMovementsList(data);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener movimientos del producto: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final token = await _getToken();
      final startStr = start.toIso8601String().split('T')[0]; // YYYY-MM-DD
      final endStr = end.toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      final response = await http.get(
        Uri.parse('${ApiConfig.movementsEndpoint}?start_date=$startStr&end_date=$endStr'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMovementsList(data);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener movimientos por rango de fechas: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByProductAndDateRange(
    String productId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final token = await _getToken();
      final startStr = start.toIso8601String().split('T')[0]; // YYYY-MM-DD
      final endStr = end.toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      final response = await http.get(
        Uri.parse('${ApiConfig.movementsEndpoint}?product_id=$productId&start_date=$startStr&end_date=$endStr'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMovementsList(data);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener movimientos del producto por rango de fechas: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getRecent(int limit) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.movementsEndpoint}/recent?limit=$limit'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMovementsList(data);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener movimientos recientes: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByType(MovementType type) async {
    try {
      final token = await _getToken();
      final tipoStr = type == MovementType.entrada 
          ? 'entrada' 
          : 'salida';
      
      final response = await http.get(
        Uri.parse('${ApiConfig.movementsEndpoint}?tipo=$tipoStr'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMovementsList(data);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener movimientos por tipo: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByUser(String userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.movementsEndpoint}?usuario_id=$userId'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseMovementsList(data);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener movimientos del usuario: ${e.toString()}');
    }
  }
}

