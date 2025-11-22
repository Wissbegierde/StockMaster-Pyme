import 'package:flutter/foundation.dart';
import '../models/inventory_value_history.dart';
import '../providers/product_provider.dart';
import '../providers/movement_provider.dart';
import '../models/movement.dart';

class InventoryValueHistoryProvider with ChangeNotifier {
  List<InventoryValuePoint> _historyData = [];
  bool _isLoading = false;
  String? _errorMessage;
  TimePeriod _selectedPeriod = TimePeriod.week;

  List<InventoryValuePoint> get historyData => _historyData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TimePeriod get selectedPeriod => _selectedPeriod;

  /// Cargar datos históricos del valor del inventario
  Future<void> loadHistoryData({
    required ProductProvider productProvider,
    required MovementProvider movementProvider,
    TimePeriod? period,
  }) async {
    _selectedPeriod = period ?? _selectedPeriod;
    _setLoading(true);
    _clearError();

    try {
      _historyData = await _calculateHistoryData(
        productProvider: productProvider,
        movementProvider: movementProvider,
        period: _selectedPeriod,
      );
      notifyListeners();
    } catch (e) {
      _setError('Error al cargar datos históricos: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Calcular datos históricos basándose en movimientos y productos
  Future<List<InventoryValuePoint>> _calculateHistoryData({
    required ProductProvider productProvider,
    required MovementProvider movementProvider,
    required TimePeriod period,
  }) async {
    final now = DateTime.now();
    final List<InventoryValuePoint> points = [];

    // Determinar el rango de fechas según el período
    DateTime startDate;
    Duration stepDuration;
    int numberOfPoints;

    switch (period) {
      case TimePeriod.day:
        startDate = DateTime(now.year, now.month, now.day);
        stepDuration = const Duration(hours: 1);
        numberOfPoints = 24;
        break;
      case TimePeriod.week:
        startDate = now.subtract(const Duration(days: 7));
        stepDuration = const Duration(days: 1);
        numberOfPoints = 7;
        break;
      case TimePeriod.month:
        startDate = DateTime(now.year, now.month - 1, now.day);
        stepDuration = const Duration(days: 1);
        numberOfPoints = 30;
        break;
      case TimePeriod.year:
        startDate = DateTime(now.year - 1, now.month, now.day);
        stepDuration = const Duration(days: 30);
        numberOfPoints = 12;
        break;
    }

    // Obtener productos y movimientos
    final products = productProvider.products;
    final movements = movementProvider.movements;

    // Calcular el valor del inventario para cada punto de tiempo
    for (int i = 0; i < numberOfPoints; i++) {
      final currentDate = startDate.add(stepDuration * i);
      
      // Calcular el stock de cada producto hasta esta fecha
      double totalValue = 0.0;
      
      for (final product in products) {
        // Obtener el stock inicial del producto
        int currentStock = product.stockActual;
        
        // Ajustar el stock basándose en los movimientos hasta esta fecha
        for (final movement in movements) {
          if (movement.productId == product.id && movement.fecha.isBefore(currentDate)) {
            switch (movement.tipo) {
              case MovementType.entrada:
                currentStock += movement.cantidad;
                break;
              case MovementType.salida:
                currentStock -= movement.cantidad;
                break;
            }
          }
        }
        
        // Asegurar que el stock no sea negativo
        if (currentStock < 0) currentStock = 0;
        
        // Calcular el valor de este producto
        totalValue += currentStock * product.precio;
      }
      
      points.add(InventoryValuePoint(
        date: currentDate,
        value: totalValue,
      ));
    }

    return points;
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}

