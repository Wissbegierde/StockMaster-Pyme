import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/movement.dart';
import 'interfaces/report_service_interface.dart';

class ReportService implements ReportServiceInterface {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy');
  final DateFormat _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  Future<Uint8List> generateProductsReport(List<Product> products) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Encabezado
            _buildHeader('Reporte de Productos', now),
            pw.SizedBox(height: 20),
            
            // Tabla de productos
            if (products.isEmpty)
              pw.Center(
                child: pw.Text(
                  'No hay productos para mostrar',
                  style: pw.TextStyle(fontSize: 14),
                ),
              )
            else
              _buildProductsTable(products),
            
            pw.SizedBox(height: 20),
            
            // Resumen
            _buildProductsSummary(products),
          ];
        },
      ),
    );
    
    return pdf.save();
  }

  @override
  Future<Uint8List> generateMovementsReport(
    List<Movement> movements,
    DateTime? startDate,
    DateTime? endDate,
  ) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    
    // Filtrar movimientos por rango de fechas si se proporciona
    List<Movement> filteredMovements = movements;
    if (startDate != null || endDate != null) {
      filteredMovements = movements.where((movement) {
        final movementDate = movement.fecha;
        if (startDate != null && movementDate.isBefore(startDate)) {
          return false;
        }
        if (endDate != null) {
          final endDateWithTime = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (movementDate.isAfter(endDateWithTime)) {
            return false;
          }
        }
        return true;
      }).toList();
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Encabezado
            _buildHeader(
              'Reporte de Movimientos',
              now,
              startDate: startDate,
              endDate: endDate,
            ),
            pw.SizedBox(height: 20),
            
            // Tabla de movimientos
            if (filteredMovements.isEmpty)
              pw.Center(
                child: pw.Text(
                  'No hay movimientos para mostrar en el rango seleccionado',
                  style: pw.TextStyle(fontSize: 14),
                ),
              )
            else
              _buildMovementsTable(filteredMovements),
            
            pw.SizedBox(height: 20),
            
            // Resumen
            _buildMovementsSummary(filteredMovements),
          ];
        },
      ),
    );
    
    return pdf.save();
  }

  pw.Widget _buildHeader(
    String title,
    DateTime generatedDate, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generado el: ${_dateTimeFormat.format(generatedDate)}',
          style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
        ),
        if (startDate != null || endDate != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Período: ${startDate != null ? _dateFormat.format(startDate) : 'Inicio'} - ${endDate != null ? _dateFormat.format(endDate) : 'Fin'}',
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildProductsTable(List<Product> products) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(1.2),
        5: const pw.FlexColumnWidth(1.2),
        6: const pw.FlexColumnWidth(1.2),
      },
      children: [
        // Encabezados
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Código', isHeader: true),
            _buildTableCell('Nombre', isHeader: true),
            _buildTableCell('Categoría', isHeader: true),
            _buildTableCell('Precio', isHeader: true),
            _buildTableCell('Stock', isHeader: true),
            _buildTableCell('Mínimo', isHeader: true),
            _buildTableCell('Estado', isHeader: true),
          ],
        ),
        // Filas de datos
        ...products.map((product) {
          final isLowStock = product.tieneStockBajo;
          return pw.TableRow(
            decoration: isLowStock
                ? const pw.BoxDecoration(color: PdfColors.red50)
                : null,
            children: [
              _buildTableCell(product.codigo),
              _buildTableCell(product.nombre),
              _buildTableCell(product.categoria),
              _buildTableCell('\$${product.precio.toStringAsFixed(2)}'),
              _buildTableCell(product.stockActual.toString()),
              _buildTableCell(product.stockMinimo.toString()),
              _buildTableCell(
                isLowStock ? 'Bajo Stock' : 'Normal',
                textColor: isLowStock ? PdfColors.red : PdfColors.green,
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildProductsSummary(List<Product> products) {
    final totalProducts = products.length;
    final lowStockCount = products.where((p) => p.tieneStockBajo).length;
    final totalValue = products.fold<double>(
      0.0,
      (sum, product) => sum + product.valorInventario,
    );
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumen',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildSummaryRow('Total de Productos:', totalProducts.toString()),
          _buildSummaryRow('Productos con Stock Bajo:', lowStockCount.toString()),
          _buildSummaryRow(
            'Valor Total del Inventario:',
            '\$${totalValue.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  pw.Widget _buildMovementsTable(List<Movement> movements) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(1.2),
        4: const pw.FlexColumnWidth(2.0),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Encabezados
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Fecha', isHeader: true),
            _buildTableCell('Tipo', isHeader: true),
            _buildTableCell('Producto', isHeader: true),
            _buildTableCell('Cantidad', isHeader: true),
            _buildTableCell('Motivo', isHeader: true),
            _buildTableCell('Usuario', isHeader: true),
          ],
        ),
        // Filas de datos
        ...movements.map((movement) {
          final isEntrada = movement.tipo == MovementType.entrada;
          return pw.TableRow(
            decoration: isEntrada
                ? const pw.BoxDecoration(color: PdfColors.green50)
                : const pw.BoxDecoration(color: PdfColors.red50),
            children: [
              _buildTableCell(_dateTimeFormat.format(movement.fecha)),
              _buildTableCell(
                isEntrada ? 'Entrada' : 'Salida',
                textColor: isEntrada ? PdfColors.green : PdfColors.red,
              ),
              _buildTableCell(movement.productoNombre ?? 'N/A'),
              _buildTableCell(movement.cantidad.toString()),
              _buildTableCell(movement.motivo),
              _buildTableCell(movement.usuarioNombre ?? 'N/A'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildMovementsSummary(List<Movement> movements) {
    final totalEntradas = movements
        .where((m) => m.tipo == MovementType.entrada)
        .fold<int>(0, (sum, m) => sum + m.cantidad);
    final totalSalidas = movements
        .where((m) => m.tipo == MovementType.salida)
        .fold<int>(0, (sum, m) => sum + m.cantidad);
    final balanceNeto = totalEntradas - totalSalidas;
    final cantidadEntradas = movements.where((m) => m.tipo == MovementType.entrada).length;
    final cantidadSalidas = movements.where((m) => m.tipo == MovementType.salida).length;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumen',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildSummaryRow('Total Entradas:', '$cantidadEntradas (Cantidad: $totalEntradas)'),
          _buildSummaryRow('Total Salidas:', '$cantidadSalidas (Cantidad: $totalSalidas)'),
          _buildSummaryRow(
            'Balance Neto:',
            balanceNeto >= 0 ? '+$balanceNeto' : balanceNeto.toString(),
            textColor: balanceNeto >= 0 ? PdfColors.green : PdfColors.red,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: textColor,
        ),
      ),
    );
  }

  pw.Widget _buildSummaryRow(String label, String value, {PdfColor? textColor}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

