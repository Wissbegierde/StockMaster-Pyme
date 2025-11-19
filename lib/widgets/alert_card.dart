import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../models/alert.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;
  final VoidCallback? onDelete;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
    this.onMarkAsRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final color = _getColorForType(alert.tipo);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alert.leida 
                ? Colors.grey[300]! 
                : color.withOpacity(0.3),
            width: alert.leida ? 1 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono del tipo de alerta
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getIconForType(alert.tipo),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Título y tipo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              alert.titulo,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: alert.leida 
                                    ? Colors.grey[600] 
                                    : const Color(0xFF111827),
                                decoration: alert.leida 
                                    ? TextDecoration.lineThrough 
                                    : null,
                              ),
                            ),
                          ),
                          if (!alert.leida)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alert.getTipoLabel(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Menú de acciones
                PopupMenuButton<String>(
                  icon: Icon(
                    FontAwesomeIcons.ellipsisVertical,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  onSelected: (value) {
                    if (value == 'read' && onMarkAsRead != null) {
                      onMarkAsRead!();
                    } else if (value == 'delete' && onDelete != null) {
                      onDelete!();
                    }
                  },
                  itemBuilder: (context) => [
                    if (!alert.leida)
                      PopupMenuItem(
                        value: 'read',
                        child: Row(
                          children: [
                            const Icon(FontAwesomeIcons.check, size: 14),
                            const SizedBox(width: 8),
                            const Text('Marcar como leída'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(FontAwesomeIcons.trash, size: 14, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Mensaje
            Text(
              alert.mensaje,
              style: TextStyle(
                fontSize: 14,
                color: alert.leida 
                    ? Colors.grey[500] 
                    : const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 12),
            // Fecha
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.clock,
                  size: 12,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 6),
                Text(
                  dateFormat.format(alert.fechaCreacion),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (alert.leida && alert.fechaLectura != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    FontAwesomeIcons.checkCircle,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Leída: ${dateFormat.format(alert.fechaLectura!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(AlertType tipo) {
    switch (tipo) {
      case AlertType.stockBajo:
        return const Color(0xFFF59E0B);
      case AlertType.movimientoImportante:
        return const Color(0xFF3B82F6);
      case AlertType.productoAgotado:
        return const Color(0xFFEF4444);
    }
  }

  IconData _getIconForType(AlertType tipo) {
    switch (tipo) {
      case AlertType.stockBajo:
        return FontAwesomeIcons.exclamationTriangle;
      case AlertType.movimientoImportante:
        return FontAwesomeIcons.arrowRightArrowLeft;
      case AlertType.productoAgotado:
        return FontAwesomeIcons.boxOpen;
    }
  }
}

