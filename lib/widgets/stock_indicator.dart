import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/product.dart';

class StockIndicator extends StatelessWidget {
  final Product product;
  final bool showLabel;
  final bool compact;

  const StockIndicator({
    super.key,
    required this.product,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.tieneStockBajo;
    final stockColor = isLowStock ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final icon = isLowStock 
        ? FontAwesomeIcons.exclamationTriangle 
        : FontAwesomeIcons.checkCircle;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: stockColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: stockColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: stockColor),
            const SizedBox(width: 4),
            Text(
              product.estadoStock,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: stockColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stockColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stockColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: stockColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showLabel)
                  Text(
                    'Stock: ${product.stockActual}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                if (showLabel)
                  const SizedBox(height: 4),
                Text(
                  showLabel 
                      ? 'Mínimo: ${product.stockMinimo}'
                      : '${product.stockActual} / ${product.stockMinimo}',
                  style: TextStyle(
                    fontSize: showLabel ? 12 : 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: stockColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              product.estadoStock,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

