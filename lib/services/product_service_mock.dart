import 'dart:async';
import '../models/product.dart';
import 'interfaces/product_service_interface.dart';

/// Servicio mock de productos para desarrollo sin backend
/// Simula respuestas del servidor para probar la UI
class ProductServiceMock implements ProductServiceInterface {
  // Productos simulados en memoria
  final List<Product> _mockProducts = [];
  int _nextId = 1;

  // Simular delay de red
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<Product>> getAll({int? page, int? limit}) async {
    await _simulateDelay();
    return List<Product>.from(_mockProducts);
  }

  @override
  Future<Product?> getById(String id) async {
    await _simulateDelay();
    try {
      return _mockProducts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Product> create(Product product) async {
    await _simulateDelay();
    
    // Verificar código único
    if (_mockProducts.any((p) => p.codigo == product.codigo)) {
      throw Exception('El código de producto ya existe');
    }

    // Crear nuevo producto con ID
    final newProduct = product.copyWith(
      id: _nextId.toString(),
      fechaCreacion: DateTime.now(),
      fechaActualizacion: DateTime.now(),
    );
    
    _nextId++;
    _mockProducts.add(newProduct);
    
    return newProduct;
  }

  @override
  Future<Product> update(String id, Product product) async {
    await _simulateDelay();
    
    // Verificar código único (excluyendo el producto actual)
    if (_mockProducts.any((p) => p.codigo == product.codigo && p.id != id)) {
      throw Exception('El código de producto ya existe');
    }

    final index = _mockProducts.indexWhere((p) => p.id == id);
    if (index == -1) {
      throw Exception('Producto no encontrado');
    }

    final updatedProduct = product.copyWith(
      id: id,
      fechaActualizacion: DateTime.now(),
    );
    
    _mockProducts[index] = updatedProduct;
    return updatedProduct;
  }

  @override
  Future<bool> delete(String id) async {
    await _simulateDelay();
    
    final index = _mockProducts.indexWhere((p) => p.id == id);
    if (index == -1) {
      return false;
    }
    
    _mockProducts.removeAt(index);
    return true;
  }

  @override
  Future<List<Product>> search(String query) async {
    await _simulateDelay();
    
    final lowerQuery = query.toLowerCase();
    return _mockProducts.where((product) {
      return product.nombre.toLowerCase().contains(lowerQuery) ||
             product.codigo.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  @override
  Future<List<Product>> filterByCategory(String categoria) async {
    await _simulateDelay();
    return _mockProducts.where((p) => p.categoria == categoria).toList();
  }

  @override
  Future<bool> codigoExists(String codigo, {String? excludeId}) async {
    await _simulateDelay();
    return _mockProducts.any((p) => 
      p.codigo == codigo && (excludeId == null || p.id != excludeId)
    );
  }

  @override
  Future<List<Product>> getLowStockProducts() async {
    await _simulateDelay();
    return _mockProducts.where((p) => p.tieneStockBajo).toList();
  }
}

