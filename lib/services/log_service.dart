// ============================================================================
// SERVICIO DE LOGS
// ----------------------------------------------------------------------------
// Registra eventos importantes en Firestore para auditoría y análisis.
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LogService {
  // ==========================================================================
  // 📋 CONSTANTES DE ACCIONES
  // ==========================================================================
  static const String actionLogin = 'LOGIN';
  static const String actionLogout = 'LOGOUT';
  static const String actionLogoutInactivity = 'LOGOUT_INACTIVITY';
  static const String actionTaskCreate = 'TASK_CREATE';
  static const String actionTaskDelete = 'TASK_DELETE';
  static const String actionTaskComplete = 'TASK_COMPLETE';
  static const String actionTaskVerify = 'TASK_VERIFY';
  static const String actionStudentLink = 'STUDENT_LINK';
  static const String actionStudentUnlink = 'STUDENT_UNLINK';
  static const String actionBackup = 'BACKUP_CREATE';
  static const String actionRestore = 'BACKUP_RESTORE';
  static const String actionError = 'ERROR';

  // ==========================================================================
  // 📝 REGISTRAR LOG
  // ==========================================================================
  static Future<void> log({
    required String action,
    String? details,
    String level = 'INFO',
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // No logear si no hay usuario

      // Obtener datos del usuario (rol y nombre)
      String userRole = 'Desconocido';
      String userEmail = user.email ?? 'sin-email';

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          userRole = userDoc.data()?['role'] ?? 'Desconocido';
        }
      } catch (e) {
        // Si falla, seguimos con los datos básicos
        debugPrint('Error al obtener rol: $e');
      }

      // Guardar log en Firestore
      await FirebaseFirestore.instance.collection('logs').add({
        'userId': user.uid,
        'userEmail': userEmail,
        'userRole': userRole,
        'action': action,
        'details': details ?? '',
        'level': level,
        'timestamp': Timestamp.now(),
      });

      if (kDebugMode) {
        debugPrint('📝 LOG: [$level] $action - ${details ?? ""}');
      }
    } catch (e) {
      // No queremos que un error de log rompa la app
      debugPrint('❌ Error al guardar log: $e');
    }
  }

  // ==========================================================================
  // 🔧 HELPERS ESPECÍFICOS
  // ==========================================================================

  // Login
  static Future<void> logLogin() async {
    await log(action: actionLogin, details: 'Inicio de sesión exitoso');
  }

  // Logout manual
  static Future<void> logLogout() async {
    await log(action: actionLogout, details: 'Cierre de sesión manual');
  }

  // Logout por inactividad
  static Future<void> logLogoutInactivity() async {
    await log(
      action: actionLogoutInactivity,
      details: 'Cierre de sesión por 5 min de inactividad',
    );
  }

  // Crear tarea
  static Future<void> logTaskCreate(String taskTitle) async {
    await log(
      action: actionTaskCreate,
      details: 'Tarea creada: "$taskTitle"',
    );
  }

  // Eliminar tarea
  static Future<void> logTaskDelete(String taskTitle) async {
    await log(
      action: actionTaskDelete,
      details: 'Tarea eliminada: "$taskTitle"',
    );
  }

  // Marcar/desmarcar tarea
  static Future<void> logTaskComplete(
      String taskTitle, bool isCompleted) async {
    await log(
      action: actionTaskComplete,
      details:
          'Tarea "${taskTitle}" ${isCompleted ? "marcada" : "desmarcada"} como completada',
    );
  }

  // Evaluar tarea (aprobar/rechazar)
  static Future<void> logTaskVerify(
      String taskTitle, String status) async {
    await log(
      action: actionTaskVerify,
      details: 'Tarea "$taskTitle" evaluada como: $status',
    );
  }

  // Vincular estudiante
  static Future<void> logStudentLink(String studentName) async {
    await log(
      action: actionStudentLink,
      details: 'Estudiante vinculado: $studentName',
    );
  }

  // Crear backup
  static Future<void> logBackup() async {
    await log(
      action: actionBackup,
      details: 'Backup JSON generado',
    );
  }

  // Restaurar backup
  static Future<void> logRestore(int tasksRestored) async {
    await log(
      action: actionRestore,
      details: 'Backup restaurado: $tasksRestored tareas recuperadas',
    );
  }

  // Error
  static Future<void> logError(String error) async {
    await log(
      action: actionError,
      details: error,
      level: 'ERROR',
    );
  }
}