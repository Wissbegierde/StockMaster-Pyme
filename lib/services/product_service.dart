import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import 'interfaces/product_service_interface.dart';

/// Servicio HTTP para productos
/// Implementa ProductServiceInterface para facilitar migración a Firebase
class ProductService implements ProductServiceInterface {
  final AuthService _authService = AuthService();

  /// Obtener el token de autenticación
  Future<String?> _getToken() async {
    return await _authService.getToken();
  }

  /// Manejar errores de respuesta HTTP
  void _handleError(http.Response response) {
    if (response.statusCode >= 400) {
      final data = jsonDecode(response.body);
      final message = data['message'] ?? 'Error en la petición';
      throw Exception(message);
    }
  }

  @override
  Future<List<Product>> getAll({int? page, int? limit}) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final uri = Uri.parse(ApiConfig.productsEndpoint).replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['data'] ?? data['products'] ?? data;
        
        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener productos: ${e.toString()}');
    }
  }

  @override
  Future<Product?> getById(String id) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.productsEndpoint}/$id'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productJson = data['data'] ?? data['product'] ?? data;
        return Product.fromJson(productJson);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        _handleError(response);
        return null;
      }
    } catch (e) {
      throw Exception('Error al obtener producto: ${e.toString()}');
    }
  }

  @override
  Future<Product> create(Product product) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse(ApiConfig.productsEndpoint),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(product.toJson()),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productJson = data['data'] ?? data['product'] ?? data;
        return Product.fromJson(productJson);
      } else {
        _handleError(response);
        throw Exception('Error al crear producto');
      }
    } catch (e) {
      throw Exception('Error al crear producto: ${e.toString()}');
    }
  }

  @override
  Future<Product> update(String id, Product product) async {
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${ApiConfig.productsEndpoint}/$id'),
        headers: ApiConfig.getHeaders(token: token),
        body: jsonEncode(product.toJson()),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final productJson = data['data'] ?? data['product'] ?? data;
        return Product.fromJson(productJson);
      } else {
        _handleError(response);
        throw Exception('Error al actualizar producto');
      }
    } catch (e) {
      throw Exception('Error al actualizar producto: ${e.toString()}');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${ApiConfig.productsEndpoint}/$id'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        _handleError(response);
        return false;
      }
    } catch (e) {
      throw Exception('Error al eliminar producto: ${e.toString()}');
    }
  }

  @override
  Future<List<Product>> search(String query) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.productsEndpoint}/search?q=$query'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['data'] ?? data['products'] ?? data;
        
        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al buscar productos: ${e.toString()}');
    }
  }

  @override
  Future<List<Product>> filterByCategory(String categoria) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.productsEndpoint}?categoria=$categoria'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['data'] ?? data['products'] ?? data;
        
        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al filtrar productos: ${e.toString()}');
    }
  }

  @override
  Future<bool> codigoExists(String codigo, {String? excludeId}) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{'codigo': codigo};
      if (excludeId != null) queryParams['exclude_id'] = excludeId;
      
      final uri = Uri.parse('${ApiConfig.productsEndpoint}/check-codigo').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(
        uri,
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] ?? false;
      }
      return false;
    } catch (e) {
      // Si hay error, asumimos que no existe para no bloquear el flujo
      return false;
    }
  }

  @override
  Future<List<Product>> getLowStockProducts() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.productsEndpoint}/low-stock'),
        headers: ApiConfig.getHeaders(token: token),
      ).timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> productsJson = data['data'] ?? data['products'] ?? data;
        
        return productsJson
            .map((json) => Product.fromJson(json))
            .toList();
      } else {
        _handleError(response);
        return [];
      }
    } catch (e) {
      throw Exception('Error al obtener productos con stock bajo: ${e.toString()}');
    }
  }
}

