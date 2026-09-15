import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerificadorScreen extends StatefulWidget {
  const VerificadorScreen({super.key});

  @override
  State<VerificadorScreen> createState() => _VerificadorScreenState();
}

class _VerificadorScreenState extends State<VerificadorScreen> {
  final Color _darkBlueColor = const Color(0xFF0D47A1);
  final _feedbackController = TextEditingController();
  final _codeInputController = TextEditingController();

  // ===========================================================================
  // VINCULACIÓN: Validar e ingresar el código entregado por el estudiante
  // ===========================================================================
  Future<void> _linkStudentByCode() async {
    final code = _codeInputController.text.trim().toUpperCase();
    final verifier = FirebaseAuth.instance.currentUser;

    if (code.isEmpty || verifier == null) return;

    try {
      // 1. Busca si existe un estudiante con ese inviteCode
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Código no válido o no encontrado')),
          );
        }
        return;
      }

      final studentDoc = query.docs.first;

      // 2. Vincula al estudiante guardando el UID del verificador y limpia el código
      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentDoc.id)
          .update({
        'verificadorId': verifier.uid,
        'inviteCode': null,
      });

      _codeInputController.clear();
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Estudiante vinculado con éxito')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al vincular estudiante')),
        );
      }
    }
  }

  // ===========================================================================
  // EVALUAR TAREA: Asigna estado y retroalimentación a la entrega
  // ===========================================================================
  Future<void> _evaluateTask(String taskId, String newStatus) async {
    final verifier = FirebaseAuth.instance.currentUser;
    if (verifier == null) return;

    try {
      Map<String, dynamic> updateData = {
        'status': newStatus,
        'feedback': _feedbackController.text.trim(),
        'verifiedBy': verifier.uid,
        'verifiedAt': Timestamp.now(),
      };

      // Si el verificador desestima la tarea, regresa a incompleta para el estudiante
      if (newStatus == 'Rechazado') {
        updateData['isCompleted'] = false;
      }

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update(updateData);

      _feedbackController.clear();
      if (mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarea marcada como: $newStatus')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar estado')),
        );
      }
    }
  }

  // ===========================================================================
  // DIÁLOGOS MODALES
  // ===========================================================================
  void _showLinkDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vincular Estudiante'),
        content: TextField(
          controller: _codeInputController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Código de Vinculación (ej. TRG-8A92)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _darkBlueColor,
              foregroundColor: Colors.white,
            ),
            onPressed: _linkStudentByCode,
            child: const Text('Vincular'),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(
    String taskId,
    String taskTitle,
    String currentFeedback,
  ) {
    _feedbackController.text = currentFeedback;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Revisar: $taskTitle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _feedbackController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observaciones / Retroalimentación',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => _evaluateTask(taskId, 'Rechazado'),
            child: const Text('Desestimar', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => _evaluateTask(taskId, 'Aprobado'),
            child: const Text('Aprobar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final verifier = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Verificador'),
        backgroundColor: _darkBlueColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Vincular Estudiante',
            onPressed: _showLinkDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // El verificador lee ÚNICAMENTE las tareas vinculadas a su UID
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('verificadorId', isEqualTo: verifier?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay tareas asignadas a tu cuenta.\nUsa el ícono + arriba para vincular estudiantes con su código.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final tasks = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final taskDoc = tasks[index];
              final taskData = taskDoc.data() as Map<String, dynamic>;

              final String status = taskData['status'] ?? 'Pendiente';
              final String feedback = taskData['feedback'] ?? '';
              final bool isCompleted = taskData['isCompleted'] ?? false;

              Color statusColor = Colors.orange;
              if (status == 'Aprobado') statusColor = Colors.green;
              if (status == 'Rechazado') statusColor = Colors.red;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(
                    taskData['title'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (taskData['description'] != null &&
                          taskData['description'].toString().isNotEmpty)
                        Text(taskData['description']),
                      const SizedBox(height: 4),
                      Text(
                        'Estado Alumno: ${isCompleted ? "Completada" : "En progreso"}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      if (feedback.isNotEmpty)
                        Text(
                          'Feedback: $feedback',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: _darkBlueColor,
                          ),
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _showReviewDialog(
                      taskDoc.id,
                      taskData['title'] ?? '',
                      feedback,
                    ),
                    child: Text(status),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}