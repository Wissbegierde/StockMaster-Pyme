import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../services/supplier_service.dart';
import '../services/supplier_service_mock.dart';
import '../services/firebase_supplier_service.dart';
import '../services/interfaces/supplier_service_interface.dart';
import '../config/app_config.dart';

class SupplierProvider with ChangeNotifier {
  // Factory pattern: crear el servicio según la configuración
  final SupplierServiceInterface _supplierService = _createSupplierService();
  
  /// Factory method para crear el servicio correcto según la configuración
  static SupplierServiceInterface _createSupplierService() {
    switch (AppConfig.backendType) {
      case BackendType.mock:
        return SupplierServiceMock();
      case BackendType.http:
        return SupplierService();
      case BackendType.firebase:
        return FirebaseSupplierService();
    }
  }
  
  List<Supplier> _suppliers = [];
  Supplier? _selectedSupplier;
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  bool _isLoadingSuppliers = false; // Flag para evitar llamadas simultáneas
  
  // Getters
  List<Supplier> get suppliers => _suppliers;
  Supplier? get selectedSupplier => _selectedSupplier;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  
  // Getters calculados
  int get totalSuppliers => _suppliers.length;
  
  List<Supplier> get filteredSuppliers {
    var filtered = List<Supplier>.from(_suppliers);
    
    // Filtrar por búsqueda (si hay query, se hace búsqueda en el servicio)
    // Si no hay query, mostrar todos
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((supplier) {
        return supplier.nombre.toLowerCase().contains(query) ||
               supplier.contacto.toLowerCase().contains(query) ||
               (supplier.email != null && supplier.email!.toLowerCase().contains(query));
      }).toList();
    }
    
    return filtered;
  }
  
  // Cargar todos los proveedores
  Future<void> loadSuppliers({int? page, int? limit}) async {
    debugPrint('[SupplierProvider] loadSuppliers called - _isLoadingSuppliers: $_isLoadingSuppliers, _isLoading: $_isLoading');
    
    // Evitar llamadas simultáneas
    if (_isLoadingSuppliers) {
      debugPrint('[SupplierProvider] Already loading suppliers, skipping...');
      return;
    }
    
    _isLoadingSuppliers = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    debugPrint('[SupplierProvider] Loading started, notifyListeners called');
    
    try {
      _suppliers = await _supplierService.getAll(page: page, limit: limit);
      debugPrint('[SupplierProvider] Suppliers loaded: ${_suppliers.length}');
    } catch (e) {
      debugPrint('[SupplierProvider] Error loading suppliers: $e');
      _errorMessage = 'Error al cargar proveedores: ${e.toString()}';
    } finally {
      _isLoading = false;
      _isLoadingSuppliers = false;
      notifyListeners();
      debugPrint('[SupplierProvider] Loading completed, notifyListeners called');
    }
  }
  
  // Cargar un proveedor por ID
  Future<void> loadSupplierById(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      _selectedSupplier = await _supplierService.getById(id);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar proveedor: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Crear un nuevo proveedor
  Future<bool> createSupplier(Supplier supplier) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Validar el proveedor
      if (!supplier.isValid()) {
        final error = supplier.getValidationError();
        _setError(error ?? 'Los datos del proveedor no son válidos');
        return false;
      }
      
      final newSupplier = await _supplierService.create(supplier);
      _suppliers.add(newSupplier);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear proveedor: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Actualizar un proveedor
  Future<bool> updateSupplier(String id, Supplier supplier) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Validar el proveedor
      if (!supplier.isValid(requireId: true)) {
        final error = supplier.getValidationError(requireId: true);
        _setError(error ?? 'Los datos del proveedor no son válidos');
        return false;
      }
      
      final updatedSupplier = await _supplierService.update(id, supplier);
      
      // Actualizar en la lista
      final index = _suppliers.indexWhere((s) => s.id == id);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
      }
      
      // Actualizar proveedor seleccionado si es el mismo
      if (_selectedSupplier?.id == id) {
        _selectedSupplier = updatedSupplier;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar proveedor: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Eliminar un proveedor
  Future<bool> deleteSupplier(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      final success = await _supplierService.delete(id);
      
      if (success) {
        _suppliers.removeWhere((s) => s.id == id);
        
        // Limpiar proveedor seleccionado si es el eliminado
        if (_selectedSupplier?.id == id) {
          _selectedSupplier = null;
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      _setError('Error al eliminar proveedor: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Buscar proveedores
  Future<void> searchSuppliers(String query) async {
    debugPrint('[SupplierProvider] searchSuppliers called with query: "$query"');
    _searchQuery = query;
    
    if (query.isEmpty) {
      // Si la búsqueda está vacía, recargar todos los proveedores
      debugPrint('[SupplierProvider] Query empty, loading all suppliers');
      // Solo cargar si no está cargando ya
      if (!_isLoadingSuppliers) {
        await loadSuppliers();
      }
      return;
    }
    
    if (_isLoading || _isLoadingSuppliers) {
      debugPrint('[SupplierProvider] Already loading, skipping search...');
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _suppliers = await _supplierService.search(query);
      debugPrint('[SupplierProvider] Search completed: ${_suppliers.length} suppliers found');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[SupplierProvider] Error searching suppliers: $e');
      _errorMessage = 'Error al buscar proveedores: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Limpiar filtros
  void clearFilters() {
    debugPrint('[SupplierProvider] clearFilters called');
    _searchQuery = '';
    // Solo cargar si no está cargando ya
    if (!_isLoadingSuppliers) {
      loadSuppliers();
    }
  }
  
  // Obtener productos de un proveedor
  Future<List<String>> getProductsBySupplier(String supplierId) async {
    try {
      return await _supplierService.getProductsBySupplier(supplierId);
    } catch (e) {
      debugPrint('[SupplierProvider] Error getting products by supplier: $e');
      return [];
    }
  }
  
  // Seleccionar un proveedor
  void selectSupplier(Supplier? supplier) {
    _selectedSupplier = supplier;
    notifyListeners();
  }
  
  // Métodos privados
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      debugPrint('[SupplierProvider] _setLoading: $loading');
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void _setError(String error) {
    if (_errorMessage != error) {
      debugPrint('[SupplierProvider] _setError: $error');
      _errorMessage = error;
      notifyListeners();
    }
  }
  
  void _clearError() {
    if (_errorMessage != null) {
      debugPrint('[SupplierProvider] _clearError');
      _errorMessage = null;
      // No notificar aquí, se notificará en el método que llama
    }
  }
  
  // Refrescar proveedores
  Future<void> refreshSuppliers() async {
    await loadSuppliers();
  }
}

