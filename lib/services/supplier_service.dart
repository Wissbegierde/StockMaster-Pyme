import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/supplier.dart';
import '../services/auth_service.dart';
import 'interfaces/supplier_service_interface.dart';

/// Servicio HTTP para proveedores
/// Implementa SupplierServiceInterface para facilitar migración a Firebase
class SupplierService implements SupplierServiceInterface {
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

  /// Parsear lista de proveedores desde JSON
  List<Supplier> _parseSuppliersList(dynamic data) {
    final List<dynamic> suppliersJson = data['data'] ?? data['suppliers'] ?? data;
    return suppliersJson
        .map((json) => Supplier.fromJson(json))
        .toList();
  }

  @override
  Future<List<Supplier>> getAll({int? page, int? limit}) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final uri = Uri.parse(ApiConfig.suppliersEndpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseSuppliersList(data);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener proveedores: ${e.toString()}');
    }
  }

  @override
  Future<Supplier?> getById(String id) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.suppliersEndpoint}/$id'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final supplierJson = data['data'] ?? data['supplier'] ?? data;
        return Supplier.fromJson(supplierJson);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        _handleError(response);
        return null;
      }
    } catch (e) {
      throw Exception('Error al obtener proveedor: ${e.toString()}');
    }
  }

  @override
  Future<Supplier> create(Supplier supplier) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.suppliersEndpoint),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(supplier.toJson()),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final supplierJson = data['data'] ?? data['supplier'] ?? data;
        return Supplier.fromJson(supplierJson);
      } else {
        _handleError(response);
        throw Exception('Error al crear proveedor');
      }
    } catch (e) {
      throw Exception('Error al crear proveedor: ${e.toString()}');
    }
  }

  @override
  Future<Supplier> update(String id, Supplier supplier) async {
    try {
      final token = await _getToken();
      final supplierJson = supplier.toJson();
      supplierJson['id'] = id; // Asegurar que el ID esté presente
      
      final response = await http.put(
        Uri.parse('${ApiConfig.suppliersEndpoint}/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(supplierJson),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final updatedSupplierJson = data['data'] ?? data['supplier'] ?? data;
        return Supplier.fromJson(updatedSupplierJson);
      } else {
        _handleError(response);
        throw Exception('Error al actualizar proveedor');
      }
    } catch (e) {
      throw Exception('Error al actualizar proveedor: ${e.toString()}');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${ApiConfig.suppliersEndpoint}/$id'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _handleError(response);
        return false;
      }
    } catch (e) {
      throw Exception('Error al eliminar proveedor: ${e.toString()}');
    }
  }

  @override
  Future<List<Supplier>> search(String query) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.suppliersEndpoint}/search').replace(
          queryParameters: {'q': query},
        ),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseSuppliersList(data);
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al buscar proveedores: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getProductsBySupplier(String supplierId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.suppliersEndpoint}/$supplierId/products'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['data'] ?? data['products'] ?? data;
        return productsJson
            .map((json) => json['id']?.toString() ?? json.toString())
            .where((id) => id.isNotEmpty)
            .toList()
            .cast<String>();
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener productos del proveedor: ${e.toString()}');
    }
  }
}

