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
  final Color _darkBlueColor = const Color(0xFF0D47A1);

  // Genera un código aleatorio de 6 caracteres (ej. TRG-8A92)
  String _generateShortCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  // ===========================================================================
  // VINCULACIÓN: Genera y guarda un nuevo código de invitación en Firestore
  // ===========================================================================
  Future<void> _createBindingCode() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newCode = 'TRG-${_generateShortCode()}';

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'inviteCode': newCode,
      });

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

  // ===========================================================================
  // 1. CREAR: Guardar tarea incluyendo el 'verificadorId' actual del alumno
  // ===========================================================================
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

  // ===========================================================================
  // 2. ACTUALIZAR: Alternar el estado de completado
  // ===========================================================================
  Future<void> _toggleTaskStatus(String taskId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(taskId)
        .update({'isCompleted': !currentStatus});
  }

  // ===========================================================================
  // 3. ELIMINAR: Borrar documento de la tarea
  // ===========================================================================
  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  // ===========================================================================
  // DIÁLOGO CREAR TAREA
  // ===========================================================================
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            style: TextButton.styleFrom(foregroundColor: _darkBlueColor),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkBlueColor,
              foregroundColor: Colors.white,
            ),
            onPressed: _addTask,
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Estudiante'),
        backgroundColor: _darkBlueColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // ================================================================
          // Banner Informativo del Código de Vinculación (ADAPTADO AL TEMA)
          // ================================================================
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user?.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final userData = snapshot.data!.data() as Map<String, dynamic>?;
              final String? inviteCode = userData?['inviteCode'];
              final String? verifierId = userData?['verificadorId'];
              final colorScheme = Theme.of(context).colorScheme; // 👈

              return Card(
                margin: const EdgeInsets.all(12),
                color: colorScheme.primaryContainer, // 👈 CAMBIO 1
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(
                        verifierId != null ? Icons.check_circle : Icons.key,
                        color: colorScheme.onPrimaryContainer, // 👈 CAMBIO 1
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
                                color: colorScheme.onPrimaryContainer, // 👈 CAMBIO 1
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
                                color: colorScheme.onPrimaryContainer, // 👈 CAMBIO 1
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (verifierId == null)
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary, // 👈 CAMBIO 1
                            foregroundColor: colorScheme.onPrimary, // 👈 CAMBIO 1
                          ),
                          onPressed: _createBindingCode,
                          child: Text(inviteCode == null ? 'Generar' : 'Nuevo'),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),

          // ================================================================
          // Lista de Tareas en tiempo real
          // ================================================================
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

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tienes tareas aún.\n¡Presiona + para agregar una!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final tasks = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final taskDoc = tasks[index];
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
                          activeColor: _darkBlueColor,
                          onChanged: (_) =>
                              _toggleTaskStatus(taskDoc.id, isCompleted),
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
                              'Estado Evaluador: $status',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: status == 'Aprobado'
                                    ? Colors.green
                                    : (status == 'Rechazado'
                                        ? Colors.red
                                        : Colors.orange),
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
                          icon:
                              const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () => _deleteTask(taskDoc.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // 👇 CAMBIO 2: FloatingActionButton adaptado al tema
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}