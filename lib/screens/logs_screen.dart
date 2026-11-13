import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  IconData _getIconForAction(String action) {
    switch (action) {
      case 'LOGIN': return Icons.login;
      case 'LOGOUT':
      case 'LOGOUT_INACTIVITY': return Icons.logout;
      case 'TASK_CREATE': return Icons.add_task;
      case 'TASK_DELETE': return Icons.delete;
      case 'TASK_COMPLETE': return Icons.check_circle;
      case 'TASK_VERIFY': return Icons.verified;
      case 'BACKUP_CREATE': return Icons.backup;
      case 'BACKUP_RESTORE': return Icons.restore;
      default: return Icons.info;
    }
  }

  Color _getColorForLevel(String level, ColorScheme colorScheme) {
    if (level == 'ERROR') return Colors.red;
    if (level == 'WARNING') return Colors.orange;
    return colorScheme.primary;
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Desconocido';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final verifier = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Actividad de Estudiantes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('verificadorId', isEqualTo: verifier?.uid)
            .snapshots(),
        builder: (context, studentsSnapshot) {
          if (!studentsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = studentsSnapshot.data!.docs;
          if (students.isEmpty) {
            return const Center(child: Text('No tienes estudiantes vinculados.'));
          }

          final studentIds = students.map((doc) => doc.id).toList();
          final studentNames = {
            for (var doc in students)
              doc.id: (doc.data() as Map<String, dynamic>)['name'] ?? 'Estudiante'
          };

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('logs')
                .where('userId', whereIn: studentIds)
                .snapshots(),
            builder: (context, logsSnapshot) {
              if (!logsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final logs = logsSnapshot.data!.docs;
              if (logs.isEmpty) {
                return const Center(child: Text('No hay actividad registrada aún.'));
              }

              // Ordenar en memoria
              logs.sort((a, b) {
                final tA = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                final tB = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                return (tB?.toDate() ?? DateTime(2000)).compareTo(tA?.toDate() ?? DateTime(2000));
              });

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final data = logs[index].data() as Map<String, dynamic>;
                  final action = data['action'] ?? 'UNKNOWN';
                  final level = data['level'] ?? 'INFO';
                  final userId = data['userId'] ?? '';
                  
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorForLevel(level, colorScheme).withOpacity(0.1),
                        child: Icon(_getIconForAction(action), color: _getColorForLevel(level, colorScheme), size: 20),
                      ),
                      title: Text(studentNames[userId] ?? 'Estudiante', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['details'] ?? ''),
                          const SizedBox(height: 4),
                          Text(_formatDate(data['timestamp']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}