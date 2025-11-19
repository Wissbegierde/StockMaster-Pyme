import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/alert_provider.dart';
import '../screens/alerts/alerts_screen.dart';
import 'alert_card.dart';

class AlertsMenu extends StatefulWidget {
  const AlertsMenu({super.key});

  @override
  State<AlertsMenu> createState() => _AlertsMenuState();
}

class _AlertsMenuState extends State<AlertsMenu> {
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;

  void _showAlertsMenu(BuildContext context) {
    if (_isMenuOpen) {
      _hideAlertsMenu();
      return;
    }

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Fondo difuminado
          GestureDetector(
            onTap: _hideAlertsMenu,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // Menú de alertas
          Positioned(
            top: offset.dy + size.height + 8,
            right: 16,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            FontAwesomeIcons.bell,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Alertas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Consumer<AlertProvider>(
                            builder: (context, alertProvider, child) {
                              if (alertProvider.unreadCount > 0) {
                                return TextButton(
                                  onPressed: () async {
                                    await alertProvider.markAllAsRead();
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Todas las alertas marcadas como leídas'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Marcar todas',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              FontAwesomeIcons.xmark,
                              color: Colors.white,
                              size: 18,
                            ),
                            onPressed: _hideAlertsMenu,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    // Lista de alertas
                    Flexible(
                      child: Consumer<AlertProvider>(
                        builder: (context, alertProvider, child) {
                          if (alertProvider.isLoading && alertProvider.alerts.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: CircularProgressIndicator(),
                            );
                          }

                          final unreadAlerts = alertProvider.unreadAlerts.take(5).toList();
                          final allAlerts = alertProvider.alerts.take(5).toList();

                          if (unreadAlerts.isEmpty && allAlerts.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.bellSlash,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No hay alertas',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: unreadAlerts.isNotEmpty ? unreadAlerts.length : allAlerts.length,
                            itemBuilder: (context, index) {
                              final alert = unreadAlerts.isNotEmpty
                                  ? unreadAlerts[index]
                                  : allAlerts[index];
                              return AlertCard(
                                alert: alert,
                                onMarkAsRead: () async {
                                  await alertProvider.markAsRead(alert.id);
                                },
                                onDelete: () async {
                                  await alertProvider.deleteAlert(alert.id);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    // Footer con botón para ver todas
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _hideAlertsMenu();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AlertsScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Ver todas las alertas'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );

    overlay.insert(_overlayEntry!);
    setState(() {
      _isMenuOpen = true;
    });
  }

  void _hideAlertsMenu() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isMenuOpen = false;
    });
  }

  @override
  void dispose() {
    _hideAlertsMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlertProvider>(
      builder: (context, alertProvider, child) {
        final unreadCount = alertProvider.unreadCount;
        
        return GestureDetector(
          onTap: () => _showAlertsMenu(context),
          child: Stack(
            children: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.bell),
                onPressed: () => _showAlertsMenu(context),
                tooltip: 'Alertas',
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

