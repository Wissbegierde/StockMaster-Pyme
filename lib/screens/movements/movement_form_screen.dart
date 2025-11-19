import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/movement.dart';
import '../../models/product.dart';
import '../../providers/movement_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class MovementFormScreen extends StatefulWidget {
  final Product? product; // Si se pasa un producto, se preselecciona

  const MovementFormScreen({super.key, this.product});

  @override
  State<MovementFormScreen> createState() => _MovementFormScreenState();
}

class _MovementFormScreenState extends State<MovementFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  
  Product? _selectedProduct;
  MovementType _selectedType = MovementType.entrada;
  bool _isLoadingProducts = false;

  @override
  void initState() {
    super.initState();
    // Si se pasa un producto, preseleccionarlo
    if (widget.product != null) {
      _selectedProduct = widget.product;
    }
    // Cargar productos si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProductsIfNeeded();
    });
  }

  Future<void> _loadProductsIfNeeded() async {
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    // Cargar productos si la lista está vacía y no está cargando
    if (productProvider.products.isEmpty && !productProvider.isLoading) {
      if (mounted) {
        setState(() => _isLoadingProducts = true);
      }
      try {
        await productProvider.loadProducts();
      } catch (e) {
        debugPrint('[MovementFormScreen] Error loading products: $e');
      } finally {
        if (mounted) {
          setState(() => _isLoadingProducts = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  int? get _stockResultante {
    if (_selectedProduct == null) return null;
    final stockActual = _selectedProduct!.stockActual;
    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    
    switch (_selectedType) {
      case MovementType.entrada:
        return stockActual + cantidad;
      case MovementType.salida:
        return stockActual - cantidad;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un producto'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo obtener el usuario actual'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final movementProvider = Provider.of<MovementProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    try {
      final cantidad = int.parse(_cantidadController.text);
      
      // Validar que no resulte en stock negativo
      final nuevoStock = _stockResultante!;
      if (nuevoStock < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'La cantidad excede el stock disponible (${_selectedProduct!.stockActual}). '
              'Por favor, ajusta la cantidad o registra una entrada primero.',
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      
      // Validar que el producto aún existe en la lista
      final productExists = productProvider.products.any(
        (p) => p.id == _selectedProduct!.id,
      );
      if (!productExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'El producto seleccionado ya no existe. Por favor, recarga la lista de productos.',
            ),
            backgroundColor: Color(0xFFEF4444),
            duration: Duration(seconds: 4),
          ),
        );
        // Recargar productos
        await productProvider.loadProducts();
        return;
      }

      final movement = Movement(
        id: '',
        productId: _selectedProduct!.id,
        tipo: _selectedType,
        cantidad: cantidad,
        motivo: _motivoController.text.trim(),
        usuarioId: currentUser.id,
        fecha: DateTime.now(),
        productoNombre: _selectedProduct!.nombre,
        usuarioNombre: currentUser.nombre,
      );

      // Validar el movimiento
      if (!movement.isValid()) {
        final error = movement.getValidationError();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Los datos del movimiento no son válidos'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }

      final success = await movementProvider.createMovement(
        movement,
        productProvider: productProvider,
      );

      if (success && mounted) {
        // Esperar un momento para que el ProductProvider se actualice
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Actualizar el producto seleccionado en el formulario desde el provider
        Product? updatedProduct;
        if (_selectedProduct != null) {
          updatedProduct = productProvider.products.firstWhere(
            (p) => p.id == _selectedProduct!.id,
            orElse: () => _selectedProduct!,
          );
          setState(() {
            _selectedProduct = updatedProduct;
          });
          debugPrint('[MovementFormScreen] Producto actualizado: Stock nuevo=${updatedProduct.stockActual}');
        }
        
        final nuevoStock = updatedProduct?.stockActual ?? _stockResultante ?? 0;
        final stockAnterior = nuevoStock - (_selectedType == MovementType.entrada ? cantidad : -cantidad);
        final tipoLabel = _selectedType == MovementType.entrada ? 'Entrada' : 'Salida';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.circleCheck,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Movimiento registrado exitosamente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$tipoLabel de $cantidad unidades. Stock: $stockAnterior → $nuevoStock',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        final error = movementProvider.errorMessage ?? 'Error al registrar el movimiento';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.triangleExclamation,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
        title: const Text('Registrar Movimiento'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
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
          child: Consumer2<MovementProvider, ProductProvider>(
            builder: (context, movementProvider, productProvider, child) {
              // Actualizar el producto seleccionado si cambió en el provider
              if (_selectedProduct != null) {
                final updatedProduct = productProvider.products.firstWhere(
                  (p) => p.id == _selectedProduct!.id,
                  orElse: () => _selectedProduct!,
                );
                // Solo actualizar si el stock cambió (para evitar rebuilds innecesarios)
                if (updatedProduct.stockActual != _selectedProduct!.stockActual) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedProduct = updatedProduct;
                      });
                    }
                  });
                }
              }
              
              return LoadingOverlay(
                isLoading: movementProvider.isLoading || _isLoadingProducts,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildTypeSelector(),
                        const SizedBox(height: 24),
                        _buildFormFields(productProvider),
                        const SizedBox(height: 24),
                        if (_selectedProduct != null) _buildStockInfo(),
                        const SizedBox(height: 24),
                        if (movementProvider.errorMessage != null)
                          _buildErrorMessage(movementProvider.errorMessage!),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              FontAwesomeIcons.arrowRightArrowLeft,
              color: Color(0xFF667eea),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrar Movimiento',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Registra una entrada o salida de inventario',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
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
          const Text(
            'Tipo de Movimiento *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<MovementType>(
            segments: const [
              ButtonSegment<MovementType>(
                value: MovementType.entrada,
                label: Text('Entrada'),
                icon: Icon(FontAwesomeIcons.arrowDown, size: 14),
              ),
              ButtonSegment<MovementType>(
                value: MovementType.salida,
                label: Text('Salida'),
                icon: Icon(FontAwesomeIcons.arrowUp, size: 14),
              ),
            ],
            selected: {_selectedType},
            onSelectionChanged: (Set<MovementType> newSelection) {
              setState(() {
                _selectedType = newSelection.first;
                // Limpiar cantidad cuando cambia el tipo
                _cantidadController.clear();
              });
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              selectedBackgroundColor: _getTypeColor(_selectedType),
              selectedForegroundColor: Colors.white,
              foregroundColor: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(MovementType type) {
    switch (type) {
      case MovementType.entrada:
        return const Color(0xFF10B981); // Verde
      case MovementType.salida:
        return const Color(0xFFEF4444); // Rojo
    }
  }

  Widget _buildFormFields(ProductProvider productProvider) {
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de Producto
          _buildProductSelector(productProvider),
          const SizedBox(height: 20),
          
          // Cantidad
          CustomTextField(
            controller: _cantidadController,
            labelText: 'Cantidad *',
            hintText: '0',
            prefixIcon: FontAwesomeIcons.hashtag,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() {}); // Actualizar para mostrar stock resultante
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'La cantidad es requerida';
              }
              final cantidad = int.tryParse(value);
              if (cantidad == null) {
                return 'Ingresa un número válido';
              }
              if (cantidad <= 0) {
                return 'La cantidad debe ser mayor a 0';
              }
              
              // Validar stock para salidas
              if (_selectedProduct != null && _selectedType == MovementType.salida) {
                if (cantidad > _selectedProduct!.stockActual) {
                  return 'La cantidad excede el stock disponible (${_selectedProduct!.stockActual})';
                }
              }
              
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Motivo
          CustomTextField(
            controller: _motivoController,
            labelText: 'Motivo *',
            hintText: 'Ej: Compra de proveedor, Venta a cliente, Corrección de inventario...',
            prefixIcon: FontAwesomeIcons.noteSticky,
            keyboardType: TextInputType.multiline,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El motivo es requerido';
              }
              if (value.trim().length < 3) {
                return 'El motivo debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector(ProductProvider productProvider) {
    // Si no hay productos y no está cargando, mostrar mensaje
    if (productProvider.products.isEmpty && !productProvider.isLoading && !_isLoadingProducts) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Producto *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  FontAwesomeIcons.exclamationTriangle,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay productos disponibles. Crea un producto primero.',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Producto *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Product>(
          value: _selectedProduct != null
              ? productProvider.products.firstWhere(
                  (p) => p.id == _selectedProduct!.id,
                  orElse: () => _selectedProduct!,
                )
              : null,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              FontAwesomeIcons.box,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD1D5DB),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD1D5DB),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF667eea),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          hint: const Text('Selecciona un producto'),
          isExpanded: true,
          items: productProvider.products.map((product) {
            return DropdownMenuItem<Product>(
              value: product,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${product.nombre} (${product.codigo}) - Stock: ${product.stockActual}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (product.tieneStockBajo)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Bajo',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: productProvider.products.isEmpty
              ? null
              : (Product? product) {
                  setState(() {
                    _selectedProduct = product;
                    _cantidadController.clear(); // Limpiar cantidad al cambiar producto
                  });
                },
          validator: (value) {
            if (value == null) {
              return 'Selecciona un producto';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStockInfo() {
    final stockActual = _selectedProduct!.stockActual;
    final stockResultante = _stockResultante ?? stockActual;
    final diferencia = stockResultante - stockActual;
    final isPositive = diferencia > 0;
    final isNegative = diferencia < 0;

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
              Icon(
                FontAwesomeIcons.chartLine,
                size: 20,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 8),
              const Text(
                'Información de Stock',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stock Actual',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$stockActual',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              if (_cantidadController.text.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      diferencia > 0 ? '+$diferencia' : '$diferencia',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isPositive
                            ? const Color(0xFF10B981)
                            : isNegative
                                ? const Color(0xFFEF4444)
                                : Colors.grey[700],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ],
                ),
              if (_cantidadController.text.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Stock Resultante',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$stockResultante',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: stockResultante < _selectedProduct!.stockMinimo
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Advertencia si el stock resultante sería negativo
          if (stockResultante < 0)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.triangleExclamation,
                    size: 16,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '⚠️ Esta salida resultaría en stock negativo. No se puede registrar.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          // Advertencia si el stock resultante estaría por debajo del mínimo
          else if (stockResultante < _selectedProduct!.stockMinimo)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    FontAwesomeIcons.exclamationTriangle,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El stock resultante estará por debajo del mínimo (${_selectedProduct!.stockMinimo})',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            FontAwesomeIcons.exclamationTriangle,
            color: Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    // Verificar si el stock resultante sería negativo
    final stockResultante = _stockResultante;
    final isStockNegativo = stockResultante != null && stockResultante < 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: 'Registrar Movimiento',
          onPressed: isStockNegativo ? null : _handleSubmit,
          icon: FontAwesomeIcons.check,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

