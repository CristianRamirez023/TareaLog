// ============================================================================
// SERVICIO DE SESIÓN ÚNICA
// ----------------------------------------------------------------------------
// Genera un ID único de sesión por dispositivo y lo guarda en Firestore.
// Si otro dispositivo inicia sesión con la misma cuenta, el primero lo detecta
// en tiempo real y cierra la sesión automáticamente.
// ============================================================================

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionService {
  // Clave para guardar el ID en SharedPreferences
  static const _keySessionId = 'session_id';

  // ID de la sesión actual (de este dispositivo)
  static String? _currentSessionId;

  // Suscripción al stream de Firestore
  static StreamSubscription<DocumentSnapshot>? _subscription;

  // ==========================================================================
  // REGISTRAR LA SESIÓN AL INICIAR
  // Se llama después del login/registro exitoso
  // ==========================================================================
  static Future<void> registerSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Obtener o generar el sessionId
    final prefs = await SharedPreferences.getInstance();
    _currentSessionId = prefs.getString(_keySessionId) ?? const Uuid().v4();
    await prefs.setString(_keySessionId, _currentSessionId!);

    // 2. Guardar en Firestore (bajo el documento del usuario)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'activeSessionId': _currentSessionId,
      'sessionUpdatedAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // ==========================================================================
  // ESCUCHAR CAMBIOS EN LA SESIÓN ACTIVA
  // Si el ID remoto cambia, significa que otro dispositivo inició sesión
  // ==========================================================================
  static void listenSessionChanges() {
    // Cancelar suscripción anterior si existe
    _subscription?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>?;
      final remoteId = data?['activeSessionId'] as String?;

      // Si el ID remoto existe, es diferente al nuestro y tenemos un ID local
      // → Otra sesión inició en otro dispositivo
      if (remoteId != null &&
          _currentSessionId != null &&
          remoteId != _currentSessionId) {
        _handleSessionReplaced();
      }
    });
  }

  // ==========================================================================
  // MANEJAR CIERRE DE SESIÓN POR OTRO DISPOSITIVO
  // ==========================================================================
  static Future<void> _handleSessionReplaced() async {
    // Cancelar la suscripción para evitar bucles
    await _subscription?.cancel();
    _subscription = null;

    // Cerrar sesión
    await FirebaseAuth.instance.signOut();

    // El StreamBuilder de main.dart detectará el cambio y cambiará a AuthScreen
  }

  // ==========================================================================
  // CANCELAR SUSCRIPCIÓN
  // Se llama en dispose() del widget
  // ==========================================================================
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}