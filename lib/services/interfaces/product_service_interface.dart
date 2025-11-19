import '../../models/product.dart';

/// Interfaz abstracta para el servicio de productos
/// Permite cambiar fácilmente entre HTTP y Firebase sin modificar el código que lo usa
abstract class ProductServiceInterface {
  /// Obtener todos los productos
  /// [page] y [limit] para paginación (opcional)
  Future<List<Product>> getAll({int? page, int? limit});

  /// Obtener un producto por ID
  Future<Product?> getById(String id);

  /// Crear un nuevo producto
  Future<Product> create(Product product);

  /// Actualizar un producto existente
  Future<Product> update(String id, Product product);

  /// Eliminar un producto
  Future<bool> delete(String id);

  /// Buscar productos por nombre o código
  Future<List<Product>> search(String query);

  /// Filtrar productos por categoría
  Future<List<Product>> filterByCategory(String categoria);

  /// Verificar si un código de producto ya existe
  Future<bool> codigoExists(String codigo, {String? excludeId});

  /// Obtener productos con stock bajo
  Future<List<Product>> getLowStockProducts();
}

