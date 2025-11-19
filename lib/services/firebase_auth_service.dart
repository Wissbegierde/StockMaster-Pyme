import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import 'interfaces/auth_service_interface.dart';

/// Servicio de autenticación usando Firebase Auth
/// Implementa AuthServiceInterface para facilitar migración desde HTTP
class FirebaseAuthService implements AuthServiceInterface {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String userKey = 'user_data';

  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Obtener datos adicionales del usuario desde Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        User? user;
        final now = DateTime.now();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final createdAt = userData['fecha_creacion'] != null
              ? (userData['fecha_creacion'] as Timestamp).toDate()
              : now;
          final updatedAt = userData['fecha_actualizacion'] != null
              ? (userData['fecha_actualizacion'] as Timestamp).toDate()
              : now;
          user = User(
            id: userCredential.user!.uid,
            nombre: userData['nombre'] ?? userCredential.user!.displayName ?? 'Usuario',
            email: userCredential.user!.email ?? email,
            rol: userData['rol'] ?? 'empleado',
            createdAt: createdAt,
            updatedAt: updatedAt,
          );
        } else {
          // Si no existe en Firestore, crear usuario básico
          user = User(
            id: userCredential.user!.uid,
            nombre: userCredential.user!.displayName ?? 'Usuario',
            email: userCredential.user!.email ?? email,
            rol: 'empleado',
            createdAt: now,
            updatedAt: now,
          );
        }

        // Guardar datos del usuario
        await _saveUserData(user);

        final token = await getToken();
        return AuthResponse(
          success: true,
          message: 'Inicio de sesión exitoso',
          user: user,
          token: token ?? '',
        );
      } else {
        return AuthResponse(
          success: false,
          message: 'Error al iniciar sesión',
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error al iniciar sesión';
      switch (e.code) {
        case 'user-not-found':
          message = 'No existe una cuenta con este correo';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          message = 'Correo electrónico inválido';
          break;
        case 'user-disabled':
          message = 'Esta cuenta ha sido deshabilitada';
          break;
        case 'too-many-requests':
          message = 'Demasiados intentos. Intenta más tarde';
          break;
        default:
          message = e.message ?? 'Error al iniciar sesión';
      }
      return AuthResponse(success: false, message: message);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  @override
  Future<AuthResponse> register(String nombre, String email, String password, String rol) async {
    try {
      // Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Actualizar el perfil con el nombre
        await userCredential.user!.updateDisplayName(nombre);

        // Guardar datos adicionales en Firestore
        final now = DateTime.now();
        final user = User(
          id: userCredential.user!.uid,
          nombre: nombre,
          email: email,
          rol: rol,
          createdAt: now,
          updatedAt: now,
        );

        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'nombre': nombre,
          'email': email,
          'rol': rol,
          'fecha_creacion': FieldValue.serverTimestamp(),
          'fecha_actualizacion': FieldValue.serverTimestamp(),
        });

        // Enviar correo de verificación después del registro
        // Agregar un pequeño delay para evitar bloqueos de Firebase
        try {
          debugPrint('[FirebaseAuthService] Esperando 2 segundos antes de enviar correo de verificación...');
          await Future.delayed(const Duration(seconds: 2));
          
          debugPrint('[FirebaseAuthService] Enviando correo de verificación después del registro');
          debugPrint('[FirebaseAuthService] Usuario: ${userCredential.user!.uid}, Email: ${userCredential.user!.email}');
          
          // Usar ActionCodeSettings para que el enlace abra la app directamente
          final actionCodeSettings = ActionCodeSettings(
            url: 'https://${_auth.app.options.projectId}.firebaseapp.com/__/auth/action',
            handleCodeInApp: true, // Abrir en la app en lugar del navegador
            androidPackageName: 'com.example.inventario',
            iOSBundleId: null,
          );
          
          await userCredential.user!.sendEmailVerification(actionCodeSettings);
          debugPrint('[FirebaseAuthService] ✅ Correo de verificación enviado exitosamente a: ${userCredential.user!.email}');
        } on FirebaseAuthException catch (e) {
          debugPrint('[FirebaseAuthService] ❌ Error Firebase al enviar correo después del registro:');
          debugPrint('[FirebaseAuthService] Código: ${e.code}');
          debugPrint('[FirebaseAuthService] Mensaje: ${e.message}');
          debugPrint('[FirebaseAuthService] Email: ${userCredential.user!.email}');
          // Continuar de todas formas, el usuario puede reenviar después
        } catch (e) {
          debugPrint('[FirebaseAuthService] ❌ Error general al enviar correo: $e');
          // Continuar de todas formas, el usuario puede reenviar después
        }

        // Guardar datos del usuario localmente
        await _saveUserData(user);

        return AuthResponse(
          success: true,
          message: 'Registro exitoso. Se ha enviado un correo de verificación.',
          user: user,
          token: await getToken() ?? '',
        );
      } else {
        return AuthResponse(
          success: false,
          message: 'Error al registrarse',
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error al registrarse';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Este correo ya está registrado';
          break;
        case 'invalid-email':
          message = 'Correo electrónico inválido';
          break;
        case 'weak-password':
          message = 'La contraseña es muy débil';
          break;
        default:
          message = e.message ?? 'Error al registrarse';
      }
      return AuthResponse(success: false, message: message);
    } catch (e) {
      return AuthResponse(
        success: false,
        message: 'Error inesperado: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _clearUserData();
    } catch (e) {
      throw Exception('Error al cerrar sesión: ${e.toString()}');
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
  }

  @override
  Future<String?> getToken() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        // Intentar obtener desde SharedPreferences como fallback
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString(userKey);
        if (userJson != null) {
          try {
            final userData = jsonDecode(userJson) as Map<String, dynamic>;
            return User.fromJson(userData);
          } catch (_) {
            return null;
          }
        }
        return null;
      }

      // Obtener datos adicionales desde Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      final now = DateTime.now();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final createdAt = userData['fecha_creacion'] != null
            ? (userData['fecha_creacion'] as Timestamp).toDate()
            : now;
        final updatedAt = userData['fecha_actualizacion'] != null
            ? (userData['fecha_actualizacion'] as Timestamp).toDate()
            : now;
        
        return User(
          id: firebaseUser.uid,
          nombre: userData['nombre'] ?? firebaseUser.displayName ?? 'Usuario',
          email: firebaseUser.email ?? '',
          rol: userData['rol'] ?? 'empleado',
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      } else {
        // Si no existe en Firestore, crear usuario básico
        return User(
          id: firebaseUser.uid,
          nombre: firebaseUser.displayName ?? 'Usuario',
          email: firebaseUser.email ?? '',
          rol: 'empleado',
          createdAt: now,
          updatedAt: now,
        );
      }
    } catch (e) {
      // Fallback a SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(userKey);
      if (userJson != null) {
        try {
          final userData = jsonDecode(userJson) as Map<String, dynamic>;
          return User.fromJson(userData);
        } catch (_) {
          return null;
        }
      }
      return null;
    }
  }

  @override
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  @override
  bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  /// Guardar datos del usuario localmente
  Future<void> _saveUserData(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(userKey, jsonEncode(user.toJson()));
  }

  /// Limpiar datos del usuario
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(userKey);
  }

  @override
  Future<bool> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      debugPrint('[FirebaseAuthService] ========== sendEmailVerification ==========');
      debugPrint('[FirebaseAuthService] Usuario ID: ${user?.uid}');
      debugPrint('[FirebaseAuthService] Email: ${user?.email}');
      debugPrint('[FirebaseAuthService] Email verificado: ${user?.emailVerified}');
      debugPrint('[FirebaseAuthService] Proyecto: ${_auth.app.options.projectId}');
      
      if (user == null) {
        debugPrint('[FirebaseAuthService] ❌ No hay usuario autenticado');
        throw Exception('No hay usuario autenticado. Por favor, inicia sesión primero.');
      }
      
      if (user.emailVerified) {
        debugPrint('[FirebaseAuthService] ✅ El correo ya está verificado');
        return true; // Ya está verificado, no es un error
      }
      
      if (user.email == null || user.email!.isEmpty) {
        debugPrint('[FirebaseAuthService] ❌ El usuario no tiene correo electrónico');
        throw Exception('El usuario no tiene un correo electrónico asociado');
      }
      
      // Recargar el usuario para obtener el estado más reciente
      await user.reload();
      final reloadedUser = _auth.currentUser;
      if (reloadedUser?.emailVerified == true) {
        debugPrint('[FirebaseAuthService] ✅ El correo ya está verificado (después de recargar)');
        return true;
      }
      
      debugPrint('[FirebaseAuthService] Preparando envío de correo de verificación...');
      debugPrint('[FirebaseAuthService] Email destino: ${user.email}');
      
      // Usar ActionCodeSettings para que el enlace abra la app directamente
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://${_auth.app.options.projectId}.firebaseapp.com/__/auth/action',
        handleCodeInApp: true, // Abrir en la app en lugar del navegador
        androidPackageName: 'com.example.inventario',
        iOSBundleId: null,
      );
      
      debugPrint('[FirebaseAuthService] ActionCodeSettings configurado');
      debugPrint('[FirebaseAuthService] URL: ${actionCodeSettings.url}');
      debugPrint('[FirebaseAuthService] handleCodeInApp: ${actionCodeSettings.handleCodeInApp}');
      debugPrint('[FirebaseAuthService] Android Package: ${actionCodeSettings.androidPackageName}');
      
      await user.sendEmailVerification(actionCodeSettings);
      debugPrint('[FirebaseAuthService] ✅ Correo de verificación enviado exitosamente a: ${user.email}');
      debugPrint('[FirebaseAuthService] ============================================');
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('[FirebaseAuthService] ❌ Error Firebase Auth:');
      debugPrint('[FirebaseAuthService] Código: ${e.code}');
      debugPrint('[FirebaseAuthService] Mensaje: ${e.message}');
      debugPrint('[FirebaseAuthService] Email: ${_auth.currentUser?.email}');
      debugPrint('[FirebaseAuthService] ============================================');
      
      String errorMessage = 'Error al enviar correo de verificación';
      
      switch (e.code) {
        case 'too-many-requests':
          errorMessage = 'Firebase ha bloqueado temporalmente el envío de correos desde este dispositivo debido a demasiados intentos. Por favor, espera 15-30 minutos antes de intentar de nuevo. Si es la primera vez, revisa tu bandeja de entrada y spam.';
          break;
        case 'user-not-found':
          errorMessage = 'Usuario no encontrado. Por favor, inicia sesión de nuevo.';
          break;
        case 'invalid-email':
          errorMessage = 'Correo electrónico inválido.';
          break;
        case 'network-request-failed':
          errorMessage = 'Error de conexión. Verifica tu conexión a internet.';
          break;
        default:
          errorMessage = 'Error: ${e.message ?? e.code}';
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('[FirebaseAuthService] ❌ Error general: $e');
      debugPrint('[FirebaseAuthService] Tipo de error: ${e.runtimeType}');
      debugPrint('[FirebaseAuthService] ============================================');
      throw Exception('Error al enviar correo de verificación: ${e.toString()}');
    }
  }

  @override
  Future<bool> verifyEmail(String code) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Firebase no usa códigos para verificación de correo
        // En su lugar, el usuario hace clic en el enlace del correo
        // Este método verifica si el correo ya fue verificado
        await user.reload();
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      throw Exception('Error al verificar correo: ${e.toString()}');
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload(); // Recargar para obtener el estado más reciente
        return user.emailVerified;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

