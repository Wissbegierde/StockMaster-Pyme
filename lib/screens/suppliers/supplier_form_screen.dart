import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/supplier.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';

class SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;

  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _contactoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();

  bool get isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _loadSupplierData();
    }
  }

  void _loadSupplierData() {
    final supplier = widget.supplier!;
    _nombreController.text = supplier.nombre;
    _contactoController.text = supplier.contacto;
    _telefonoController.text = supplier.telefono;
    _emailController.text = supplier.email ?? '';
    _direccionController.text = supplier.direccion ?? '';
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _contactoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final supplierProvider = Provider.of<SupplierProvider>(context, listen: false);

    try {
      final supplier = Supplier(
        id: isEditing ? widget.supplier!.id : '',
        nombre: _nombreController.text.trim(),
        contacto: _contactoController.text.trim(),
        telefono: _telefonoController.text.trim(),
        email: _emailController.text.trim().isEmpty 
            ? null 
            : _emailController.text.trim(),
        direccion: _direccionController.text.trim().isEmpty 
            ? null 
            : _direccionController.text.trim(),
        fechaCreacion: isEditing ? widget.supplier!.fechaCreacion : DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      bool success;
      if (isEditing) {
        success = await supplierProvider.updateSupplier(widget.supplier!.id, supplier);
      } else {
        success = await supplierProvider.createSupplier(supplier);
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isEditing 
                        ? 'Proveedor actualizado correctamente' 
                        : 'Proveedor creado correctamente',
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        final error = supplierProvider.errorMessage ?? 'Error al guardar el proveedor';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(FontAwesomeIcons.exclamationTriangle, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                Expanded(child: Text(error)),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
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
        title: Text(isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor'),
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 0,
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
          child: Consumer<SupplierProvider>(
            builder: (context, supplierProvider, child) {
              return LoadingOverlay(
                isLoading: supplierProvider.isLoading,
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
                        if (supplierProvider.errorMessage != null)
                          _buildErrorMessage(supplierProvider.errorMessage!),
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
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              isEditing ? FontAwesomeIcons.pencil : FontAwesomeIcons.truck,
              color: const Color(0xFF8B5CF6),
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editar Proveedor' : 'Nuevo Proveedor',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEditing 
                      ? 'Modifica la información del proveedor'
                      : 'Completa los datos para crear un nuevo proveedor',
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
          // Nombre
          CustomTextField(
            controller: _nombreController,
            labelText: 'Nombre del Proveedor *',
            hintText: 'Ej: Proveedor ABC S.A.',
            prefixIcon: FontAwesomeIcons.building,
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
          
          // Contacto
          CustomTextField(
            controller: _contactoController,
            labelText: 'Contacto *',
            hintText: 'Ej: Juan Pérez',
            prefixIcon: FontAwesomeIcons.user,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El contacto es requerido';
              }
              if (value.trim().length < 3) {
                return 'El contacto debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Teléfono
          CustomTextField(
            controller: _telefonoController,
            labelText: 'Teléfono *',
            hintText: 'Ej: +1234567890',
            prefixIcon: FontAwesomeIcons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El teléfono es requerido';
              }
              if (value.trim().length < 8) {
                return 'El teléfono debe tener al menos 8 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Email (opcional)
          CustomTextField(
            controller: _emailController,
            labelText: 'Email (Opcional)',
            hintText: 'Ej: contacto@proveedor.com',
            prefixIcon: FontAwesomeIcons.envelope,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              // Email es opcional, pero si se proporciona debe ser válido
              if (value != null && value.trim().isNotEmpty) {
                final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                if (!emailRegex.hasMatch(value.trim())) {
                  return 'Ingresa un email válido';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Dirección (opcional)
          CustomTextField(
            controller: _direccionController,
            labelText: 'Dirección (Opcional)',
            hintText: 'Ej: Calle 123, Ciudad, País',
            prefixIcon: FontAwesomeIcons.locationDot,
            maxLines: 3,
            validator: (value) {
              // Dirección es opcional, no requiere validación
              return null;
            },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: isEditing ? 'Actualizar Proveedor' : 'Crear Proveedor',
          onPressed: _handleSubmit,
          icon: isEditing ? FontAwesomeIcons.floppyDisk : FontAwesomeIcons.check,
          backgroundColor: const Color(0xFF8B5CF6),
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
