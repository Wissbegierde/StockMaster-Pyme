import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/supplier_provider.dart';
import '../../providers/product_provider.dart';
import '../../models/supplier.dart';
import '../../widgets/supplier_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/supplier_card_skeleton.dart';
import 'supplier_form_screen.dart';
import 'supplier_detail_screen.dart';

class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialLoad = true;
  bool _hasCompletedInitialLoad = false;
  SupplierProvider? _supplierProvider;
  bool _isLoadingSuppliers = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Cargar proveedores y configurar listener después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
        _supplierProvider!.addListener(_onProviderChanged);
        _loadSuppliers();
      }
    });
  }
  
  void _onProviderChanged() {
    if (!mounted || _supplierProvider == null) return;
    
    // Solo procesar la carga inicial una vez
    if (!_hasCompletedInitialLoad && _isInitialLoad) {
      // Si la carga inicial terminó (no está cargando)
      if (!_supplierProvider!.isLoading) {
        _hasCompletedInitialLoad = true;
        // Usar Future.microtask para evitar cambiar estado durante el build
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

  Future<void> _loadSuppliers() async {
    // Evitar llamadas simultáneas
    if (_isLoadingSuppliers) {
      return;
    }
    
    _isLoadingSuppliers = true;
    
    try {
      final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
      await supplierProvider.loadSuppliers();
    } finally {
      _isLoadingSuppliers = false;
    }
  }

  @override
  void dispose() {
    // Remover listener del provider si está disponible
    if (_supplierProvider != null) {
      _supplierProvider!.removeListener(_onProviderChanged);
      _supplierProvider = null;
    }
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    supplierProvider.searchSuppliers(query);
  }

  void _handleClearFilters() {
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    supplierProvider.clearFilters();
    _searchController.clear();
  }

  Future<void> _handleDeleteSupplier(Supplier supplier) async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    
    // Verificar si tiene productos asociados
    final products = productProvider.products
        .where((p) => p.proveedorId == supplier.id)
        .toList();
    final hasProducts = products.isNotEmpty;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              FontAwesomeIcons.triangleExclamation,
              color: Colors.red[400],
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar Proveedor',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que quieres eliminar este proveedor?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.truck,
                        size: 16,
                        color: const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          supplier.nombre,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contacto: ${supplier.contacto}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (hasProducts) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      FontAwesomeIcons.exclamationTriangle,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Este proveedor tiene ${products.length} producto${products.length != 1 ? 's' : ''} asociado${products.length != 1 ? 's' : ''}. Los productos no se eliminarán, pero perderán la referencia al proveedor.',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  FontAwesomeIcons.circleInfo,
                  size: 14,
                  color: Colors.red[400],
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Esta acción no se puede deshacer.',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
      final success = await supplierProvider.deleteSupplier(supplier.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.checkCircle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Proveedor "${supplier.nombre}" eliminado correctamente'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.exclamationCircle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(supplierProvider.errorMessage ?? 'Error al eliminar proveedor'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(FontAwesomeIcons.arrowLeft),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<SupplierProvider>(
            builder: (context, supplierProvider, child) {
              if (supplierProvider.searchQuery.isNotEmpty) {
                return IconButton(
                  icon: const Icon(FontAwesomeIcons.xmark),
                  onPressed: _handleClearFilters,
                  tooltip: 'Limpiar búsqueda',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8B5CF6),
              Color(0xFFA78BFA),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barra de búsqueda
              _buildSearchBar(),
              // Lista de proveedores
              Expanded(
                child: Consumer<SupplierProvider>(
                  builder: (context, supplierProvider, child) {
                    final isLoading = supplierProvider.isLoading;
                    // Solo mostrar skeleton durante la carga inicial
                    final shouldShowSkeleton = _isInitialLoad && isLoading;
                    
                    if (shouldShowSkeleton) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 3,
                        itemBuilder: (context, index) => const SupplierCardSkeleton(),
                      );
                    }
                    
                    return RefreshIndicator(
                      onRefresh: _loadSuppliers,
                      color: const Color(0xFF8B5CF6),
                      child: _buildSuppliersList(supplierProvider),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SupplierFormScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                  )),
                  child: child,
                );
              },
            ),
          ).then((_) => _loadSuppliers());
        },
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _handleSearch,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, contacto o email...',
          prefixIcon: const Icon(FontAwesomeIcons.magnifyingGlass, size: 16),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(FontAwesomeIcons.xmark, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    _handleSearch('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSuppliersList(SupplierProvider supplierProvider) {
    final suppliers = supplierProvider.filteredSuppliers;

    // Si no hay proveedores y no está cargando (y ya pasó la carga inicial), mostrar empty state
    if (suppliers.isEmpty && !supplierProvider.isLoading && !_isInitialLoad) {
      return _buildEmptyState(supplierProvider);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: suppliers.length,
        itemBuilder: (context, index) {
          final supplier = suppliers[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 50)),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: SupplierCard(
              supplier: supplier,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SupplierDetailScreen(supplierId: supplier.id),
                  ),
                );
              },
              onEdit: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SupplierFormScreen(supplier: supplier),
                  ),
                ).then((_) => _loadSuppliers());
              },
              onDelete: () => _handleDeleteSupplier(supplier),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(SupplierProvider supplierProvider) {
    final hasSearch = supplierProvider.searchQuery.isNotEmpty;
    
    return EmptyState(
      icon: hasSearch ? FontAwesomeIcons.magnifyingGlass : FontAwesomeIcons.truck,
      title: hasSearch ? 'No se encontraron proveedores' : 'No hay proveedores',
      message: hasSearch
          ? 'Intenta con otros términos de búsqueda'
          : 'Agrega tu primer proveedor para comenzar',
      actionLabel: hasSearch ? 'Limpiar búsqueda' : null,
      onAction: hasSearch ? _handleClearFilters : null,
    );
  }

}

