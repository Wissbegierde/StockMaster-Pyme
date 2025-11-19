import 'dart:typed_data';
import '../../models/product.dart';
import '../../models/movement.dart';

/// Interfaz para el servicio de generación de reportes PDF
abstract class ReportServiceInterface {
  /// Genera un PDF con el listado completo de productos
  /// 
  /// [products] Lista de productos a incluir en el reporte
  /// Retorna los bytes del PDF generado
  Future<Uint8List> generateProductsReport(List<Product> products);
  
  /// Genera un PDF con movimientos en un rango de fechas
  /// 
  /// [movements] Lista de movimientos a incluir en el reporte
  /// [startDate] Fecha de inicio del rango (opcional)
  /// [endDate] Fecha de fin del rango (opcional)
  /// Retorna los bytes del PDF generado
  Future<Uint8List> generateMovementsReport(
    List<Movement> movements,
    DateTime? startDate,
    DateTime? endDate,
  );
}

