import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/movement_provider.dart';
import '../providers/product_provider.dart';
import '../models/movement.dart';

class MovementStatsCard extends StatelessWidget {
  final MovementProvider movementProvider;

  const MovementStatsCard({
    super.key,
    required this.movementProvider,
  });

  // Calcular dinero ganado (valor de las salidas)
  double _calcularDineroGanado(MovementProvider movementProvider, ProductProvider productProvider) {
    double total = 0.0;
    
    for (final movement in movementProvider.movements) {
      if (movement.tipo == MovementType.salida) {
        // Buscar el producto para obtener su precio
        try {
          final product = productProvider.products.firstWhere(
            (p) => p.id == movement.productId,
          );
          total += movement.cantidad * product.precio;
        } catch (e) {
          // Si el producto no existe, simplemente no lo contamos
          // (puede haber sido eliminado)
        }
      }
    }
    
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final totalEntradas = movementProvider.totalEntradas;
    final totalSalidas = movementProvider.totalSalidas;
    final balanceNeto = movementProvider.balanceNeto;
    final cantidadEntradas = movementProvider.cantidadEntradas;
    final cantidadSalidas = movementProvider.cantidadSalidas;
    
    // Calcular dinero ganado - usar Consumer para que se actualice cuando cambien los productos
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final dineroGanado = _calcularDineroGanado(movementProvider, productProvider);
        final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
        
        return _buildStatsContent(
          totalEntradas: totalEntradas,
          totalSalidas: totalSalidas,
          balanceNeto: balanceNeto,
          cantidadEntradas: cantidadEntradas,
          cantidadSalidas: cantidadSalidas,
          dineroGanado: dineroGanado,
          formatter: formatter,
        );
      },
    );
  }
  
  Widget _buildStatsContent({
    required int totalEntradas,
    required int totalSalidas,
    required int balanceNeto,
    required int cantidadEntradas,
    required int cantidadSalidas,
    required double dineroGanado,
    required NumberFormat formatter,
  }) {

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.chartBar,
                size: 20,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              const Text(
                'Resumen de Movimientos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Entradas
              Expanded(
                child: _buildStatItem(
                  icon: FontAwesomeIcons.arrowUp,
                  iconColor: const Color(0xFF10B981),
                  label: 'Entradas',
                  value: totalEntradas.toString(),
                  count: cantidadEntradas,
                ),
              ),
              const SizedBox(width: 12),
              // Salidas
              Expanded(
                child: _buildStatItem(
                  icon: FontAwesomeIcons.arrowDown,
                  iconColor: const Color(0xFFEF4444),
                  label: 'Salidas',
                  value: totalSalidas.toString(),
                  count: cantidadSalidas,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Balance Neto
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: balanceNeto >= 0
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: balanceNeto >= 0
                    ? const Color(0xFF10B981).withOpacity(0.3)
                    : const Color(0xFFEF4444).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      balanceNeto >= 0
                          ? FontAwesomeIcons.arrowTrendUp
                          : FontAwesomeIcons.arrowTrendDown,
                      size: 16,
                      color: balanceNeto >= 0
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Balance Neto',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                Text(
                  balanceNeto >= 0 ? '+$balanceNeto' : '$balanceNeto',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: balanceNeto >= 0
                        ? const Color(0xFF10B981)
                        : const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Dinero Ganado
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      FontAwesomeIcons.dollarSign,
                      size: 16,
                      color: Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Dinero Ganado',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                Text(
                  formatter.format(dineroGanado),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count movimiento${count != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

