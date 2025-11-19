import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/product.dart';
import '../../models/supplier.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import 'product_form_screen.dart';
import 'products_list_screen.dart';
import '../movements/movement_form_screen.dart';
import '../suppliers/supplier_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    
    await productProvider.loadProductById(widget.productId);
    
    // Cargar proveedores si el producto tiene un proveedor y no están cargados
    final product = productProvider.selectedProduct;
    if (product != null && product.proveedorId != null) {
      if (supplierProvider.suppliers.isEmpty && !supplierProvider.isLoading) {
        await supplierProvider.loadSuppliers();
      }
      // Cargar el proveedor específico si no está en la lista
      final supplierExists = supplierProvider.suppliers.any(
        (s) => s.id == product.proveedorId,
      );
      if (!supplierExists && supplierProvider.selectedSupplier?.id != product.proveedorId) {
        await supplierProvider.loadSupplierById(product.proveedorId!);
      }
    }
  }

  Future<void> _handleDelete() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final product = productProvider.selectedProduct;

    if (product == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de que quieres eliminar este producto?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Código: ${product.codigo}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
      final success = await productProvider.deleteProduct(product.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${product.nombre}" eliminado correctamente'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        // Regresar a la lista
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const ProductsListScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              productProvider.errorMessage ?? 'Error al eliminar producto',
            ),
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
        title: const Text('Detalle de Producto'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(FontAwesomeIcons.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              final product = productProvider.selectedProduct;
              // Siempre mostrar el menú, incluso si el producto es null (mostrará opciones básicas)
              return PopupMenuButton<String>(
                icon: const Icon(FontAwesomeIcons.ellipsisVertical),
                onSelected: (value) {
                  if (value == 'edit' && product != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProductFormScreen(product: product),
                      ),
                    ).then((_) => _loadProduct());
                  } else if (value == 'delete' && product != null) {
                    _handleDelete();
                  }
                },
                itemBuilder: (context) {
                  if (product == null) {
                    return [
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(FontAwesomeIcons.arrowRotateRight, size: 16),
                            SizedBox(width: 8),
                            Text('Recargar'),
                          ],
                        ),
                      ),
                    ];
                  }
                  return [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.pencil, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.trash, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
              );
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
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              // El LoadingOverlay solo cubre el body, no el AppBar
              return Stack(
                children: [
                  productProvider.selectedProduct == null
                      ? _buildNotFound()
                      : _buildProductDetail(productProvider.selectedProduct!),
                  if (productProvider.isLoading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.boxOpen,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Producto no encontrado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El producto que buscas no existe o fue eliminado',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(FontAwesomeIcons.arrowLeft),
              label: const Text('Volver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667eea),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetail(Product product) {
    final isLowStock = product.tieneStockBajo;
    final stockColor = isLowStock ? const Color(0xFFEF4444) : const Color(0xFF10B981);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header con nombre y código
          _buildHeaderCard(product, stockColor, isLowStock),
          const SizedBox(height: 16),
          
          // Información básica
          _buildInfoSection(
            title: 'Información Básica',
            icon: FontAwesomeIcons.circleInfo,
            children: [
              _buildInfoRow('Código', product.codigo, FontAwesomeIcons.barcode),
              _buildInfoRow('Nombre', product.nombre, FontAwesomeIcons.box),
              _buildInfoRow('Categoría', product.categoria, FontAwesomeIcons.tag),
              if (product.proveedorId != null) _buildSupplierRow(product.proveedorId!),
            ],
          ),
          const SizedBox(height: 16),
          
          // Información de stock
          _buildInfoSection(
            title: 'Stock',
            icon: FontAwesomeIcons.boxesStacked,
            children: [
              _buildStockCard(product, stockColor, isLowStock),
            ],
          ),
          const SizedBox(height: 16),
          
          // Información financiera
          _buildInfoSection(
            title: 'Información Financiera',
            icon: FontAwesomeIcons.dollarSign,
            children: [
              _buildInfoRow(
                'Precio Unitario',
                '\$${product.precio.toStringAsFixed(2)}',
                FontAwesomeIcons.moneyBill,
              ),
              _buildInfoRow(
                'Valor Total Inventario',
                '\$${product.valorInventario.toStringAsFixed(2)}',
                FontAwesomeIcons.calculator,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Fechas
          _buildInfoSection(
            title: 'Fechas',
            icon: FontAwesomeIcons.calendar,
            children: [
              _buildInfoRow(
                'Fecha de Creación',
                dateFormat.format(product.fechaCreacion),
                FontAwesomeIcons.clock,
              ),
              _buildInfoRow(
                'Última Actualización',
                dateFormat.format(product.fechaActualizacion),
                FontAwesomeIcons.clockRotateLeft,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Botones de acción
          _buildActionButtons(product),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Product product, Color stockColor, bool isLowStock) {
    return Container(
      padding: const EdgeInsets.all(24),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  FontAwesomeIcons.box,
                  color: const Color(0xFF667eea),
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nombre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.codigo,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: stockColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: stockColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLowStock ? FontAwesomeIcons.exclamationTriangle : FontAwesomeIcons.checkCircle,
                      size: 14,
                      color: stockColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      product.estadoStock,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: stockColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
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
              Icon(icon, size: 20, color: const Color(0xFF667eea)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              size: 18,
              color: const Color(0xFF667eea),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierRow(String supplierId) {
    return Consumer<SupplierProvider>(
      builder: (context, supplierProvider, child) {
        // Buscar el proveedor en la lista
        Supplier? supplier;
        try {
          supplier = supplierProvider.suppliers.firstWhere(
            (s) => s.id == supplierId,
          );
        } catch (e) {
          // Si no está en la lista, intentar cargarlo
          if (supplierProvider.selectedSupplier?.id == supplierId) {
            supplier = supplierProvider.selectedSupplier;
          } else {
            // Si no está disponible, mostrar mensaje
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.truck,
                      size: 18,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Proveedor',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cargando...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        }

        if (supplier == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SupplierDetailScreen(supplierId: supplierId),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.truck,
                    size: 18,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proveedor',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              supplier.nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          Icon(
                            FontAwesomeIcons.chevronRight,
                            size: 14,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStockCard(Product product, Color stockColor, bool isLowStock) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: stockColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: stockColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: _buildStockInfo(
                  'Stock Actual',
                  product.stockActual.toString(),
                  stockColor,
                  FontAwesomeIcons.boxesStacked,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: stockColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStockInfo(
                  'Stock Mínimo',
                  product.stockMinimo.toString(),
                  Colors.grey,
                  FontAwesomeIcons.exclamationTriangle,
                ),
              ),
            ],
          ),
          if (isLowStock) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 14,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      product.stockActual < product.stockMinimo
                          ? '¡Atención! El stock está por debajo del mínimo'
                          : '¡Atención! El stock está en el mínimo',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStockInfo(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => MovementFormScreen(product: product),
              ),
            ).then((_) => _loadProduct());
          },
          icon: const Icon(FontAwesomeIcons.arrowRightArrowLeft),
          label: const Text('Registrar Movimiento'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductFormScreen(product: product),
              ),
            ).then((_) => _loadProduct());
          },
          icon: const Icon(FontAwesomeIcons.pencil),
          label: const Text('Editar Producto'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _handleDelete,
          icon: const Icon(FontAwesomeIcons.trash),
          label: const Text('Eliminar Producto'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
