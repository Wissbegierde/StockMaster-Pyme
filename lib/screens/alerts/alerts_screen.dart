import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/alert_provider.dart';
import '../../models/alert.dart';
import '../../widgets/alert_card.dart';
import '../../widgets/empty_state.dart';
import '../products/product_detail_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialLoad = true;
  bool _hasCompletedInitialLoad = false;
  AlertProvider? _alertProvider;
  bool _isLoadingAlerts = false;
  String _filter = 'all'; // 'all', 'unread', 'read'

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _alertProvider = Provider.of<AlertProvider>(context, listen: false);
        _alertProvider!.addListener(_onProviderChanged);
        _loadAlerts();
      }
    });
  }

  void _onProviderChanged() {
    if (!mounted || _alertProvider == null) return;
    
    if (!_hasCompletedInitialLoad && _isInitialLoad) {
      if (!_alertProvider!.isLoading) {
        _hasCompletedInitialLoad = true;
        Future.microtask(() {
          if (mounted && _isInitialLoad) {
            setState(() {
              _isInitialLoad = false;
            });
          }
        });
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _animationController.forward();
  }

  Future<void> _loadAlerts() async {
    if (_isLoadingAlerts) return;
    
    _isLoadingAlerts = true;
    try {
      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      await alertProvider.loadAlerts();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAlerts = false;
        });
      }
    }
  }

  Future<void> _handleMarkAsRead(String alertId) async {
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    final success = await alertProvider.markAsRead(alertId);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(FontAwesomeIcons.checkCircle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Alerta marcada como leída'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _handleDelete(String alertId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Alerta'),
        content: const Text('¿Estás seguro de que quieres eliminar esta alerta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final alertProvider = Provider.of<AlertProvider>(context, listen: false);
      final success = await alertProvider.deleteAlert(alertId);
      
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(FontAwesomeIcons.checkCircle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Alerta eliminada'),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  Future<void> _handleMarkAllAsRead() async {
    final alertProvider = Provider.of<AlertProvider>(context, listen: false);
    final success = await alertProvider.markAllAsRead();
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(FontAwesomeIcons.checkCircle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Todas las alertas marcadas como leídas'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  void _handleAlertTap(Alert alert) {
    // Si la alerta está relacionada con un producto, navegar al detalle
    if (alert.productoId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(productId: alert.productoId!),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _alertProvider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(FontAwesomeIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          Consumer<AlertProvider>(
            builder: (context, alertProvider, child) {
              if (alertProvider.unreadCount > 0) {
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(FontAwesomeIcons.checkDouble),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${alertProvider.unreadCount}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: _handleMarkAllAsRead,
                  tooltip: 'Marcar todas como leídas',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF59E0B),
              Color(0xFFEF4444),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Filtros
              _buildFilters(),
              // Lista de alertas
              Expanded(
                child: Consumer<AlertProvider>(
                  builder: (context, alertProvider, child) {
                    final isLoading = alertProvider.isLoading;
                    final shouldShowSkeleton = _isInitialLoad && isLoading;
                    
                    if (shouldShowSkeleton) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 3,
                        itemBuilder: (context, index) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          height: 120,
                        ),
                      );
                    }
                    
                    return RefreshIndicator(
                      onRefresh: _loadAlerts,
                      color: const Color(0xFFF59E0B),
                      child: _buildAlertsList(alertProvider),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Consumer<AlertProvider>(
      builder: (context, alertProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterChip(
                  'Todas',
                  _filter == 'all',
                  alertProvider.alerts.length,
                  () => setState(() => _filter = 'all'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'No Leídas',
                  _filter == 'unread',
                  alertProvider.unreadCount,
                  () => setState(() => _filter = 'unread'),
                  color: const Color(0xFFEF4444),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip(
                  'Leídas',
                  _filter == 'read',
                  alertProvider.readAlerts.length,
                  () => setState(() => _filter = 'read'),
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    int count,
    VoidCallback onTap, {
    Color? color,
  }) {
    final chipColor = color ?? const Color(0xFF6B7280);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? chipColor : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList(AlertProvider alertProvider) {
    List<Alert> filteredAlerts;
    
    switch (_filter) {
      case 'unread':
        filteredAlerts = alertProvider.unreadAlerts;
        break;
      case 'read':
        filteredAlerts = alertProvider.readAlerts;
        break;
      default:
        filteredAlerts = alertProvider.alerts;
    }

    if (filteredAlerts.isEmpty && !alertProvider.isLoading && !_isInitialLoad) {
      return _buildEmptyState(alertProvider);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredAlerts.length,
        itemBuilder: (context, index) {
          final alert = filteredAlerts[index];
          return AlertCard(
            alert: alert,
            onTap: () => _handleAlertTap(alert),
            onMarkAsRead: () => _handleMarkAsRead(alert.id),
            onDelete: () => _handleDelete(alert.id),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AlertProvider alertProvider) {
    String title;
    String message;
    IconData icon;
    
    switch (_filter) {
      case 'unread':
        title = 'No hay alertas no leídas';
        message = 'Todas las alertas han sido leídas';
        icon = FontAwesomeIcons.checkCircle;
        break;
      case 'read':
        title = 'No hay alertas leídas';
        message = 'Aún no has leído ninguna alerta';
        icon = FontAwesomeIcons.envelopeOpen;
        break;
      default:
        title = 'No hay alertas';
        message = 'No se han generado alertas aún';
        icon = FontAwesomeIcons.bell;
    }
    
    return EmptyState(
      icon: icon,
      title: title,
      message: message,
    );
  }
}

