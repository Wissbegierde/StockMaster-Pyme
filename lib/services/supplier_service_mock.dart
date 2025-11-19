import 'dart:async';
import '../models/supplier.dart';
import 'interfaces/supplier_service_interface.dart';

/// Servicio Mock para proveedores (desarrollo y testing)
/// Implementa SupplierServiceInterface con datos de prueba
class SupplierServiceMock implements SupplierServiceInterface {
  final List<Supplier> _suppliers = [];
  int _nextId = 1;

  SupplierServiceMock() {
    // Inicializar con algunos proveedores de ejemplo
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();
    _suppliers.addAll([
      Supplier(
        id: 'supp-001',
        nombre: 'Proveedor ABC S.A.',
        contacto: 'Juan Pérez',
        telefono: '+1234567890',
        email: 'contacto@proveedorabc.com',
        direccion: 'Calle 123, Ciudad, País',
        fechaCreacion: now.subtract(const Duration(days: 30)),
        fechaActualizacion: now.subtract(const Duration(days: 5)),
      ),
      Supplier(
        id: 'supp-002',
        nombre: 'Distribuidora XYZ',
        contacto: 'María García',
        telefono: '+9876543210',
        email: 'ventas@distribuidoraxyz.com',
        direccion: 'Avenida Principal 456',
        fechaCreacion: now.subtract(const Duration(days: 20)),
        fechaActualizacion: now.subtract(const Duration(days: 2)),
      ),
      Supplier(
        id: 'supp-003',
        nombre: 'Importadora Global',
        contacto: 'Carlos Rodríguez',
        telefono: '+5551234567',
        email: 'info@importadoraglobal.com',
        direccion: 'Boulevard Industrial 789',
        fechaCreacion: now.subtract(const Duration(days: 15)),
        fechaActualizacion: now.subtract(const Duration(days: 1)),
      ),
      Supplier(
        id: 'supp-004',
        nombre: 'Tecnología Avanzada',
        contacto: 'Ana Martínez',
        telefono: '+1112223333',
        email: null, // Sin email
        direccion: 'Zona Tecnológica 321',
        fechaCreacion: now.subtract(const Duration(days: 10)),
        fechaActualizacion: now.subtract(const Duration(days: 3)),
      ),
    ]);
    _nextId = 5;
  }

  // Simular delay de red
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Future<List<Supplier>> getAll({int? page, int? limit}) async {
    await _simulateDelay();
    
    var suppliers = List<Supplier>.from(_suppliers);
    
    // Ordenar por nombre
    suppliers.sort((a, b) => a.nombre.compareTo(b.nombre));
    
    // Paginación
    if (page != null && limit != null) {
      final start = page * limit;
      final end = start + limit;
      if (start < suppliers.length) {
        suppliers = suppliers.sublist(
          start,
          end > suppliers.length ? suppliers.length : end,
        );
      } else {
        suppliers = [];
      }
    }
    
    return suppliers;
  }

  @override
  Future<Supplier?> getById(String id) async {
    await _simulateDelay();
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Supplier> create(Supplier supplier) async {
    await _simulateDelay();
    
    // Validar que el proveedor sea válido
    if (!supplier.isValid()) {
      final error = supplier.getValidationError();
      throw Exception(error ?? 'Datos del proveedor inválidos');
    }

    // Crear nuevo proveedor con ID
    final now = DateTime.now();
    final newSupplier = supplier.copyWith(
      id: _nextId.toString(),
      fechaCreacion: now,
      fechaActualizacion: now,
    );
    
    _nextId++;
    _suppliers.add(newSupplier);
    
    return newSupplier;
  }

  @override
  Future<Supplier> update(String id, Supplier supplier) async {
    await _simulateDelay();
    
    // Validar que el proveedor sea válido
    if (!supplier.isValid(requireId: true)) {
      final error = supplier.getValidationError(requireId: true);
      throw Exception(error ?? 'Datos del proveedor inválidos');
    }

    final index = _suppliers.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw Exception('Proveedor no encontrado');
    }

    final updatedSupplier = supplier.copyWith(
      id: id,
      fechaActualizacion: DateTime.now(),
    );
    
    _suppliers[index] = updatedSupplier;
    return updatedSupplier;
  }

  @override
  Future<bool> delete(String id) async {
    await _simulateDelay();
    
    final index = _suppliers.indexWhere((s) => s.id == id);
    if (index == -1) {
      throw Exception('Proveedor no encontrado');
    }
    
    _suppliers.removeAt(index);
    return true;
  }

  @override
  Future<List<Supplier>> search(String query) async {
    await _simulateDelay();
    
    if (query.isEmpty) {
      return getAll();
    }
    
    final queryLower = query.toLowerCase();
    return _suppliers.where((supplier) {
      return supplier.nombre.toLowerCase().contains(queryLower) ||
          supplier.contacto.toLowerCase().contains(queryLower) ||
          (supplier.email != null && supplier.email!.toLowerCase().contains(queryLower));
    }).toList();
  }

  @override
  Future<List<String>> getProductsBySupplier(String supplierId) async {
    await _simulateDelay();
    
    // Simular productos asociados al proveedor
    // En una implementación real, esto consultaría la base de datos de productos
    // Por ahora, retornamos una lista vacía o algunos IDs de ejemplo
    if (supplierId == 'supp-001') {
      return ['prod-001', 'prod-002'];
    } else if (supplierId == 'supp-002') {
      return ['prod-003'];
    }
    
    return [];
  }
}

