import '../models/movement.dart';
import 'interfaces/movement_service_interface.dart';

/// Servicio Mock para movimientos (desarrollo y testing)
/// Implementa MovementServiceInterface con datos de prueba
class MovementServiceMock implements MovementServiceInterface {
  final List<Movement> _movements = [];

  MovementServiceMock() {
    // Inicializar con algunos movimientos de ejemplo
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();
    _movements.addAll([
      Movement(
        id: 'mov-001',
        productId: 'prod-001',
        tipo: MovementType.entrada,
        cantidad: 50,
        motivo: 'Compra a proveedor XYZ',
        usuarioId: 'user-001',
        fecha: now.subtract(const Duration(days: 5)),
        productoNombre: 'Laptop Dell',
        usuarioNombre: 'Juan Pérez',
        fechaCreacion: now.subtract(const Duration(days: 5)),
        fechaActualizacion: now.subtract(const Duration(days: 5)),
      ),
      Movement(
        id: 'mov-002',
        productId: 'prod-001',
        tipo: MovementType.salida,
        cantidad: 10,
        motivo: 'Venta a cliente ABC',
        usuarioId: 'user-001',
        fecha: now.subtract(const Duration(days: 3)),
        productoNombre: 'Laptop Dell',
        usuarioNombre: 'Juan Pérez',
        fechaCreacion: now.subtract(const Duration(days: 3)),
        fechaActualizacion: now.subtract(const Duration(days: 3)),
      ),
      Movement(
        id: 'mov-003',
        productId: 'prod-002',
        tipo: MovementType.entrada,
        cantidad: 25,
        motivo: 'Entrada por inventario físico',
        usuarioId: 'user-002',
        fecha: now.subtract(const Duration(days: 1)),
        productoNombre: 'Mouse Inalámbrico',
        usuarioNombre: 'María García',
        fechaCreacion: now.subtract(const Duration(days: 1)),
        fechaActualizacion: now.subtract(const Duration(days: 1)),
      ),
      Movement(
        id: 'mov-004',
        productId: 'prod-001',
        tipo: MovementType.entrada,
        cantidad: 30,
        motivo: 'Devolución de cliente',
        usuarioId: 'user-001',
        fecha: now.subtract(const Duration(hours: 12)),
        productoNombre: 'Laptop Dell',
        usuarioNombre: 'Juan Pérez',
        fechaCreacion: now.subtract(const Duration(hours: 12)),
        fechaActualizacion: now.subtract(const Duration(hours: 12)),
      ),
    ]);
  }

  @override
  Future<List<Movement>> getAll({int? page, int? limit}) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simular latencia
    
    var movements = List<Movement>.from(_movements);
    
    // Ordenar por fecha (más reciente primero)
    movements.sort((a, b) => b.fecha.compareTo(a.fecha));
    
    // Paginación
    if (page != null && limit != null) {
      final start = page * limit;
      final end = start + limit;
      if (start < movements.length) {
        movements = movements.sublist(
          start,
          end > movements.length ? movements.length : end,
        );
      } else {
        movements = [];
      }
    }
    
    return movements;
  }

  @override
  Future<Movement?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _movements.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Movement> create(Movement movement) async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simular latencia
    
    // Generar ID si no tiene
    final newMovement = movement.id.isEmpty
        ? movement.copyWith(
            id: 'mov-${DateTime.now().millisecondsSinceEpoch}',
            fechaCreacion: DateTime.now(),
            fechaActualizacion: DateTime.now(),
          )
        : movement.copyWith(
            fechaCreacion: movement.fechaCreacion ?? DateTime.now(),
            fechaActualizacion: DateTime.now(),
          );
    
    _movements.add(newMovement);
    
    // Simular actualización de stock (en producción esto lo haría el backend)
    // Por ahora solo retornamos el movimiento creado
    
    return newMovement;
  }

  @override
  Future<List<Movement>> getByProduct(String productId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _movements
        .where((m) => m.productId == productId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Future<List<Movement>> getByDateRange(DateTime start, DateTime end) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _movements
        .where((m) => m.fecha.isAfter(start.subtract(const Duration(days: 1))) && 
                     m.fecha.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Future<List<Movement>> getByProductAndDateRange(
    String productId,
    DateTime start,
    DateTime end,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _movements
        .where((m) => m.productId == productId &&
                     m.fecha.isAfter(start.subtract(const Duration(days: 1))) && 
                     m.fecha.isBefore(end.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Future<List<Movement>> getRecent(int limit) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final movements = List<Movement>.from(_movements);
    movements.sort((a, b) => b.fecha.compareTo(a.fecha));
    return movements.take(limit).toList();
  }

  @override
  Future<List<Movement>> getByType(MovementType type) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _movements
        .where((m) => m.tipo == type)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  @override
  Future<List<Movement>> getByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _movements
        .where((m) => m.usuarioId == userId)
        .toList()
      ..sort((a, b) => b.fecha.compareTo(a.fecha));
  }
}

