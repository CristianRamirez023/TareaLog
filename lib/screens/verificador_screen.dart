import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerificadorScreen extends StatefulWidget {
  const VerificadorScreen({super.key});

  @override
  State<VerificadorScreen> createState() => _VerificadorScreenState();
}

class _VerificadorScreenState extends State<VerificadorScreen> {
  final _feedbackController = TextEditingController();
  final _codeInputController = TextEditingController();

  bool _isLinking = false;

  // =========================================================================
  // VINCULACIÓN
  // =========================================================================
  Future<void> _linkStudentByCode() async {
    if (_isLinking) return;

    final code = _codeInputController.text.trim().toUpperCase();
    final verifier = FirebaseAuth.instance.currentUser;

    if (code.isEmpty) {
      _showSnackBar('Ingresa un código válido', isError: true);
      return;
    }

    if (verifier == null) return;

    setState(() => _isLinking = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('inviteCode', isEqualTo: code)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) {
          _showSnackBar(
            'Código no válido o ya fue usado. Pídele al estudiante que genere uno nuevo.',
            isError: true,
          );
        }
        return;
      }

      final studentDoc = query.docs.first;
      final studentData = studentDoc.data();

      final String? currentVerifierId = studentData['verificadorId'];
      if (currentVerifierId != null) {
        if (currentVerifierId == verifier.uid) {
          if (mounted) {
            _showSnackBar(
              'Este estudiante ya está vinculado a tu cuenta',
              isError: true,
            );
          }
        } else {
          if (mounted) {
            _showSnackBar(
              'Este estudiante ya está vinculado a otro verificador',
              isError: true,
            );
          }
        }
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(studentDoc.id)
          .update({
        'verificadorId': verifier.uid,
        'inviteCode': null,
      });

      final tasksQuery = await FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: studentDoc.id)
          .get();

      for (var task in tasksQuery.docs) {
        await task.reference.update({'verificadorId': verifier.uid});
      }

      _codeInputController.clear();
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        final studentName = studentData['name'] ?? 'Estudiante';
        _showSnackBar('$studentName vinculado con éxito', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al vincular estudiante: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLinking = false);
      }
    }
  }

  // =========================================================================
  // EVALUAR TAREA
  // =========================================================================
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

      if (newStatus == 'Rechazado') {
        updateData['isCompleted'] = false;
      }

      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update(updateData);

      _feedbackController.clear();
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        _showSnackBar('Tarea marcada como: $newStatus', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al actualizar estado', isError: true);
      }
    }
  }

  // =========================================================================
  // DIÁLOGOS
  // =========================================================================
  void _showLinkDialog() {
    _codeInputController.clear();

    showDialog(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Vincular Estudiante'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Pídele al estudiante su código de vinculación (formato TRG-XXXXXX).',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeInputController,
                    textCapitalization: TextCapitalization.characters,
                    enabled: !_isLinking,
                    decoration: const InputDecoration(
                      labelText: 'Código (ej. TRG-8A92)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isLinking ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  onPressed: _isLinking ? null : _linkStudentByCode,
                  child: _isLinking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Vincular'),
                ),
              ],
            );
          },
        );
      },
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
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => _evaluateTask(taskId, 'Rechazado'),
            child: const Text(
              'Desestimar',
              style: TextStyle(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => _evaluateTask(taskId, 'Aprobado'),
            child: const Text(
              'Aprobar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentTasksDialog(
    String studentName,
    List<QueryDocumentSnapshot> studentTasks,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text('Tareas de $studentName'),
          content: SizedBox(
            width: double.maxFinite,
            child: studentTasks.isEmpty
                ? const Text('Este estudiante no tiene tareas aún.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: studentTasks.length,
                    itemBuilder: (context, index) {
                      final taskData = studentTasks[index].data()
                          as Map<String, dynamic>;
                      final status = taskData['status'] ?? 'Pendiente';

                      Color statusColor = Colors.orange;
                      if (status == 'Aprobado') statusColor = Colors.green;
                      if (status == 'Rechazado') statusColor = Colors.red;

                      return ListTile(
                        title: Text(taskData['title'] ?? ''),
                        subtitle: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  // =========================================================================
  // HELPER: SnackBar
  // =========================================================================
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final verifier = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          children: [
            // =========================================================
            // SALUDO
            // =========================================================
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(verifier?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final userData =
                    snapshot.data!.data() as Map<String, dynamic>?;
                final String name = userData?['name'] ?? 'Verificador';

                return Padding(
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
                );
              },
            ),

            // =========================================================
            // ESTADÍSTICAS + LISTA AGRUPADA POR ESTUDIANTE
            // =========================================================
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Traemos TODAS las tareas del verificador
                stream: FirebaseFirestore.instance
                    .collection('tasks')
                    .where('verificadorId', isEqualTo: verifier?.uid)
                    .snapshots(),
                builder: (context, tasksSnapshot) {
                  if (tasksSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final tasks = tasksSnapshot.data?.docs ?? [];

                  // Estadísticas generales
                  int total = tasks.length;
                  int aprobadas = 0;
                  int rechazadas = 0;
                  int pendientes = 0;

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

                  return Column(
                    children: [
                      // Estadísticas
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            _buildStatCard(
                              'Total',
                              total,
                              colorScheme.primary,
                              Icons.assignment,
                            ),
                            const SizedBox(width: 8),
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

                      // Lista agrupada por estudiante
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          // Traemos la lista de estudiantes vinculados
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .where('verificadorId',
                                  isEqualTo: verifier?.uid)
                              .snapshots(),
                          builder: (context, studentsSnapshot) {
                            if (studentsSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final students =
                                studentsSnapshot.data?.docs ?? [];

                            if (students.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    'No tienes estudiantes vinculados.\nUsa el botón "Vincular" para agregar uno.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Agrupar tareas por estudiante
                            Map<String, List<QueryDocumentSnapshot>>
                                tasksByStudent = {};
                            for (var task in tasks) {
                              final data =
                                  task.data() as Map<String, dynamic>;
                              final userId = data['userId'] as String?;
                              if (userId != null) {
                                tasksByStudent
                                    .putIfAbsent(userId, () => [])
                                    .add(task);
                              }
                            }

                            return ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: students.length,
                              itemBuilder: (context, index) {
                                final student = students[index];
                                final studentData =
                                    student.data() as Map<String, dynamic>;
                                final studentName =
                                    studentData['name'] ?? 'Sin nombre';
                                final studentEmail =
                                    studentData['email'] ?? '';

                                final studentTasks =
                                    tasksByStudent[student.id] ?? [];

                                // Contadores por estudiante
                                int sPending = 0;
                                int sApproved = 0;
                                int sRejected = 0;
                                for (var t in studentTasks) {
                                  final d = t.data()
                                      as Map<String, dynamic>;
                                  final s = d['status'] ?? 'Pendiente';
                                  if (s == 'Aprobado') {
                                    sApproved++;
                                  } else if (s == 'Rechazado') {
                                    sRejected++;
                                  } else {
                                    sPending++;
                                  }
                                }

                                return Card(
                                  elevation: 2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ExpansionTile(
                                    leading: CircleAvatar(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor:
                                          colorScheme.onPrimary,
                                      child: Text(
                                        studentName.isNotEmpty
                                            ? studentName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      studentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studentEmail,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${studentTasks.length} tareas · $sPending pend. · $sApproved aprob. · $sRejected rech.',
                                          style: const TextStyle(
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    children: studentTasks.isEmpty
                                        ? [
                                            const Padding(
                                              padding: EdgeInsets.all(16),
                                              child: Text(
                                                'Este estudiante no tiene tareas aún.',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontStyle:
                                                      FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                          ]
                                        : studentTasks.map((task) {
                                            final taskData = task.data()
                                                as Map<String, dynamic>;
                                            final status =
                                                taskData['status'] ??
                                                    'Pendiente';
                                            final feedback =
                                                taskData['feedback'] ?? '';
                                            final isCompleted =
                                                taskData['isCompleted'] ??
                                                    false;

                                            Color statusColor =
                                                Colors.orange;
                                            if (status == 'Aprobado') {
                                              statusColor = Colors.green;
                                            }
                                            if (status == 'Rechazado') {
                                              statusColor = Colors.red;
                                            }

                                            return ListTile(
                                              contentPadding:
                                                  const EdgeInsets
                                                      .symmetric(
                                                horizontal: 16,
                                                vertical: 4,
                                              ),
                                              title: Text(
                                                taskData['title'] ?? '',
                                                style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  if (taskData[
                                                              'description'] !=
                                                          null &&
                                                      taskData['description']
                                                          .toString()
                                                          .isNotEmpty)
                                                    Text(
                                                      taskData[
                                                          'description'],
                                                      style:
                                                          const TextStyle(
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Estado alumno: ${isCompleted ? "✅ Completada" : "⏳ En progreso"}',
                                                    style:
                                                        const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  if (feedback
                                                      .isNotEmpty)
                                                    Text(
                                                      'Feedback: $feedback',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontStyle:
                                                            FontStyle
                                                                .italic,
                                                        color: colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              trailing: ElevatedButton(
                                                style: ElevatedButton
                                                    .styleFrom(
                                                  backgroundColor:
                                                      statusColor,
                                                  foregroundColor:
                                                      Colors.white,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 12,
                                                    vertical: 4,
                                                  ),
                                                  minimumSize:
                                                      const Size(0, 32),
                                                ),
                                                onPressed: () =>
                                                    _showReviewDialog(
                                                  task.id,
                                                  taskData['title'] ?? '',
                                                  feedback,
                                                ),
                                                child: Text(
                                                  status,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),

        // Botón flotante para vincular estudiante
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            onPressed: _showLinkDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Vincular'),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}