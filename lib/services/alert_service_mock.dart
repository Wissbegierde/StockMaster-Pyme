import 'dart:async';
import '../models/alert.dart';
import 'interfaces/alert_service_interface.dart';

class AlertServiceMock implements AlertServiceInterface {
  final List<Alert> _alerts = [];
  int _nextId = 1;

  AlertServiceMock() {
    // Inicializar con datos de ejemplo
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();
    _alerts.addAll([
      Alert(
        id: 'alert-${_nextId++}',
        tipo: AlertType.stockBajo,
        titulo: 'Stock Bajo - Producto A',
        mensaje: 'El producto "Producto A" tiene stock bajo (5 unidades). Stock mínimo: 10',
        productoId: 'prod-1',
        leida: false,
        fechaCreacion: now.subtract(const Duration(hours: 2)),
      ),
      Alert(
        id: 'alert-${_nextId++}',
        tipo: AlertType.stockBajo,
        titulo: 'Stock Bajo - Producto B',
        mensaje: 'El producto "Producto B" tiene stock bajo (3 unidades). Stock mínimo: 8',
        productoId: 'prod-2',
        leida: true,
        fechaCreacion: now.subtract(const Duration(days: 1)),
        fechaLectura: now.subtract(const Duration(hours: 12)),
      ),
      Alert(
        id: 'alert-${_nextId++}',
        tipo: AlertType.movimientoImportante,
        titulo: 'Movimiento Importante',
        mensaje: 'Se registró una salida grande de 50 unidades del producto "Producto C"',
        productoId: 'prod-3',
        leida: false,
        fechaCreacion: now.subtract(const Duration(hours: 5)),
      ),
      Alert(
        id: 'alert-${_nextId++}',
        tipo: AlertType.productoAgotado,
        titulo: 'Producto Agotado',
        mensaje: 'El producto "Producto D" se ha agotado completamente',
        productoId: 'prod-4',
        leida: false,
        fechaCreacion: now.subtract(const Duration(minutes: 30)),
      ),
    ]);
  }

  @override
  Future<List<Alert>> getAll() async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Alert>.from(_alerts);
  }

  @override
  Future<Alert?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _alerts.firstWhere((alert) => alert.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Alert>> getUnread() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _alerts.where((alert) => !alert.leida).toList();
  }

  @override
  Future<Alert> create(Alert alert) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Generar ID si no tiene
    final newAlert = alert.id.isEmpty
        ? alert.copyWith(id: 'alert-${_nextId++}')
        : alert;
    
    _alerts.insert(0, newAlert); // Agregar al inicio
    return newAlert;
  }

  @override
  Future<bool> markAsRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index == -1) {
      return false;
    }
    
    final alert = _alerts[index];
    _alerts[index] = alert.copyWith(
      leida: true,
      fechaLectura: DateTime.now(),
    );
    
    return true;
  }

  @override
  Future<bool> markAllAsRead() async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    final now = DateTime.now();
    for (int i = 0; i < _alerts.length; i++) {
      if (!_alerts[i].leida) {
        _alerts[i] = _alerts[i].copyWith(
          leida: true,
          fechaLectura: now,
        );
      }
    }
    
    return true;
  }

  @override
  Future<bool> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index == -1) {
      return false;
    }
    
    _alerts.removeAt(index);
    return true;
  }
}

