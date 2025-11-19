import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockActualController = TextEditingController();
  final _stockMinimoController = TextEditingController();
  
  String _selectedCategoria = 'Electrónicos';
  String? _selectedSupplierId;
  bool _isCheckingCodigo = false;
  String? _codigoError;
  bool _isLoadingSuppliers = false;

  // Categorías predefinidas
  final List<String> _categorias = [
    'Electrónicos',
    'Ropa',
    'Alimentos',
    'Hogar',
    'Deportes',
    'Libros',
    'Juguetes',
    'Herramientas',
    'Otros',
  ];

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    if (isEditing) {
      _loadProductData();
    }
  }

  Future<void> _loadSuppliers() async {
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    if (supplierProvider.suppliers.isEmpty && !supplierProvider.isLoading) {
      setState(() {
        _isLoadingSuppliers = true;
      });
      await supplierProvider.loadSuppliers();
      setState(() {
        _isLoadingSuppliers = false;
      });
      
      // Después de cargar proveedores, validar que el proveedor seleccionado existe
      if (isEditing && _selectedSupplierId != null) {
        final supplierExists = supplierProvider.suppliers.any(
          (s) => s.id == _selectedSupplierId,
        );
        if (!supplierExists) {
          // Si el proveedor no existe (fue eliminado), limpiar la selección
          setState(() {
            _selectedSupplierId = null;
          });
        }
      }
    }
  }

  void _loadProductData() {
    final product = widget.product!;
    _codigoController.text = product.codigo;
    _nombreController.text = product.nombre;
    _precioController.text = product.precio.toStringAsFixed(2);
    _stockActualController.text = product.stockActual.toString();
    _stockMinimoController.text = product.stockMinimo.toString();
    _selectedCategoria = product.categoria;
    
    // Establecer el proveedor solo si existe en la lista
    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);
    if (product.proveedorId != null) {
      final supplierExists = supplierProvider.suppliers.any(
        (s) => s.id == product.proveedorId,
      );
      if (supplierExists) {
        _selectedSupplierId = product.proveedorId;
      } else {
        // Si no existe, intentar cargarlo
        _selectedSupplierId = product.proveedorId;
        // Se validará después de cargar proveedores en _loadSuppliers
      }
    } else {
      _selectedSupplierId = null;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _precioController.dispose();
    _stockActualController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  Future<void> _checkCodigoUnico(String codigo) async {
    if (codigo.isEmpty) return;
    
    // Si estamos editando y el código no cambió, no verificar
    if (isEditing && codigo == widget.product!.codigo) {
      setState(() {
        _codigoError = null;
      });
      return;
    }

    setState(() {
      _isCheckingCodigo = true;
      _codigoError = null;
    });

    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final exists = await productProvider.checkCodigoExists(
      codigo,
      excludeId: isEditing ? widget.product!.id : null,
    );

    setState(() {
      _isCheckingCodigo = false;
      if (exists) {
        _codigoError = 'Este código ya está en uso';
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_codigoError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_codigoError!),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final productProvider = Provider.of<ProductProvider>(context, listen: false);

    try {
      final product = Product(
        id: isEditing ? widget.product!.id : '',
        codigo: _codigoController.text.trim().toUpperCase(),
        nombre: _nombreController.text.trim(),
        categoria: _selectedCategoria,
        precio: double.parse(_precioController.text),
        stockActual: int.parse(_stockActualController.text),
        stockMinimo: int.parse(_stockMinimoController.text),
        proveedorId: _selectedSupplierId,
        fechaCreacion: isEditing ? widget.product!.fechaCreacion : DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await productProvider.updateProduct(widget.product!.id, product);
      } else {
        success = await productProvider.createProduct(product);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing 
                  ? 'Producto actualizado correctamente' 
                  : 'Producto creado correctamente',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        final error = productProvider.errorMessage ?? 'Error al guardar el producto';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: const Color(0xFFEF4444),
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
        title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
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
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, child) {
              return LoadingOverlay(
                isLoading: productProvider.isLoading,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 24),
                        _buildFormFields(),
                        const SizedBox(height: 24),
                        if (productProvider.errorMessage != null)
                          _buildErrorMessage(productProvider.errorMessage!),
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
            child: Icon(
              isEditing ? FontAwesomeIcons.pencil : FontAwesomeIcons.plus,
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
                  isEditing ? 'Editar Producto' : 'Nuevo Producto',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing 
                      ? 'Modifica la información del producto'
                      : 'Completa los datos para crear un nuevo producto',
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

  Widget _buildFormFields() {
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
          // Código
          CustomTextField(
            controller: _codigoController,
            labelText: 'Código del Producto *',
            hintText: 'PROD-001',
            prefixIcon: FontAwesomeIcons.barcode,
            keyboardType: TextInputType.text,
            onChanged: (value) {
              // Convertir a mayúsculas
              final upperValue = value.toUpperCase();
              if (_codigoController.text != upperValue) {
                _codigoController.value = TextEditingValue(
                  text: upperValue,
                  selection: TextSelection.collapsed(offset: upperValue.length),
                );
              }
              
              // Verificar código único cuando cambia
              if (upperValue.trim().isNotEmpty) {
                _checkCodigoUnico(upperValue.trim());
              } else {
                setState(() {
                  _codigoError = null;
                });
              }
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El código es requerido';
              }
              if (value.trim().length < 3) {
                return 'El código debe tener al menos 3 caracteres';
              }
              if (_codigoError != null) {
                return _codigoError;
              }
              return null;
            },
            suffixIcon: _isCheckingCodigo
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          
          // Nombre
          CustomTextField(
            controller: _nombreController,
            labelText: 'Nombre del Producto *',
            hintText: 'Ej: Laptop Dell',
            prefixIcon: FontAwesomeIcons.box,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es requerido';
              }
              if (value.trim().length < 3) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Categoría
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          
          // Proveedor
          _buildSupplierDropdown(),
          const SizedBox(height: 20),
          
          // Precio
          CustomTextField(
            controller: _precioController,
            labelText: 'Precio *',
            hintText: '0.00',
            prefixIcon: FontAwesomeIcons.dollarSign,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El precio es requerido';
              }
              final precio = double.tryParse(value);
              if (precio == null) {
                return 'Ingresa un precio válido';
              }
              if (precio < 0) {
                return 'El precio no puede ser negativo';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Stock Actual
          CustomTextField(
            controller: _stockActualController,
            labelText: 'Stock Actual *',
            hintText: '0',
            prefixIcon: FontAwesomeIcons.boxesStacked,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El stock actual es requerido';
              }
              final stock = int.tryParse(value);
              if (stock == null) {
                return 'Ingresa un número válido';
              }
              if (stock < 0) {
                return 'El stock no puede ser negativo';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Stock Mínimo
          CustomTextField(
            controller: _stockMinimoController,
            labelText: 'Stock Mínimo *',
            hintText: '0',
            prefixIcon: FontAwesomeIcons.exclamationTriangle,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El stock mínimo es requerido';
              }
              final stock = int.tryParse(value);
              if (stock == null) {
                return 'Ingresa un número válido';
              }
              if (stock < 0) {
                return 'El stock mínimo no puede ser negativo';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categoría *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFD1D5DB),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategoria,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                FontAwesomeIcons.tag,
                size: 16,
                color: Color(0xFF6B7280),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            items: _categorias.map((categoria) {
              return DropdownMenuItem(
                value: categoria,
                child: Text(categoria),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategoria = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecciona una categoría';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierDropdown() {
    return Consumer<SupplierProvider>(
      builder: (context, supplierProvider, child) {
        final suppliers = supplierProvider.suppliers;
        
        // Validar que el proveedor seleccionado existe en la lista
        String? validSupplierId;
        if (_selectedSupplierId != null) {
          final supplierExists = suppliers.any(
            (s) => s.id == _selectedSupplierId,
          );
          if (supplierExists) {
            validSupplierId = _selectedSupplierId;
          } else {
            // Si no existe, limpiar la selección
            validSupplierId = null;
            // Actualizar el estado si es necesario
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedSupplierId != null) {
                setState(() {
                  _selectedSupplierId = null;
                });
              }
            });
          }
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proveedor (Opcional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD1D5DB),
                  width: 1,
                ),
              ),
              child: _isLoadingSuppliers
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Row(
                        children: [
                          const Icon(
                            FontAwesomeIcons.truck,
                            size: 16,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Cargando proveedores...',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : DropdownButtonFormField<String>(
                      value: validSupplierId,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          FontAwesomeIcons.truck,
                          size: 16,
                          color: Color(0xFF6B7280),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      hint: const Text('Sin proveedor'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Sin proveedor'),
                        ),
                        ...suppliers.map((supplier) {
                          return DropdownMenuItem<String>(
                            value: supplier.id,
                            child: Text(supplier.nombre),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedSupplierId = value;
                        });
                      },
                    ),
            ),
          ],
        );
      },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: isEditing ? 'Actualizar Producto' : 'Crear Producto',
          onPressed: _handleSubmit,
          icon: isEditing ? FontAwesomeIcons.floppyDisk : FontAwesomeIcons.check,
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
