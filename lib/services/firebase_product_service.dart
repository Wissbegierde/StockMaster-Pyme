import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import 'interfaces/product_service_interface.dart';

/// Servicio Firebase para productos usando Firestore
/// Implementa ProductServiceInterface para facilitar migración desde HTTP
class FirebaseProductService implements ProductServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'products';

  /// Convertir documento de Firestore a Product
  Product _documentToProduct(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      codigo: data['codigo'] ?? '',
      nombre: data['nombre'] ?? '',
      categoria: data['categoria'] ?? '',
      precio: (data['precio'] ?? 0.0).toDouble(),
      stockActual: data['stock_actual'] ?? data['stockActual'] ?? 0,
      stockMinimo: data['stock_minimo'] ?? data['stockMinimo'] ?? 0,
      proveedorId: data['proveedor_id'] ?? data['proveedorId'],
      fechaCreacion: data['fecha_creacion'] != null
          ? (data['fecha_creacion'] as Timestamp).toDate()
          : data['fechaCreacion'] != null
              ? (data['fechaCreacion'] as Timestamp).toDate()
              : DateTime.now(),
      fechaActualizacion: data['fecha_actualizacion'] != null
          ? (data['fecha_actualizacion'] as Timestamp).toDate()
          : data['fechaActualizacion'] != null
              ? (data['fechaActualizacion'] as Timestamp).toDate()
              : DateTime.now(),
    );
  }

  /// Convertir Product a Map para Firestore
  Map<String, dynamic> _productToMap(Product product, {bool includeId = false}) {
    final map = <String, dynamic>{
      'codigo': product.codigo,
      'nombre': product.nombre,
      'categoria': product.categoria,
      'precio': product.precio,
      'stock_actual': product.stockActual,
      'stock_minimo': product.stockMinimo,
      'proveedor_id': product.proveedorId,
      'fecha_creacion': Timestamp.fromDate(product.fechaCreacion),
      'fecha_actualizacion': Timestamp.fromDate(product.fechaActualizacion),
    };
    
    if (includeId) {
      map['id'] = product.id;
    }
    
    return map;
  }

  @override
  Future<List<Product>> getAll({int? page, int? limit}) async {
    try {
      Query query = _firestore.collection(_collectionName)
          .orderBy('fecha_creacion', descending: true);

      // Aplicar límite si se especifica
      // Nota: Firestore no soporta offset directamente, para paginación real
      // necesitarías usar startAfter con el último documento de la página anterior
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _documentToProduct(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener productos: ${e.toString()}');
    }
  }

  @override
  Future<Product?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return _documentToProduct(doc);
    } catch (e) {
      throw Exception('Error al obtener producto: ${e.toString()}');
    }
  }

  @override
  Future<Product> create(Product product) async {
    try {
      // Verificar que el código no exista
      final codigoAlreadyExists = await codigoExists(product.codigo);
      if (codigoAlreadyExists) {
        throw Exception('El código de producto ya existe');
      }

      final now = DateTime.now();
      final productWithDates = product.copyWith(
        fechaCreacion: now,
        fechaActualizacion: now,
      );

      final data = _productToMap(productWithDates);
      
      // Firestore genera el ID automáticamente
      final docRef = _firestore.collection(_collectionName).doc();
      
      await docRef.set(data);
      
      // Retornar el producto con el ID generado
      return productWithDates.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Error al crear producto: ${e.toString()}');
    }
  }

  @override
  Future<Product> update(String id, Product product) async {
    try {
      // Verificar que el código no exista (excluyendo el producto actual)
      final codigoAlreadyExists = await codigoExists(product.codigo, excludeId: id);
      if (codigoAlreadyExists) {
        throw Exception('El código de producto ya existe');
      }

      final updatedProduct = product.copyWith(
        fechaActualizacion: DateTime.now(),
      );

      final data = _productToMap(updatedProduct);
      
      await _firestore.collection(_collectionName).doc(id).update(data);
      
      return updatedProduct.copyWith(id: id);
    } catch (e) {
      throw Exception('Error al actualizar producto: ${e.toString()}');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      throw Exception('Error al eliminar producto: ${e.toString()}');
    }
  }

  @override
  Future<List<Product>> search(String query) async {
    try {
      final queryLower = query.toLowerCase();
      
      // Firestore no soporta búsqueda full-text nativa, así que obtenemos todos
      // y filtramos en memoria. Para producción con muchos productos,
      // considera usar Algolia, Elasticsearch o similar
      final allProducts = await getAll();
      
      return allProducts.where((product) {
        final nombreMatch = product.nombre.toLowerCase().contains(queryLower);
        final codigoMatch = product.codigo.toLowerCase().contains(queryLower);
        return nombreMatch || codigoMatch;
      }).toList();
    } catch (e) {
      throw Exception('Error al buscar productos: ${e.toString()}');
    }
  }

  @override
  Future<List<Product>> filterByCategory(String categoria) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('categoria', isEqualTo: categoria)
          .orderBy('fecha_creacion', descending: true)
          .get();

      return snapshot.docs.map((doc) => _documentToProduct(doc)).toList();
    } catch (e) {
      throw Exception('Error al filtrar productos: ${e.toString()}');
    }
  }

  @override
  Future<bool> codigoExists(String codigo, {String? excludeId}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('codigo', isEqualTo: codigo)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      // Si se especifica excludeId, verificar que no sea el mismo documento
      if (excludeId != null) {
        return snapshot.docs.any((doc) => doc.id != excludeId);
      }

      return true;
    } catch (e) {
      // Si hay error, asumimos que no existe para no bloquear el flujo
      return false;
    }
  }

  @override
  Future<List<Product>> getLowStockProducts() async {
    try {
      final allProducts = await getAll();
      
      return allProducts.where((product) => product.tieneStockBajo).toList();
    } catch (e) {
      throw Exception('Error al obtener productos con stock bajo: ${e.toString()}');
    }
  }

  /// Stream para escuchar cambios en tiempo real (bonus)
  /// Útil para actualizaciones automáticas sin recargar
  Stream<List<Product>> productsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('fecha_creacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => _documentToProduct(doc))
            .toList());
  }
}

