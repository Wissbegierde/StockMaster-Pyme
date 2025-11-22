import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card_skeleton.dart';
import '../../widgets/category_chip.dart';
import 'product_form_screen.dart';
import 'product_detail_screen.dart';

class ProductsListScreen extends StatefulWidget {
  final bool showLowStockOnly;
  
  const ProductsListScreen({super.key, this.showLowStockOnly = false});

  @override
  State<ProductsListScreen> createState() => _ProductsListScreenState();
}

class _ProductsListScreenState extends State<ProductsListScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialLoad = true;
  bool _hasCompletedInitialLoad = false;
  ProductProvider? _productProvider;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Cargar productos y configurar listener después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _productProvider = Provider.of<ProductProvider>(context, listen: false);
        _productProvider!.addListener(_onProviderChanged);
        _loadProducts();
      }
    });
  }
  
  void _onProviderChanged() {
    if (!mounted || _productProvider == null) return;
    
    // Debug: Log del estado del provider
    debugPrint('[ProductsListScreen] Provider changed - isLoading: ${_productProvider!.isLoading}, products: ${_productProvider!.products.length}, _isInitialLoad: $_isInitialLoad, _hasCompletedInitialLoad: $_hasCompletedInitialLoad');
    
    // Solo procesar la carga inicial una vez
    if (!_hasCompletedInitialLoad && _isInitialLoad) {
      // Si la carga inicial terminó (no está cargando)
      if (!_productProvider!.isLoading) {
        debugPrint('[ProductsListScreen] Initial load completed');
        _hasCompletedInitialLoad = true;
        // Usar Future.microtask para evitar cambiar estado durante el build
        Future.microtask(() {
          if (mounted && _isInitialLoad) {
            setState(() {
              _isInitialLoad = false;
            });
            debugPrint('[ProductsListScreen] _isInitialLoad set to false');
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

  Future<void> _loadProducts() async {
    // Evitar llamadas simultáneas
    if (_isLoadingProducts) {
      debugPrint('[ProductsListScreen] _loadProducts already in progress, skipping...');
      return;
    }
    
    debugPrint('[ProductsListScreen] _loadProducts called, showLowStockOnly: ${widget.showLowStockOnly}');
    _isLoadingProducts = true;
    
    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Si se solicita mostrar solo productos con stock bajo, cargar esos
      if (widget.showLowStockOnly) {
        await productProvider.loadLowStockProducts();
      } else {
        // Cargar productos siempre (permite refresh)
        await productProvider.loadProducts();
      }
      debugPrint('[ProductsListScreen] _loadProducts completed');
    } finally {
      _isLoadingProducts = false;
    }
  }

  @override
  void dispose() {
    // Remover listener del provider si está disponible
    if (_productProvider != null) {
      _productProvider!.removeListener(_onProviderChanged);
      _productProvider = null;
    }
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.searchProducts(query);
  }

  void _handleCategoryFilter(String? category) {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.filterByCategory(category);
  }

  void _handleClearFilters() {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    productProvider.clearFilters();
    _searchController.clear();
  }

  Future<void> _handleDeleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Estás seguro de que quieres eliminar "${product.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      final success = await productProvider.deleteProduct(product.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${product.nombre}" eliminado'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(productProvider.errorMessage ?? 'Error al eliminar producto'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.showLowStockOnly ? 'Productos con Stock Bajo' : 'Productos'),
        backgroundColor: const Color(0xFF667eea),
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
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              if (productProvider.searchQuery.isNotEmpty || productProvider.selectedCategory != null) {
                return IconButton(
                  icon: const Icon(FontAwesomeIcons.xmark),
                  onPressed: _handleClearFilters,
                  tooltip: 'Limpiar filtros',
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
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Barra de búsqueda y filtros
              _buildSearchAndFilters(),
              // Lista de productos
              Expanded(
                child: Consumer<ProductProvider>(
                  builder: (context, productProvider, child) {
                    final isLoading = productProvider.isLoading;
                    final hasProducts = productProvider.products.isNotEmpty;
                    // Solo mostrar skeleton durante la carga inicial
                    final shouldShowSkeleton = _isInitialLoad && isLoading;
                    
                    debugPrint('[ProductsListScreen] Builder - isLoading: $isLoading, hasProducts: $hasProducts, _isInitialLoad: $_isInitialLoad, shouldShowSkeleton: $shouldShowSkeleton');
                    
                    if (shouldShowSkeleton) {
                      debugPrint('[ProductsListScreen] Showing skeleton (initial load)');
                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 3,
                        itemBuilder: (context, index) => const ProductCardSkeleton(),
                      );
                    }
                    
                    debugPrint('[ProductsListScreen] Showing products list');
                    return RefreshIndicator(
                      onRefresh: _loadProducts,
                      color: const Color(0xFF667eea),
                      child: _buildProductsList(productProvider),
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
                  const ProductFormScreen(),
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
          ).then((_) => _loadProducts());
        },
        backgroundColor: const Color(0xFF10B981),
        icon: const Icon(FontAwesomeIcons.plus),
        label: const Text('Agregar'),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            onChanged: _handleSearch,
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o código...',
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
          const SizedBox(height: 12),
          // Filtro por categoría
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              final categories = productProvider.categories;
              if (categories.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          category: 'Todas',
                          isSelected: productProvider.selectedCategory == null,
                          onTap: () => _handleCategoryFilter(null),
                        ),
                      );
                    }
                    
                    final category = categories[index - 1];
                    final isSelected = productProvider.selectedCategory == category;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        category: category,
                        isSelected: isSelected,
                        onTap: () => _handleCategoryFilter(isSelected ? null : category),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(ProductProvider productProvider) {
    final products = productProvider.filteredProducts;

    // Si no hay productos y no está cargando (y ya pasó la carga inicial), mostrar empty state
    // Asegurarse de que _isInitialLoad sea false para evitar parpadeo
    if (products.isEmpty && !productProvider.isLoading && !_isInitialLoad) {
      return _buildEmptyState(productProvider);
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, 0.1 * (index + 1)),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _animationController,
              curve: Interval(
                index * 0.1,
                0.5 + (index * 0.1),
                curve: Curves.easeOut,
              ),
            )),
            child: Hero(
              tag: 'product_${product.id}',
              child: ProductCard(
                product: product,
                onTap: () {
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ProductDetailScreen(productId: product.id),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return FadeTransition(
                          opacity: animation,
                          child: child,
                        );
                      },
                    ),
                  );
                },
                onEdit: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductFormScreen(product: product),
                    ),
                  ).then((_) => _loadProducts());
                },
                onDelete: () => _handleDeleteProduct(product),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ProductProvider productProvider) {
    final hasFilters = productProvider.searchQuery.isNotEmpty || productProvider.selectedCategory != null;
    
    return EmptyState(
      icon: hasFilters ? FontAwesomeIcons.magnifyingGlass : FontAwesomeIcons.boxesStacked,
      title: hasFilters ? 'No se encontraron productos' : 'No hay productos',
      message: hasFilters
          ? 'Intenta con otros filtros de búsqueda'
          : 'Agrega tu primer producto para comenzar',
      actionLabel: hasFilters ? 'Limpiar filtros' : null,
      onAction: hasFilters ? _handleClearFilters : null,
    );
  }
}

