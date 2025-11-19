import '../../models/supplier.dart';

/// Interfaz abstracta para el servicio de proveedores
/// Permite cambiar fácilmente entre HTTP y Firebase sin modificar el código que lo usa
abstract class SupplierServiceInterface {
  /// Obtener todos los proveedores
  /// [page] y [limit] para paginación (opcional)
  Future<List<Supplier>> getAll({int? page, int? limit});

  /// Obtener un proveedor por ID
  Future<Supplier?> getById(String id);

  /// Crear un nuevo proveedor
  Future<Supplier> create(Supplier supplier);

  /// Actualizar un proveedor existente
  Future<Supplier> update(String id, Supplier supplier);

  /// Eliminar un proveedor
  Future<bool> delete(String id);

  /// Buscar proveedores por nombre, contacto o email
  Future<List<Supplier>> search(String query);

  /// Obtener productos de un proveedor (opcional, para estadísticas)
  /// Retorna una lista de IDs de productos asociados al proveedor
  Future<List<String>> getProductsBySupplier(String supplierId);
}

