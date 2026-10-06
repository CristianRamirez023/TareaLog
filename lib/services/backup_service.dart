// ============================================================================
// SERVICIO DE BACKUP Y RESTAURACIÓN
// ----------------------------------------------------------------------------
// Permite exportar TODOS los datos del usuario a un archivo JSON y restaurarlos
// después en caso de pérdida o migración a otro dispositivo.
// ============================================================================

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class BackupService {
  // ==========================================================================
  // 🔧 HELPER: CONVERTIR TIMESTAMPS A STRING
  // Recorre un Map y convierte todos los Timestamp a String ISO 8601
  // ==========================================================================
  static Map<String, dynamic> _convertTimestamps(
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic> converted = {};

    data.forEach((key, value) {
      if (value is Timestamp) {
        // Convertir a ISO 8601 para poder serializar
        converted[key] = value.toDate().toIso8601String();
      } else if (value is Map<String, dynamic>) {
        // Recursivo para Maps anidados
        converted[key] = _convertTimestamps(value);
      } else if (value is List) {
        // Para listas, verificar si tienen Timestamps
        converted[key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map<String, dynamic>) {
            return _convertTimestamps(item);
          }
          return item;
        }).toList();
      } else {
        converted[key] = value;
      }
    });

    return converted;
  }

  // ==========================================================================
  // 🔧 HELPER: CONVERTIR STRINGS ISO A TIMESTAMP AL RESTAURAR
  // ==========================================================================
  static Map<String, dynamic> _restoreTimestamps(
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic> converted = {};

    // Campos que sabemos que son Timestamps
    const timestampFields = [
      'createdAt',
      'verifiedAt',
      'acceptedPolicyAt',
      'sessionUpdatedAt',
    ];

    data.forEach((key, value) {
      if (timestampFields.contains(key) && value is String) {
        // Convertir String ISO a Timestamp
        try {
          converted[key] = Timestamp.fromDate(DateTime.parse(value));
        } catch (_) {
          converted[key] = value;
        }
      } else if (value is Map<String, dynamic>) {
        // Recursivo para Maps anidados
        converted[key] = _restoreTimestamps(value);
      } else {
        converted[key] = value;
      }
    });

    return converted;
  }

  // ==========================================================================
  // 📤 CREAR BACKUP
  // ==========================================================================
  static Future<File> createBackup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // 1. Leer datos del usuario
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) throw Exception('Usuario no encontrado en Firestore');

    // 👇 Convertir Timestamps a String antes de serializar
    final userData = _convertTimestamps(userDoc.data()!);

    // 2. Leer todas las tareas del usuario
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .get();

    final tasks = tasksSnapshot.docs.map((doc) {
      // 👇 Convertir Timestamps a String antes de serializar
      final data = _convertTimestamps(doc.data());
      return {
        '_id': doc.id,
        ...data,
      };
    }).toList();

    // 3. Construir el objeto de backup
    final backup = {
      'version': '1.0',
      'appName': 'TareaLog',
      'backupDate': DateTime.now().toIso8601String(),
      'userId': user.uid,
      'user': {
        '_id': userDoc.id,
        ...userData,
      },
      'tasks': tasks,
      'summary': {
        'totalTasks': tasks.length,
      },
    };

    // 4. Convertir a JSON con formato bonito
    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

    // 5. Guardar en carpeta temporal
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final name = userData['name']?.toString().replaceAll(' ', '_') ?? 'usuario';
    final fileName = 'backup_tarealog_${name}_$timestamp.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(jsonString);

    return file;
  }

  // ==========================================================================
  // 📥 RESTAURAR BACKUP
  // ==========================================================================
  static Future<Map<String, int>> restoreBackup(File backupFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // 1. Leer y parsear el archivo JSON
    final jsonString = await backupFile.readAsString();
    final Map<String, dynamic> backup = jsonDecode(jsonString);

    // 2. Validar estructura
    if (backup['appName'] != 'TareaLog') {
      throw Exception('El archivo no es un backup válido de TareaLog');
    }

    if (backup['userId'] != user.uid) {
      throw Exception(
        'Este backup pertenece a otra cuenta. '
        'Inicia sesión con la cuenta correcta para restaurarlo.',
      );
    }

    // 3. Restaurar datos del usuario
    final userBackup = backup['user'] as Map<String, dynamic>?;
    if (userBackup != null) {
      final userCopy = Map<String, dynamic>.from(userBackup);
      userCopy.remove('_id');

      // 👇 Convertir Strings ISO a Timestamp
      final userRestored = _restoreTimestamps(userCopy);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userRestored, SetOptions(merge: true));
    }

    // 4. Restaurar tareas
    int tasksRestored = 0;
    final tasksBackup = backup['tasks'] as List<dynamic>? ?? [];

    for (var taskData in tasksBackup) {
      if (taskData is! Map<String, dynamic>) continue;

      final taskCopy = Map<String, dynamic>.from(taskData);
      final taskId = taskCopy.remove('_id') as String?;

      // 👇 Convertir Strings ISO a Timestamp
      final taskRestored = _restoreTimestamps(taskCopy);

      if (taskId == null || taskId.isEmpty) {
        // Crear nuevo
        await FirebaseFirestore.instance
            .collection('tasks')
            .add(taskRestored);
      } else {
        // Restaurar con el ID original (sobrescribe)
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(taskId)
            .set(taskRestored, SetOptions(merge: true));
      }
      tasksRestored++;
    }

    return {
      'tasksRestored': tasksRestored,
    };
  }

  // ==========================================================================
  // 🔍 VALIDAR BACKUP SIN RESTAURAR
  // ==========================================================================
  static Future<Map<String, dynamic>> validateBackup(File backupFile) async {
    final jsonString = await backupFile.readAsString();
    final Map<String, dynamic> backup = jsonDecode(jsonString);

    if (backup['appName'] != 'TareaLog') {
      throw Exception('El archivo no es un backup válido de TareaLog');
    }

    return {
      'version': backup['version'] ?? 'desconocida',
      'backupDate': backup['backupDate'] ?? 'desconocida',
      'totalTasks': (backup['tasks'] as List?)?.length ?? 0,
      'userId': backup['userId'] ?? 'desconocido',
    };
  }
}