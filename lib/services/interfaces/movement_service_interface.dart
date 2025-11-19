import '../../models/movement.dart';

/// Interfaz abstracta para el servicio de movimientos
/// Permite cambiar fácilmente entre HTTP y Firebase sin modificar el código que lo usa
abstract class MovementServiceInterface {
  /// Obtener todos los movimientos
  /// [page] y [limit] para paginación (opcional)
  Future<List<Movement>> getAll({int? page, int? limit});

  /// Obtener un movimiento por ID
  Future<Movement?> getById(String id);

  /// Crear un nuevo movimiento
  /// Actualiza automáticamente el stock del producto
  /// Retorna el movimiento creado
  Future<Movement> create(Movement movement);

  /// Obtener movimientos de un producto específico
  Future<List<Movement>> getByProduct(String productId);

  /// Obtener movimientos por rango de fechas
  Future<List<Movement>> getByDateRange(DateTime start, DateTime end);

  /// Obtener movimientos de un producto en un rango de fechas
  Future<List<Movement>> getByProductAndDateRange(
    String productId,
    DateTime start,
    DateTime end,
  );

  /// Obtener movimientos recientes (para dashboard)
  /// [limit] es el número máximo de movimientos a retornar
  Future<List<Movement>> getRecent(int limit);

  /// Obtener movimientos por tipo
  Future<List<Movement>> getByType(MovementType type);

  /// Obtener movimientos por usuario
  Future<List<Movement>> getByUser(String userId);
}

