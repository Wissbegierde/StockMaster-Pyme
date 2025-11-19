import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';
import '../services/product_service_mock.dart';
import '../services/firebase_product_service.dart';
import '../services/interfaces/product_service_interface.dart';
import '../config/app_config.dart';

class ProductProvider with ChangeNotifier {
  // Factory pattern: crear el servicio según la configuración
  final ProductServiceInterface _productService = _createProductService();
  
  /// Factory method para crear el servicio correcto según la configuración
  static ProductServiceInterface _createProductService() {
    switch (AppConfig.backendType) {
      case BackendType.mock:
        return ProductServiceMock();
      case BackendType.http:
        return ProductService();
      case BackendType.firebase:
        return FirebaseProductService();
    }
  }
  
  List<Product> _products = [];
  Product? _selectedProduct;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoadingProducts = false; // Flag para evitar llamadas simultáneas
  
  // Getters
  List<Product> get products => _products;
  Product? get selectedProduct => _selectedProduct;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  String? get selectedCategory => _selectedCategory;
  
  // Getters calculados
  int get totalProducts => _products.length;
  
  int get lowStockCount => _products.where((p) => p.tieneStockBajo).length;
  
  double get totalInventoryValue {
    return _products.fold(0.0, (sum, product) => sum + product.valorInventario);
  }
  
  List<Product> get filteredProducts {
    var filtered = List<Product>.from(_products);
    
    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        return product.nombre.toLowerCase().contains(query) ||
               product.codigo.toLowerCase().contains(query);
      }).toList();
    }
    
    // Filtrar por categoría
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.categoria == _selectedCategory;
      }).toList();
    }
    
    return filtered;
  }
  
  List<String> get categories {
    final cats = _products.map((p) => p.categoria).toSet().toList();
    cats.sort();
    return cats;
  }
  
  // Cargar todos los productos
  Future<void> loadProducts({int? page, int? limit}) async {
    debugPrint('[ProductProvider] loadProducts called - _isLoadingProducts: $_isLoadingProducts, _isLoading: $_isLoading');
    
    // Evitar llamadas simultáneas
    if (_isLoadingProducts) {
      debugPrint('[ProductProvider] Already loading products, skipping...');
      return;
    }
    
    _isLoadingProducts = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    debugPrint('[ProductProvider] Loading started, notifyListeners called');
    
    try {
      _products = await _productService.getAll(page: page, limit: limit);
      debugPrint('[ProductProvider] Products loaded: ${_products.length}');
    } catch (e) {
      debugPrint('[ProductProvider] Error loading products: $e');
      _errorMessage = 'Error al cargar productos: ${e.toString()}';
    } finally {
      _isLoading = false;
      _isLoadingProducts = false;
      notifyListeners();
      debugPrint('[ProductProvider] Loading completed, notifyListeners called');
    }
  }
  
  // Cargar un producto por ID
  Future<void> loadProductById(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      _selectedProduct = await _productService.getById(id);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar producto: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Crear un nuevo producto
  Future<bool> createProduct(Product product) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Validar que el código no exista
      final codigoExists = await _productService.codigoExists(product.codigo);
      if (codigoExists) {
        _setError('El código de producto ya existe');
        return false;
      }
      
      // Validar el producto
      if (!product.isValid()) {
        _setError('Los datos del producto no son válidos');
        return false;
      }
      
      final newProduct = await _productService.create(product);
      _products.add(newProduct);
      notifyListeners();
      
      // Verificar y crear alerta de stock bajo si aplica
      _checkAndCreateLowStockAlert(newProduct);
      
      return true;
    } catch (e) {
      _setError('Error al crear producto: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Actualizar un producto
  Future<bool> updateProduct(String id, Product product) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Validar que el código no exista (excluyendo el producto actual)
      final codigoExists = await _productService.codigoExists(
        product.codigo,
        excludeId: id,
      );
      if (codigoExists) {
        _setError('El código de producto ya existe');
        return false;
      }
      
      // Validar el producto
      if (!product.isValid()) {
        _setError('Los datos del producto no son válidos');
        return false;
      }
      
      final updatedProduct = await _productService.update(id, product);
      
      // Actualizar en la lista
      final index = _products.indexWhere((p) => p.id == id);
      if (index != -1) {
        _products[index] = updatedProduct;
      }
      
      // Actualizar producto seleccionado si es el mismo
      if (_selectedProduct?.id == id) {
        _selectedProduct = updatedProduct;
      }
      
      notifyListeners();
      
      // Verificar y crear alerta de stock bajo si aplica
      _checkAndCreateLowStockAlert(updatedProduct);
      
      return true;
    } catch (e) {
      _setError('Error al actualizar producto: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Eliminar un producto
  Future<bool> deleteProduct(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _productService.delete(id);
      
      if (success) {
        _products.removeWhere((p) => p.id == id);
        
        // Limpiar producto seleccionado si es el eliminado
        if (_selectedProduct?.id == id) {
          _selectedProduct = null;
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setError('Error al eliminar producto: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Buscar productos
  Future<void> searchProducts(String query) async {
    debugPrint('[ProductProvider] searchProducts called with query: "$query"');
    _searchQuery = query;
    
    if (query.isEmpty) {
      // Si la búsqueda está vacía, recargar todos los productos
      debugPrint('[ProductProvider] Query empty, loading all products');
      // Solo cargar si no está cargando ya
      if (!_isLoadingProducts) {
        await loadProducts();
      }
      return;
    }
    
    if (_isLoading || _isLoadingProducts) {
      debugPrint('[ProductProvider] Already loading, skipping search...');
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _products = await _productService.search(query);
      debugPrint('[ProductProvider] Search completed: ${_products.length} products found');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[ProductProvider] Error searching products: $e');
      _errorMessage = 'Error al buscar productos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Filtrar por categoría
  Future<void> filterByCategory(String? categoria) async {
    debugPrint('[ProductProvider] filterByCategory called with category: "$categoria"');
    _selectedCategory = categoria;
    
    if (categoria == null || categoria.isEmpty) {
      // Si no hay categoría seleccionada, recargar todos
      debugPrint('[ProductProvider] Category empty, loading all products');
      // Solo cargar si no está cargando ya
      if (!_isLoadingProducts) {
        await loadProducts();
      }
      return;
    }
    
    if (_isLoading || _isLoadingProducts) {
      debugPrint('[ProductProvider] Already loading, skipping filter...');
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _products = await _productService.filterByCategory(categoria);
      debugPrint('[ProductProvider] Filter completed: ${_products.length} products found');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[ProductProvider] Error filtering products: $e');
      _errorMessage = 'Error al filtrar productos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Limpiar filtros
  void clearFilters() {
    debugPrint('[ProductProvider] clearFilters called');
    _searchQuery = '';
    _selectedCategory = null;
    // Solo cargar si no está cargando ya
    if (!_isLoadingProducts) {
      loadProducts();
    }
  }
  
  // Obtener productos con stock bajo
  Future<void> loadLowStockProducts() async {
    _setLoading(true);
    _clearError();
    
    try {
      _products = await _productService.getLowStockProducts();
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar productos con stock bajo: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Seleccionar un producto
  void selectProduct(Product? product) {
    _selectedProduct = product;
    notifyListeners();
  }
  
  // Verificar si un código existe
  Future<bool> checkCodigoExists(String codigo, {String? excludeId}) async {
    try {
      return await _productService.codigoExists(codigo, excludeId: excludeId);
    } catch (e) {
      return false;
    }
  }
  
  // Métodos privados
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      debugPrint('[ProductProvider] _setLoading: $loading');
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void _setError(String error) {
    if (_errorMessage != error) {
      debugPrint('[ProductProvider] _setError: $error');
      _errorMessage = error;
      notifyListeners();
    }
  }
  
  void _clearError() {
    if (_errorMessage != null) {
      debugPrint('[ProductProvider] _clearError');
      _errorMessage = null;
      // No notificar aquí, se notificará en el método que llama
    }
  }
  
  // Refrescar productos
  Future<void> refreshProducts() async {
    await loadProducts();
  }
  
  // Verificar y crear alerta de stock bajo para un producto
  void _checkAndCreateLowStockAlert(Product product) {
    // Solo crear alerta si el producto tiene stock bajo
    if (!product.tieneStockBajo) {
      return;
    }
    
    // Usar un callback o notificar al AlertProvider
    // Por ahora, solo loguear (la integración completa se hará cuando se cargue el AlertProvider)
    debugPrint('[ProductProvider] Producto con stock bajo detectado: ${product.nombre} (Stock: ${product.stockActual}, Mínimo: ${product.stockMinimo})');
    
    // Nota: La creación real de la alerta se hará desde el AlertProvider
    // cuando se detecte un cambio en los productos. Esto evita dependencias circulares.
  }
}

