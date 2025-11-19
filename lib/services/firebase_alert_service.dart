import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert.dart';
import 'interfaces/alert_service_interface.dart';

/// Servicio Firebase para alertas
/// Implementa AlertServiceInterface usando Firestore
class FirebaseAlertService implements AlertServiceInterface {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'alerts';

  @override
  Future<List<Alert>> getAll() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('fecha_creacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Alert.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener alertas: ${e.toString()}');
    }
  }

  @override
  Future<Alert?> getById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) {
        return null;
      }
      return Alert.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Error al obtener alerta: ${e.toString()}');
    }
  }

  @override
  Future<List<Alert>> getUnread() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('leida', isEqualTo: false)
          .orderBy('fecha_creacion', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Alert.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener alertas no leídas: ${e.toString()}');
    }
  }

  @override
  Future<Alert> create(Alert alert) async {
    try {
      final data = alert.toJson();
      data.remove('id'); // Firestore genera el ID

      final docRef = await _firestore.collection(_collection).add(data);
      final doc = await docRef.get();
      
      return Alert.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      throw Exception('Error al crear alerta: ${e.toString()}');
    }
  }

  @override
  Future<bool> markAsRead(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'leida': true,
        'fecha_lectura': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      throw Exception('Error al marcar alerta como leída: ${e.toString()}');
    }
  }

  @override
  Future<bool> markAllAsRead() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('leida', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      final now = DateTime.now().toIso8601String();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'leida': true,
          'fecha_lectura': now,
        });
      }

      await batch.commit();
      return true;
    } catch (e) {
      throw Exception('Error al marcar todas las alertas como leídas: ${e.toString()}');
    }
  }

  @override
  Future<bool> delete(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      throw Exception('Error al eliminar alerta: ${e.toString()}');
    }
  }
}

