import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/movement.dart';
import 'interfaces/movement_service_interface.dart';

/// Servicio Firebase para movimientos usando Firestore
/// Implementa MovementServiceInterface para facilitar migración desde HTTP
class FirebaseMovementService implements MovementServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'movements';
  final String _productsCollectionName = 'products';

  /// Convertir documento de Firestore a Movement
  Movement _documentToMovement(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Movement(
      id: doc.id,
      productId: data['product_id'] ?? data['productId'] ?? '',
      tipo: _stringToMovementType(data['tipo'] ?? data['type'] ?? ''),
      cantidad: data['cantidad'] ?? data['quantity'] ?? 0,
      motivo: data['motivo'] ?? data['reason'] ?? '',
      usuarioId: data['usuario_id'] ?? data['usuarioId'] ?? data['user_id'] ?? data['userId'] ?? '',
      fecha: data['fecha'] != null
          ? (data['fecha'] as Timestamp).toDate()
          : data['date'] != null
              ? (data['date'] as Timestamp).toDate()
              : DateTime.now(),
      productoNombre: data['producto_nombre'] ?? data['productoNombre'] ?? data['product_name'],
      usuarioNombre: data['usuario_nombre'] ?? data['usuarioNombre'] ?? data['user_name'],
      fechaCreacion: data['fecha_creacion'] != null
          ? (data['fecha_creacion'] as Timestamp).toDate()
          : data['created_at'] != null
              ? (data['created_at'] as Timestamp).toDate()
              : null,
      fechaActualizacion: data['fecha_actualizacion'] != null
          ? (data['fecha_actualizacion'] as Timestamp).toDate()
          : data['updated_at'] != null
              ? (data['updated_at'] as Timestamp).toDate()
              : null,
    );
  }

  /// Convertir string a MovementType
  MovementType _stringToMovementType(String tipoStr) {
    switch (tipoStr.toLowerCase()) {
      case 'entrada':
      case 'entry':
      case 'in':
        return MovementType.entrada;
      case 'salida':
      case 'exit':
      case 'out':
        return MovementType.salida;
      default:
        return MovementType.entrada; // Default
    }
  }

  /// Convertir MovementType a string
  String _movementTypeToString(MovementType tipo) {
    switch (tipo) {
      case MovementType.entrada:
        return 'entrada';
      case MovementType.salida:
        return 'salida';
    }
  }

  /// Convertir Movement a Map para Firestore
  Map<String, dynamic> _movementToMap(Movement movement, {bool includeId = false}) {
    final map = <String, dynamic>{
      'product_id': movement.productId,
      'tipo': _movementTypeToString(movement.tipo),
      'cantidad': movement.cantidad,
      'motivo': movement.motivo,
      'usuario_id': movement.usuarioId,
      'fecha': Timestamp.fromDate(movement.fecha),
    };
    
    if (movement.productoNombre != null) {
      map['producto_nombre'] = movement.productoNombre;
    }
    if (movement.usuarioNombre != null) {
      map['usuario_nombre'] = movement.usuarioNombre;
    }
    if (movement.fechaCreacion != null) {
      map['fecha_creacion'] = Timestamp.fromDate(movement.fechaCreacion!);
    }
    if (movement.fechaActualizacion != null) {
      map['fecha_actualizacion'] = Timestamp.fromDate(movement.fechaActualizacion!);
    }
    
    if (includeId) {
      map['id'] = movement.id;
    }
    
    return map;
  }

  @override
  Future<List<Movement>> getAll({int? page, int? limit}) async {
    try {
      Query query = _firestore.collection(_collectionName)
          .orderBy('fecha', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => _documentToMovement(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos: ${e.toString()}');
    }
  }

  @override
  Future<Movement?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();
      
      if (!doc.exists) {
        return null;
      }
      
      return _documentToMovement(doc);
    } catch (e) {
      throw Exception('Error al obtener movimiento: ${e.toString()}');
    }
  }

  @override
  Future<Movement> create(Movement movement) async {
    try {
      // Usar transacción para actualizar stock y crear movimiento atómicamente
      return await _firestore.runTransaction((transaction) async {
        // Leer el documento del producto
        final productRef = _firestore.collection(_productsCollectionName).doc(movement.productId);
        final productDoc = await transaction.get(productRef);
        
        if (!productDoc.exists) {
          throw Exception('El producto no existe');
        }
        
        final productData = productDoc.data()!;
        final stockActual = productData['stock_actual'] ?? productData['stockActual'] ?? 0;
        int nuevoStock;
        
        // Calcular nuevo stock según el tipo de movimiento
        switch (movement.tipo) {
          case MovementType.entrada:
            nuevoStock = stockActual + movement.cantidad;
            break;
          case MovementType.salida:
            nuevoStock = stockActual - movement.cantidad;
            // Validar que no resulte en stock negativo
            if (nuevoStock < 0) {
              throw Exception('Stock insuficiente. Disponible: $stockActual, Solicitado: ${movement.cantidad}');
            }
            break;
        }
        
        // Actualizar stock del producto
        transaction.update(productRef, {
          'stock_actual': nuevoStock,
          'fecha_actualizacion': Timestamp.now(),
        });
        
        // Crear documento de movimiento
        final now = DateTime.now();
        final movementWithDates = Movement(
          id: '', // Firestore generará el ID
          productId: movement.productId,
          tipo: movement.tipo,
          cantidad: movement.cantidad,
          motivo: movement.motivo,
          usuarioId: movement.usuarioId,
          fecha: movement.fecha,
          productoNombre: movement.productoNombre,
          usuarioNombre: movement.usuarioNombre,
          fechaCreacion: now,
          fechaActualizacion: now,
        );
        
        final movementData = _movementToMap(movementWithDates);
        final movementRef = _firestore.collection(_collectionName).doc();
        transaction.set(movementRef, movementData);
        
        // Retornar el movimiento con el ID generado
        return movementWithDates.copyWith(id: movementRef.id);
      });
    } catch (e) {
      throw Exception('Error al crear movimiento: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByProduct(String productId) async {
    try {
      final snapshot = await _firestore.collection(_collectionName)
          .where('product_id', isEqualTo: productId)
          .orderBy('fecha', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => _documentToMovement(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos del producto: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByDateRange(DateTime start, DateTime end) async {
    try {
      final startTimestamp = Timestamp.fromDate(start);
      final endTimestamp = Timestamp.fromDate(end);
      
      // Firestore requiere un índice compuesto para múltiples where + orderBy
      // Por ahora, filtramos en memoria después de obtener los datos
      // Para producción, crea un índice compuesto en Firestore Console
      final snapshot = await _firestore.collection(_collectionName)
          .where('fecha', isGreaterThanOrEqualTo: startTimestamp)
          .where('fecha', isLessThanOrEqualTo: endTimestamp)
          .get();
      
      final movements = snapshot.docs
          .map((doc) => _documentToMovement(doc))
          .toList();
      
      // Ordenar por fecha descendente
      movements.sort((a, b) => b.fecha.compareTo(a.fecha));
      
      return movements;
    } catch (e) {
      throw Exception('Error al obtener movimientos por rango de fechas: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByProductAndDateRange(
    String productId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final startTimestamp = Timestamp.fromDate(start);
      final endTimestamp = Timestamp.fromDate(end);
      
      // Firestore requiere un índice compuesto para múltiples where + orderBy
      // Por ahora, filtramos en memoria después de obtener los datos
      // Para producción, crea un índice compuesto en Firestore Console
      final snapshot = await _firestore.collection(_collectionName)
          .where('product_id', isEqualTo: productId)
          .where('fecha', isGreaterThanOrEqualTo: startTimestamp)
          .where('fecha', isLessThanOrEqualTo: endTimestamp)
          .get();
      
      final movements = snapshot.docs
          .map((doc) => _documentToMovement(doc))
          .toList();
      
      // Ordenar por fecha descendente
      movements.sort((a, b) => b.fecha.compareTo(a.fecha));
      
      return movements;
    } catch (e) {
      throw Exception('Error al obtener movimientos del producto por rango de fechas: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getRecent(int limit) async {
    try {
      final snapshot = await _firestore.collection(_collectionName)
          .orderBy('fecha', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => _documentToMovement(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos recientes: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByType(MovementType type) async {
    try {
      final tipoStr = _movementTypeToString(type);
      
      final snapshot = await _firestore.collection(_collectionName)
          .where('tipo', isEqualTo: tipoStr)
          .orderBy('fecha', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => _documentToMovement(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos por tipo: ${e.toString()}');
    }
  }

  @override
  Future<List<Movement>> getByUser(String userId) async {
    try {
      final snapshot = await _firestore.collection(_collectionName)
          .where('usuario_id', isEqualTo: userId)
          .orderBy('fecha', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => _documentToMovement(doc)).toList();
    } catch (e) {
      throw Exception('Error al obtener movimientos por usuario: ${e.toString()}');
    }
  }
}

