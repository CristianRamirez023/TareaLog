// ============================================================================
// PANTALLA DEL ESTUDIANTE
// ----------------------------------------------------------------------------
// - Saludo + Banner de vinculación
// - Barra de progreso general
// - Estadísticas (Pendientes/Aprobadas/Rechazadas)
// - Lista de tareas COLAPSABLE
// - CRUD de tareas
// - Registro de logs de auditoría
// - Traducciones (Español / Inglés)
// ============================================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart'; // 👈 NUEVO
import '../services/log_service.dart';

class EstudianteScreen extends StatefulWidget {
  const EstudianteScreen({super.key});

  @override
  State<EstudianteScreen> createState() => _EstudianteScreenState();
}

class _EstudianteScreenState extends State<EstudianteScreen> {
  final _taskTitleController = TextEditingController();
  final _taskDescController = TextEditingController();

  // ==========================================================================
  // GENERAR CÓDIGO ALEATORIO
  // ==========================================================================
  String _generateShortCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  // ==========================================================================
  // GENERAR CÓDIGO DE VINCULACIÓN
  // ==========================================================================
  Future<void> _createBindingCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final t = AppLocalizations.of(context)!;
    final newCode = 'TRG-${_generateShortCode()}';

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'inviteCode': newCode});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.generateNewCode(newCode))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.errorGeneratingCode)),
        );
      }
    }
  }

  // ==========================================================================
  // CREAR TAREA
  // ==========================================================================
  Future<void> _addTask() async {
    final title = _taskTitleController.text.trim();
    final description = _taskDescController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (title.isEmpty || user == null) return;

    final t = AppLocalizations.of(context)!;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final String? verifierId = userDoc.data()?['verificadorId'];

      await FirebaseFirestore.instance.collection('tasks').add({
        'userId': user.uid,
        'verificadorId': verifierId,
        'title': title,
        'description': description,
        'isCompleted': false,
        'status': 'Pendiente',
        'feedback': '',
        'createdAt': Timestamp.now(),
      });

      await LogService.logTaskCreate(title);

      _taskTitleController.clear();
      _taskDescController.clear();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.errorCreatingTask)),
        );
      }
    }
  }

  // ==========================================================================
  // TOGGLE ESTADO DE TAREA
  // ==========================================================================
  Future<void> _toggleTaskStatus(String taskId, bool currentStatus) async {
    final t = AppLocalizations.of(context)!;
    try {
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();
      final title = taskDoc.data()?['title'] ?? 'Sin título';

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'isCompleted': !currentStatus});

      await LogService.logTaskComplete(title, !currentStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.errorUpdatingTask)),
        );
      }
    }
  }

  // ==========================================================================
  // ELIMINAR TAREA
  // ==========================================================================
  Future<void> _deleteTask(String taskId) async {
    final t = AppLocalizations.of(context)!;
    try {
      final taskDoc = await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .get();
      final title = taskDoc.data()?['title'] ?? 'Sin título';

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .delete();

      await LogService.logTaskDelete(title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.errorDeletingTask)),
        );
      }
    }
  }

  // ==========================================================================
  // DIÁLOGO PARA CREAR TAREA
  // ==========================================================================
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final t = AppLocalizations.of(ctx)!;
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(t.newTask),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskTitleController,
                decoration: InputDecoration(
                  labelText: t.taskTitle,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskDescController,
                decoration: InputDecoration(
                  labelText: t.taskDescription,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: _addTask,
              child: Text(t.save),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // 📊 CARD DE PROGRESO GENERAL
  // ==========================================================================
  Widget _buildProgressCard(int total, int completadas) {
    final t = AppLocalizations.of(context)!;
    final double progress = total == 0 ? 0 : completadas / total;
    final int percentage = (progress * 100).round();

    Color progressColor;
    if (percentage < 30) {
      progressColor = Colors.red;
    } else if (percentage < 70) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.green;
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up, color: progressColor, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      t.progress,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$completadas/$total ${t.tasks}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  _getProgressMessage(t, percentage),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // 💬 MENSAJE MOTIVACIONAL
  // ==========================================================================
  String _getProgressMessage(AppLocalizations t, int percentage) {
    if (percentage == 0) return t.startNow;
    if (percentage < 30) return t.startingOut;
    if (percentage < 50) return t.goodPace;
    if (percentage < 70) return t.doingGreat;
    if (percentage < 100) return t.almostThere;
    return t.completed;
  }

  // ==========================================================================
  // 🎴 CARD DE ESTADÍSTICA
  // ==========================================================================
  Widget _buildStatCard(
      String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // 🎴 TARJETA DE UNA TAREA INDIVIDUAL
  // ==========================================================================
  Widget _buildTaskTile(
      QueryDocumentSnapshot taskDoc, ColorScheme colorScheme) {
    final t = AppLocalizations.of(context)!;
    final taskData = taskDoc.data() as Map<String, dynamic>;
    final bool isCompleted = taskData['isCompleted'] ?? false;
    final String status = taskData['status'] ?? 'Pendiente';
    final String feedback = taskData['feedback'] ?? '';

    // Traducir el estado
    String translatedStatus;
    if (status == 'Aprobado') {
      translatedStatus = t.approved;
    } else if (status == 'Rechazado') {
      translatedStatus = t.rejected;
    } else {
      translatedStatus = t.pending;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          activeColor: colorScheme.primary,
          onChanged: (_) => _toggleTaskStatus(taskDoc.id, isCompleted),
        ),
        title: Text(
          taskData['title'] ?? '',
          style: TextStyle(
            decoration: isCompleted
                ? TextDecoration.lineThrough
                : TextDecoration.none,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (taskData['description'] != null &&
                taskData['description'].toString().isNotEmpty)
              Text(taskData['description']),
            Text(
              '${t.status}: $translatedStatus',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: status == 'Aprobado'
                    ? Colors.green
                    : (status == 'Rechazado' ? Colors.red : Colors.orange),
              ),
            ),
            if (feedback.isNotEmpty)
              Text(
                '${t.observationsLabel(feedback)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: () => _deleteTask(taskDoc.id),
        ),
      ),
    );
  }

  // ==========================================================================
  // 📋 SECCIÓN COLAPSABLE DE TAREAS
  // ==========================================================================
  Widget _buildTasksSection(
      List<QueryDocumentSnapshot> tasks, ColorScheme colorScheme) {
    final t = AppLocalizations.of(context)!;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        key: const PageStorageKey('tasks_section'),
        initiallyExpanded: true,
        leading: Icon(
          Icons.assignment,
          color: colorScheme.primary,
        ),
        title: Text(
          t.myTasks,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          tasks.length == 1
              ? t.tasksCountOne
              : t.tasksCount(tasks.length),
          style: const TextStyle(fontSize: 12),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: tasks
                  .map((taskDoc) => _buildTaskTile(taskDoc, colorScheme))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          children: [
            // =========================================================
            // SALUDO + BANNER
            // =========================================================
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final userData =
                    snapshot.data!.data() as Map<String, dynamic>?;
                final String? inviteCode = userData?['inviteCode'];
                final String? verifierId = userData?['verificadorId'];
                final String name = userData?['name'] ?? 'Estudiante';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.welcomeUser,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      color: colorScheme.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              verifierId != null
                                  ? Icons.check_circle
                                  : Icons.key,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    verifierId != null
                                        ? t.verifierLinked
                                        : t.bindingCode,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  Text(
                                    verifierId != null
                                        ? '...'
                                        : (inviteCode != null
                                            ? '${t.bindingCode}: $inviteCode'
                                            : '...'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (verifierId == null)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                                onPressed: _createBindingCode,
                                child: Text(
                                  inviteCode == null
                                      ? t.generateCodeButton
                                      : t.newCodeButton,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // =========================================================
            // PROGRESO + ESTADÍSTICAS + TAREAS
            // =========================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('userId', isEqualTo: user?.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = snapshot.data?.docs ?? [];

                  int pendientes = 0;
                  int aprobadas = 0;
                  int rechazadas = 0;

                  for (var doc in tasks) {
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pendiente';
                    if (status == 'Aprobado') {
                      aprobadas++;
                    } else if (status == 'Rechazado') {
                      rechazadas++;
                    } else {
                      pendientes++;
                    }
                  }

                  final int totalTasks = tasks.length;
                  final int completedTasks = aprobadas;

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        if (tasks.isNotEmpty)
                          _buildProgressCard(totalTasks, completedTasks),

                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildStatCard(
                                t.pending,
                                pendientes,
                                Colors.orange,
                                Icons.pending_actions,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                t.approved,
                                aprobadas,
                                Colors.green,
                                Icons.check_circle,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                t.rejected,
                                rechazadas,
                                Colors.red,
                                Icons.cancel,
                              ),
                            ],
                          ),
                        ),

                        if (tasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(
                              t.noTasksYet,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          _buildTasksSection(tasks, colorScheme),

                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // ----- FAB -----
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            onPressed: _showAddTaskDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}