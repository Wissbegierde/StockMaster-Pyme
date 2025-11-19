import 'package:flutter/foundation.dart';
import '../models/movement.dart';
import '../services/movement_service.dart';
import '../services/movement_service_mock.dart';
import '../services/firebase_movement_service.dart';
import '../services/interfaces/movement_service_interface.dart';
import '../config/app_config.dart';
import 'product_provider.dart';

class MovementProvider with ChangeNotifier {
  // Factory pattern: crear el servicio según la configuración
  final MovementServiceInterface _movementService = _createMovementService();
  
  /// Factory method para crear el servicio correcto según la configuración
  static MovementServiceInterface _createMovementService() {
    switch (AppConfig.backendType) {
      case BackendType.mock:
        return MovementServiceMock();
      case BackendType.http:
        return MovementService();
      case BackendType.firebase:
        return FirebaseMovementService();
    }
  }
  
  List<Movement> _movements = [];
  Movement? _selectedMovement;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLoadingMovements = false; // Flag para evitar llamadas simultáneas
  
  // Filtros activos
  String? _selectedProductId;
  DateTime? _startDate;
  DateTime? _endDate;
  MovementType? _selectedType;
  String? _selectedUserId;
  String _searchQuery = ''; // Query de búsqueda
  
  // Getters
  List<Movement> get movements => _movements;
  Movement? get selectedMovement => _selectedMovement;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedProductId => _selectedProductId;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  MovementType? get selectedType => _selectedType;
  String? get selectedUserId => _selectedUserId;
  String get searchQuery => _searchQuery;
  
  // Getters calculados
  int get totalMovements => _movements.length;
  
  // Estadísticas de movimientos
  int get totalEntradas {
    return _movements
        .where((m) => m.tipo == MovementType.entrada)
        .fold(0, (sum, m) => sum + m.cantidad);
  }
  
  int get totalSalidas {
    return _movements
        .where((m) => m.tipo == MovementType.salida)
        .fold(0, (sum, m) => sum + m.cantidad);
  }
  
  int get balanceNeto => totalEntradas - totalSalidas;
  
  int get cantidadEntradas => _movements.where((m) => m.tipo == MovementType.entrada).length;
  int get cantidadSalidas => _movements.where((m) => m.tipo == MovementType.salida).length;
  
  /// Obtiene el número de movimientos del día actual
  int get movementsToday {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    return _movements.where((movement) {
      final movementDate = movement.fecha;
      return movementDate.isAfter(todayStart) && movementDate.isBefore(todayEnd);
    }).length;
  }
  
  List<Movement> get filteredMovements {
    var filtered = List<Movement>.from(_movements);
    
    // Aplicar filtro por tipo si está seleccionado
    if (_selectedType != null) {
      filtered = filtered.where((movement) => movement.tipo == _selectedType).toList();
    }
    
    // Aplicar búsqueda si hay query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((movement) {
        // Buscar en nombre del producto
        final productoNombre = (movement.productoNombre ?? '').toLowerCase();
        // Buscar en motivo
        final motivo = movement.motivo.toLowerCase();
        // Buscar en nombre del usuario
        final usuarioNombre = (movement.usuarioNombre ?? '').toLowerCase();
        
        return productoNombre.contains(query) ||
               motivo.contains(query) ||
               usuarioNombre.contains(query);
      }).toList();
    }
    
    return filtered;
  }
  
  // Método para actualizar la búsqueda
  void searchMovements(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  // Cargar todos los movimientos
  Future<void> loadMovements({int? page, int? limit}) async {
    debugPrint('[MovementProvider] loadMovements called - _isLoadingMovements: $_isLoadingMovements');
    
    // Evitar llamadas simultáneas
    if (_isLoadingMovements) {
      debugPrint('[MovementProvider] Already loading movements, skipping...');
      return;
    }
    
    _isLoadingMovements = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _movements = await _movementService.getAll(page: page, limit: limit);
      debugPrint('[MovementProvider] Movements loaded: ${_movements.length}');
    } catch (e) {
      debugPrint('[MovementProvider] Error loading movements: $e');
      _errorMessage = 'Error al cargar movimientos: ${e.toString()}';
    } finally {
      _isLoading = false;
      _isLoadingMovements = false;
      notifyListeners();
    }
  }
  
  // Cargar un movimiento por ID
  Future<void> loadMovementById(String id) async {
    _setLoading(true);
    _clearError();
    
    try {
      _selectedMovement = await _movementService.getById(id);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar movimiento: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Crear un nuevo movimiento
  // [productProvider] es opcional, se usa para actualizar el stock después de crear
  Future<bool> createMovement(
    Movement movement, {
    ProductProvider? productProvider,
  }) async {
    _setLoading(true);
    _clearError();
    
    try {
      // Validar el movimiento
      if (!movement.isValid()) {
        final error = movement.getValidationError();
        _setError(error ?? 'Los datos del movimiento no son válidos');
        return false;
      }
      
      // Validar que el producto existe y está activo
      if (productProvider != null) {
        final productIndex = productProvider.products.indexWhere(
          (p) => p.id == movement.productId,
        );
        
        if (productIndex == -1) {
          _setError(
            'El producto seleccionado no existe o ha sido eliminado. Por favor, recarga la lista de productos.',
          );
          return false;
        }
        
        final product = productProvider.products[productIndex];
        
        // Validar stock suficiente para salidas
        if (movement.tipo == MovementType.salida) {
          if (movement.cantidad > product.stockActual) {
            _setError(
              'Stock insuficiente. Disponible: ${product.stockActual}, Solicitado: ${movement.cantidad}.\n¿Deseas registrar una entrada primero?',
            );
            return false;
          }
          
          // Validar que no resulte en stock negativo
          final nuevoStock = product.stockActual - movement.cantidad;
          if (nuevoStock < 0) {
            _setError(
              'Esta salida resultaría en stock negativo. Stock actual: ${product.stockActual}, Cantidad: ${movement.cantidad}.\nPor favor, ajusta la cantidad.',
            );
            return false;
          }
        }
      } else {
        // Si no hay productProvider, advertir pero permitir (el backend debería validar)
        debugPrint('[MovementProvider] Warning: productProvider is null, stock validation skipped');
      }
      
      // Crear el movimiento
      final newMovement = await _movementService.create(movement);
      
      // Agregar a la lista
      _movements.insert(0, newMovement); // Insertar al inicio (más reciente primero)
      
      // Actualizar stock del producto directamente
      if (productProvider != null) {
        debugPrint('[MovementProvider] Actualizando stock del producto ${movement.productId}...');
        // Buscar el producto en la lista
        final productIndex = productProvider.products.indexWhere(
          (p) => p.id == movement.productId,
        );
        
        if (productIndex != -1) {
          final product = productProvider.products[productIndex];
          int nuevoStock;
          
          switch (movement.tipo) {
            case MovementType.entrada:
              nuevoStock = product.stockActual + movement.cantidad;
              debugPrint('[MovementProvider] Entrada: ${product.stockActual} + ${movement.cantidad} = $nuevoStock');
              break;
            case MovementType.salida:
              nuevoStock = product.stockActual - movement.cantidad;
              debugPrint('[MovementProvider] Salida: ${product.stockActual} - ${movement.cantidad} = $nuevoStock');
              break;
          }
          
          // Actualizar el producto con el nuevo stock
          final updatedProduct = product.copyWith(
            stockActual: nuevoStock,
            fechaActualizacion: DateTime.now(),
          );
          
          debugPrint('[MovementProvider] Actualizando producto con nuevo stock: $nuevoStock');
          // Actualizar en el servicio (para persistencia en mock)
          final updateSuccess = await productProvider.updateProduct(product.id, updatedProduct);
          debugPrint('[MovementProvider] Producto actualizado: $updateSuccess');
        } else {
          // Si no está en la lista, recargar todos los productos
          debugPrint('[MovementProvider] Producto no encontrado en lista, recargando...');
          await productProvider.loadProducts();
        }
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[MovementProvider] Error creating movement: $e');
      _setError('Error al crear movimiento: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Filtrar por producto
  Future<void> filterByProduct(String? productId) async {
    debugPrint('[MovementProvider] filterByProduct called with productId: "$productId"');
    _selectedProductId = productId;
    
    if (productId == null || productId.isEmpty) {
      // Si no hay producto seleccionado, recargar todos
      debugPrint('[MovementProvider] ProductId empty, loading all movements');
      if (!_isLoadingMovements) {
        await loadMovements();
      }
      return;
    }
    
    if (_isLoading || _isLoadingMovements) {
      debugPrint('[MovementProvider] Already loading, skipping filter...');
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _movements = await _movementService.getByProduct(productId);
      debugPrint('[MovementProvider] Filter by product completed: ${_movements.length} movements found');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[MovementProvider] Error filtering movements: $e');
      _errorMessage = 'Error al filtrar movimientos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Filtrar por rango de fechas
  Future<void> filterByDateRange(DateTime? start, DateTime? end) async {
    debugPrint('[MovementProvider] filterByDateRange called');
    _startDate = start;
    _endDate = end;
    
    if (start == null || end == null) {
      // Si no hay fechas, recargar todos
      debugPrint('[MovementProvider] Dates empty, loading all movements');
      if (!_isLoadingMovements) {
        await loadMovements();
      }
      return;
    }
    
    if (_isLoading || _isLoadingMovements) {
      debugPrint('[MovementProvider] Already loading, skipping filter...');
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _movements = await _movementService.getByDateRange(start, end);
      debugPrint('[MovementProvider] Filter by date range completed: ${_movements.length} movements found');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[MovementProvider] Error filtering movements: $e');
      _errorMessage = 'Error al filtrar movimientos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Filtrar por tipo
  Future<void> filterByType(MovementType? type) async {
    debugPrint('[MovementProvider] filterByType called with type: $type');
    _selectedType = type;
    
    // Si se selecciona "Todos" (null), recargar todos los movimientos
    if (type == null && !_isLoadingMovements) {
      debugPrint('[MovementProvider] Type is null, loading all movements');
      await loadMovements();
      return;
    }
    
    // Notificar cambios para que filteredMovements se actualice
    // El filtrado se hace en el getter filteredMovements (filtrado en memoria)
    // Esto es más rápido y no requiere llamadas adicionales al servicio
    notifyListeners();
  }
  
  // Filtrar por usuario
  Future<void> filterByUser(String? userId) async {
    debugPrint('[MovementProvider] filterByUser called with userId: "$userId"');
    _selectedUserId = userId;
    
    if (userId == null || userId.isEmpty) {
      // Si no hay usuario seleccionado, recargar todos
      debugPrint('[MovementProvider] UserId empty, loading all movements');
      if (!_isLoadingMovements) {
        await loadMovements();
      }
      return;
    }
    
    if (_isLoading || _isLoadingMovements) {
      debugPrint('[MovementProvider] Already loading, skipping filter...');
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _movements = await _movementService.getByUser(userId);
      debugPrint('[MovementProvider] Filter by user completed: ${_movements.length} movements found');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[MovementProvider] Error filtering movements: $e');
      _errorMessage = 'Error al filtrar movimientos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Filtrar por producto y rango de fechas
  Future<void> filterByProductAndDateRange(
    String? productId,
    DateTime? start,
    DateTime? end,
  ) async {
    debugPrint('[MovementProvider] filterByProductAndDateRange called');
    _selectedProductId = productId;
    _startDate = start;
    _endDate = end;
    
    if (productId == null || productId.isEmpty || start == null || end == null) {
      // Si faltan parámetros, recargar todos
      debugPrint('[MovementProvider] Parameters incomplete, loading all movements');
      if (!_isLoadingMovements) {
        await loadMovements();
      }
      return;
    }
    
    if (_isLoading || _isLoadingMovements) {
      debugPrint('[MovementProvider] Already loading, skipping filter...');
      return;
    }
    
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      _movements = await _movementService.getByProductAndDateRange(productId, start, end);
      debugPrint('[MovementProvider] Filter by product and date range completed: ${_movements.length} movements found');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[MovementProvider] Error filtering movements: $e');
      _errorMessage = 'Error al filtrar movimientos: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Obtener movimientos recientes
  Future<void> loadRecentMovements(int limit) async {
    _setLoading(true);
    _clearError();
    
    try {
      _movements = await _movementService.getRecent(limit);
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar movimientos recientes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
  
  // Limpiar todos los filtros
  void clearFilters() {
    debugPrint('[MovementProvider] clearFilters called');
    _selectedProductId = null;
    _startDate = null;
    _endDate = null;
    _selectedType = null;
    _selectedUserId = null;
    _searchQuery = '';
    
    // Recargar todos los movimientos
    if (!_isLoadingMovements) {
      loadMovements();
    }
  }
  
  // Seleccionar un movimiento
  void selectMovement(Movement? movement) {
    _selectedMovement = movement;
    notifyListeners();
  }
  
  // Refrescar movimientos
  Future<void> refreshMovements() async {
    await loadMovements();
  }
  
  // Métodos privados
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      debugPrint('[MovementProvider] _setLoading: $loading');
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void _setError(String error) {
    if (_errorMessage != error) {
      debugPrint('[MovementProvider] _setError: $error');
      _errorMessage = error;
      notifyListeners();
    }
  }
  
  void _clearError() {
    if (_errorMessage != null) {
      debugPrint('[MovementProvider] _clearError');
      _errorMessage = null;
      // No notificar aquí, se notificará en el método que llama
    }
  }
}

