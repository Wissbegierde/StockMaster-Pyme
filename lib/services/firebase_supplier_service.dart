import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/supplier.dart';
import 'interfaces/supplier_service_interface.dart';

/// Servicio Firebase para proveedores usando Firestore
/// Implementa SupplierServiceInterface para facilitar migración desde HTTP
class FirebaseSupplierService implements SupplierServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'suppliers';
  final String _productsCollectionName = 'products';

  /// Convertir documento de Firestore a Supplier
  Supplier _documentToSupplier(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Supplier(
      id: doc.id,
      nombre: data['nombre'] ?? '',
      contacto: data['contacto'] ?? '',
      telefono: data['telefono'] ?? '',
      email: data['email'],
      direccion: data['direccion'],
      fechaCreacion: data['fecha_creacion'] != null
          ? (data['fecha_creacion'] as Timestamp).toDate()
          : data['fechaCreacion'] != null
              ? (data['fechaCreacion'] as Timestamp).toDate()
              : data['created_at'] != null
                  ? (data['created_at'] as Timestamp).toDate()
                  : DateTime.now(),
      fechaActualizacion: data['fecha_actualizacion'] != null
          ? (data['fecha_actualizacion'] as Timestamp).toDate()
          : data['fechaActualizacion'] != null
              ? (data['fechaActualizacion'] as Timestamp).toDate()
              : data['updated_at'] != null
                  ? (data['updated_at'] as Timestamp).toDate()
                  : DateTime.now(),
    );
  }

  /// Convertir Supplier a Map para Firestore
  Map<String, dynamic> _supplierToMap(Supplier supplier, {bool includeId = false}) {
    final map = <String, dynamic>{
      'nombre': supplier.nombre,
      'contacto': supplier.contacto,
      'telefono': supplier.telefono,
      'fecha_creacion': Timestamp.fromDate(supplier.fechaCreacion),
      'fecha_actualizacion': Timestamp.fromDate(supplier.fechaActualizacion),
    };
    
    if (supplier.email != null) {
      map['email'] = supplier.email;
    }
    if (supplier.direccion != null) {
      map['direccion'] = supplier.direccion;
    }
    
    if (includeId) {
      map['id'] = supplier.id;
    }
    
    return map;
  }

  @override
  Future<List<Supplier>> getAll({int? page, int? limit}) async {
    try {
      Query query = _firestore.collection(_collectionName)
          .orderBy('nombre', descending: false);

      // Aplicar límite si se especifica
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _documentToSupplier(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener proveedores: ${e.toString()}');
    }
  }

  @override
  Future<Supplier?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return _documentToSupplier(doc);
    } catch (e) {
      throw Exception('Error al obtener proveedor: ${e.toString()}');
    }
  }

  @override
  Future<Supplier> create(Supplier supplier) async {
    try {
      // Validar que el proveedor sea válido
      if (!supplier.isValid()) {
        final error = supplier.getValidationError();
        throw Exception(error ?? 'Datos del proveedor inválidos');
      }

      final now = DateTime.now();
      final supplierData = _supplierToMap(
        supplier.copyWith(
          fechaCreacion: now,
          fechaActualizacion: now,
        ),
      );

      final docRef = await _firestore.collection(_collectionName).add(supplierData);
      
      // Obtener el documento creado para retornarlo
      final doc = await docRef.get();
      return _documentToSupplier(doc);
    } catch (e) {
      throw Exception('Error al crear proveedor: ${e.toString()}');
    }
  }

  @override
  Future<Supplier> update(String id, Supplier supplier) async {
    try {
      // Validar que el proveedor sea válido
      if (!supplier.isValid(requireId: true)) {
        final error = supplier.getValidationError(requireId: true);
        throw Exception(error ?? 'Datos del proveedor inválidos');
      }

      // Verificar que el proveedor existe
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (!doc.exists) {
        throw Exception('Proveedor no encontrado');
      }

      final supplierData = _supplierToMap(
        supplier.copyWith(
          id: id,
          fechaCreacion: _documentToSupplier(doc).fechaCreacion, // Mantener fecha original
          fechaActualizacion: DateTime.now(),
        ),
      );

      await _firestore.collection(_collectionName).doc(id).update(supplierData);
      
      // Obtener el documento actualizado para retornarlo
      final updatedDoc = await _firestore.collection(_collectionName).doc(id).get();
      return _documentToSupplier(updatedDoc);
    } catch (e) {
      throw Exception('Error al actualizar proveedor: ${e.toString()}');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      // Verificar que el proveedor existe
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      if (!doc.exists) {
        throw Exception('Proveedor no encontrado');
      }

      await _firestore.collection(_collectionName).doc(id).delete();
      return true;
    } catch (e) {
      throw Exception('Error al eliminar proveedor: ${e.toString()}');
    }
  }

  @override
  Future<List<Supplier>> search(String query) async {
    try {
      if (query.isEmpty) {
        return getAll();
      }

      final queryLower = query.toLowerCase();
      final snapshot = await _firestore.collection(_collectionName)
          .orderBy('nombre')
          .get();

      return snapshot.docs
          .map((doc) => _documentToSupplier(doc))
          .where((supplier) {
            return supplier.nombre.toLowerCase().contains(queryLower) ||
                supplier.contacto.toLowerCase().contains(queryLower) ||
                (supplier.email != null && supplier.email!.toLowerCase().contains(queryLower));
          })
          .toList();
    } catch (e) {
      throw Exception('Error al buscar proveedores: ${e.toString()}');
    }
  }

  @override
  Future<List<String>> getProductsBySupplier(String supplierId) async {
    try {
      final snapshot = await _firestore.collection(_productsCollectionName)
          .where('proveedor_id', isEqualTo: supplierId)
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      throw Exception('Error al obtener productos del proveedor: ${e.toString()}');
    }
  }
}

