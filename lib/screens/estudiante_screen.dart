import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    final newCode = 'TRG-${_generateShortCode()}';

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'inviteCode': newCode});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nuevo código generado: $newCode')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al generar el código')),
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

      _taskTitleController.clear();
      _taskDescController.clear();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al crear la tarea')),
        );
      }
    }
  }

  // ==========================================================================
  // TOGGLE ESTADO DE TAREA
  // ==========================================================================
  Future<void> _toggleTaskStatus(String taskId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': !currentStatus});
  }

  // ==========================================================================
  // ELIMINAR TAREA
  // ==========================================================================
  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  // ==========================================================================
  // DIÁLOGO PARA CREAR TAREA
  // ==========================================================================
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Nueva Tarea'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _taskTitleController,
                decoration: const InputDecoration(
                  labelText: 'Título de la tarea',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _taskDescController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: _addTask,
              child: const Text('Guardar'),
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
                    const Text(
                      'Progreso general',
                      style: TextStyle(
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
                  '$completadas de $total tareas completadas',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  _getProgressMessage(percentage),
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
  String _getProgressMessage(int percentage) {
    if (percentage == 0) return '¡Empieza ya! 💪';
    if (percentage < 30) return '¡Vas empezando! 🚀';
    if (percentage < 50) return '¡Buen ritmo! 🔥';
    if (percentage < 70) return '¡Vas muy bien! ⭐';
    if (percentage < 100) return '¡Casi lo logras! 🎯';
    return '¡Completado! 🏆';
  }

  // ==========================================================================
  // 🎴 CARD DE ESTADÍSTICA INDIVIDUAL
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
    final taskData = taskDoc.data() as Map<String, dynamic>;
    final bool isCompleted = taskData['isCompleted'] ?? false;
    final String status = taskData['status'] ?? 'Pendiente';
    final String feedback = taskData['feedback'] ?? '';

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
              'Estado: $status',
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
                'Obs: $feedback',
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
  // ✅ Con PageStorageKey para recordar el estado al cambiar de tema
  // ==========================================================================
  Widget _buildTasksSection(
      List<QueryDocumentSnapshot> tasks, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ExpansionTile(
        // 👇 Guarda el estado de expansión en la memoria de la página
        key: const PageStorageKey('tasks_section'),
        initiallyExpanded: true,
        leading: Icon(
          Icons.assignment,
          color: colorScheme.primary,
        ),
        title: const Text(
          'Mis Tareas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          '${tasks.length} ${tasks.length == 1 ? "tarea" : "tareas"}',
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
                    // ----- Saludo con avatar -----
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
                                const Text(
                                  'Bienvenido de vuelta,',
                                  style: TextStyle(fontSize: 12),
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

                    // ----- Banner de vinculación -----
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
                                        ? 'Verificador Vinculado'
                                        : 'Código de Vinculación',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  Text(
                                    verifierId != null
                                        ? 'Tus tareas serán revisadas por tu evaluador.'
                                        : (inviteCode != null
                                            ? 'Comparte este código: $inviteCode'
                                            : 'Genera un código para enlazar tu evaluador.'),
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
                                    inviteCode == null ? 'Generar' : 'Nuevo'),
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

                  // ==================================================
                  // SINGLE CHILD SCROLL VIEW
                  // ==================================================
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // Barra de progreso
                        if (tasks.isNotEmpty)
                          _buildProgressCard(totalTasks, completedTasks),

                        // Estadísticas
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              _buildStatCard(
                                'Pendientes',
                                pendientes,
                                Colors.orange,
                                Icons.pending_actions,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                'Aprobadas',
                                aprobadas,
                                Colors.green,
                                Icons.check_circle,
                              ),
                              const SizedBox(width: 8),
                              _buildStatCard(
                                'Rechazadas',
                                rechazadas,
                                Colors.red,
                                Icons.cancel,
                              ),
                            ],
                          ),
                        ),

                        // Lista colapsable o mensaje vacío
                        if (tasks.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(40),
                            child: Text(
                              'No tienes tareas aún.\n¡Presiona + para agregar una!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        else
                          _buildTasksSection(tasks, colorScheme),

                        // Espacio para que el FAB no tape contenido
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