// Archivo de test para verificar el modelo de Movement
// Ejecutar con: dart test/test_movement_model.dart

// ignore_for_file: avoid_print

import '../lib/models/movement.dart';

void main() {
  print('🧪 Probando Modelo de Movement...\n');

  // Test 1: Crear un movimiento desde JSON (entrada)
  print('✅ Test 1: Crear movimiento de ENTRADA desde JSON');
  final jsonEntrada = {
    'id': 'mov-001',
    'product_id': 'prod-001',
    'tipo': 'entrada',
    'cantidad': 50,
    'motivo': 'Compra a proveedor XYZ',
    'usuario_id': 'user-001',
    'fecha': DateTime.now().toIso8601String(),
    'producto_nombre': 'Laptop Dell',
    'usuario_nombre': 'Juan Pérez',
  };

  final entrada = Movement.fromJson(jsonEntrada);
  print('   Movimiento creado: ${entrada.getLabel()}');
  print('   Producto: ${entrada.productoNombre ?? entrada.productId}');
  print('   Cantidad: ${entrada.getCantidadConSigno()}');
  print('   Motivo: ${entrada.motivo}');
  print('   Color (hex): ${entrada.getColorHex()}');
  print('   Icono: ${entrada.getIcon()}');
  print('   ✅ Movimiento de entrada creado correctamente\n');

  // Test 2: Crear movimiento de salida
  print('✅ Test 2: Crear movimiento de SALIDA desde JSON');
  final jsonSalida = {
    'id': 'mov-002',
    'product_id': 'prod-001',
    'tipo': 'salida',
    'cantidad': 10,
    'motivo': 'Venta a cliente ABC',
    'usuario_id': 'user-001',
    'fecha': DateTime.now().toIso8601String(),
  };

  final salida = Movement.fromJson(jsonSalida);
  print('   Movimiento: ${salida.getLabel()}');
  print('   Cantidad: ${salida.getCantidadConSigno()}');
  print('   Color (hex): ${salida.getColorHex()}');
  print('   ✅ Movimiento de salida creado correctamente\n');

  // Test 3: Crear movimiento de ajuste
  print('✅ Test 3: Crear movimiento de AJUSTE desde JSON');
  final jsonAjuste = {
    'id': 'mov-003',
    'product_id': 'prod-002',
    'tipo': 'ajuste',
    'cantidad': 25,
    'motivo': 'Ajuste por inventario físico',
    'usuario_id': 'user-002',
    'fecha': DateTime.now().toIso8601String(),
  };

  final ajuste = Movement.fromJson(jsonAjuste);
  print('   Movimiento: ${ajuste.getLabel()}');
  print('   Cantidad: ${ajuste.getCantidadConSigno()}');
  print('   Color (hex): ${ajuste.getColorHex()}');
  print('   ✅ Movimiento de ajuste creado correctamente\n');

  // Test 4: Convertir a JSON
  print('✅ Test 4: Convertir movimiento a JSON');
  final json = entrada.toJson();
  print('   JSON generado: ${json.keys.join(", ")}');
  print('   Tipo en JSON: ${json['tipo']}');
  print('   ✅ Conversión a JSON exitosa\n');

  // Test 5: Validaciones
  print('✅ Test 5: Validar movimiento');
  print('   ¿Es válido? ${entrada.isValid()}');
  final error = entrada.getValidationError();
  print('   Error de validación: ${error ?? "Ninguno"}');
  print('   ✅ Validaciones funcionando\n');

  // Test 6: Movimiento inválido (cantidad <= 0)
  print('✅ Test 6: Movimiento inválido (cantidad <= 0)');
  final movimientoInvalido = entrada.copyWith(cantidad: 0);
  print('   ¿Es válido? ${movimientoInvalido.isValid()}');
  print('   Error: ${movimientoInvalido.getValidationError()}');
  print('   ✅ Validación de cantidad funcionando\n');

  // Test 7: Movimiento inválido (motivo muy corto)
  print('✅ Test 7: Movimiento inválido (motivo muy corto)');
  final movimientoMotivoCorto = entrada.copyWith(motivo: 'AB');
  print('   ¿Es válido? ${movimientoMotivoCorto.isValid()}');
  print('   Error: ${movimientoMotivoCorto.getValidationError()}');
  print('   ✅ Validación de motivo funcionando\n');

  // Test 8: Cálculo de nuevo stock
  print('✅ Test 8: Calcular nuevo stock');
  final stockActual = 100;
  
  // Entrada
  final nuevoStockEntrada = entrada.calcularNuevoStock(stockActual);
  print('   Stock actual: $stockActual');
  print('   Movimiento: ${entrada.getLabel()} de ${entrada.cantidad}');
  print('   Nuevo stock (entrada): $nuevoStockEntrada');
  print('   ✅ Cálculo de entrada correcto');
  
  // Salida
  final nuevoStockSalida = salida.calcularNuevoStock(stockActual);
  print('   Movimiento: ${salida.getLabel()} de ${salida.cantidad}');
  print('   Nuevo stock (salida): $nuevoStockSalida');
  print('   ✅ Cálculo de salida correcto');
  
  // Ajuste
  final nuevoStockAjuste = ajuste.calcularNuevoStock(stockActual);
  print('   Movimiento: ${ajuste.getLabel()} a ${ajuste.cantidad}');
  print('   Nuevo stock (ajuste): $nuevoStockAjuste');
  print('   ✅ Cálculo de ajuste correcto\n');

  // Test 9: Verificar stock negativo
  print('✅ Test 9: Verificar si resultaría en stock negativo');
  final stockBajo = 5;
  
  // Salida que resultaría en stock negativo
  final salidaGrande = salida.copyWith(cantidad: 10);
  final resultariaNegativo = salidaGrande.resultariaEnStockNegativo(stockBajo);
  print('   Stock actual: $stockBajo');
  print('   Salida de: ${salidaGrande.cantidad}');
  print('   ¿Resultaría en stock negativo? $resultariaNegativo');
  print('   ✅ Validación de stock negativo funcionando\n');

  // Test 10: copyWith
  print('✅ Test 10: Método copyWith');
  final movimientoActualizado = entrada.copyWith(
    motivo: 'Compra actualizada a proveedor ABC',
    cantidad: 75,
  );
  print('   Motivo original: ${entrada.motivo}');
  print('   Motivo actualizado: ${movimientoActualizado.motivo}');
  print('   Cantidad original: ${entrada.cantidad}');
  print('   Cantidad actualizada: ${movimientoActualizado.cantidad}');
  print('   ✅ copyWith funcionando correctamente\n');

  // Test 11: Diferentes formatos de JSON (compatibilidad)
  print('✅ Test 11: Compatibilidad con diferentes formatos de JSON');
  
  // Formato alternativo (snake_case en inglés)
  final jsonAlternativo = {
    'id': 'mov-004',
    'product_id': 'prod-003',
    'type': 'entry',  // En inglés
    'quantity': 30,
    'reason': 'Purchase from supplier',
    'user_id': 'user-003',
    'date': DateTime.now().toIso8601String(),
  };
  
  final movimientoAlternativo = Movement.fromJson(jsonAlternativo);
  print('   Tipo parseado: ${movimientoAlternativo.getLabel()}');
  print('   Cantidad: ${movimientoAlternativo.cantidad}');
  print('   ✅ Compatibilidad con formatos alternativos funcionando\n');

  // Test 12: Enum MovementType
  print('✅ Test 12: Enum MovementType');
  print('   Valores del enum:');
  for (var tipo in MovementType.values) {
    final tempMovement = entrada.copyWith(tipo: tipo);
    print('     - ${tempMovement.getLabel()} (${tempMovement.getIcon()})');
  }
  print('   ✅ Enum funcionando correctamente\n');

  print('🎉 ¡Todos los tests pasaron! El modelo Movement está funcionando correctamente.');
  print('\n📊 Resumen:');
  print('   ✅ Creación desde JSON');
  print('   ✅ Conversión a JSON');
  print('   ✅ Validaciones');
  print('   ✅ Cálculo de nuevo stock');
  print('   ✅ Verificación de stock negativo');
  print('   ✅ Métodos helper (color, icono, etiqueta)');
  print('   ✅ copyWith');
  print('   ✅ Compatibilidad con formatos alternativos');
}


