// ============================================================================
// SERVICIO DE PDF
// Genera reportes en PDF según el rol del usuario.
// Ordena las tareas en Dart para evitar índices compuestos en Firestore.
// ============================================================================

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PdfService {
  // ==========================================================================
  // GENERAR REPORTE SEGÚN EL ROL
  // ==========================================================================
  static Future<Uint8List> generateReport(String role) async {
    if (role == 'Verificador') {
      return _generateVerifierReport();
    }
    return _generateStudentReport();
  }

  // ==========================================================================
  // 📄 REPORTE DEL ESTUDIANTE
  // ==========================================================================
  static Future<Uint8List> _generateStudentReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // ----- Obtener datos del usuario -----
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};
    final name = userData['name'] ?? 'Estudiante';
    final email = userData['email'] ?? '';

    // ----- Obtener tareas (sin orderBy) -----
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: user.uid)
        .get();

    // 👇 Ordenar en Dart por fecha (descendente)
    final sortedTasks = tasksSnapshot.docs.toList()
      ..sort((a, b) {
        final dateA = a.data()['createdAt'] as Timestamp?;
        final dateB = b.data()['createdAt'] as Timestamp?;
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA); // descendente
      });

    // ----- Estadísticas -----
    int pendientes = 0;
    int aprobadas = 0;
    int rechazadas = 0;

    for (var doc in sortedTasks) {
      final status = doc.data()['status'] ?? 'Pendiente';
      if (status == 'Aprobado') {
        aprobadas++;
      } else if (status == 'Rechazado') {
        rechazadas++;
      } else {
        pendientes++;
      }
    }

    // ----- Crear PDF -----
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader('TareaLog - Reporte de Estudiante'),
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) {
          return [
            // ----- Info del estudiante -----
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nombre: $name',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Correo: $email',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(
                    'Fecha: ${_formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // ----- Resumen -----
            pw.Text(
              'Resumen de Tareas',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox('Total', sortedTasks.length.toString(),
                    PdfColors.blue800),
                _buildStatBox(
                    'Pendientes', pendientes.toString(), PdfColors.orange),
                _buildStatBox(
                    'Aprobadas', aprobadas.toString(), PdfColors.green),
                _buildStatBox(
                    'Rechazadas', rechazadas.toString(), PdfColors.red),
              ],
            ),
            pw.SizedBox(height: 24),

            // ----- Tabla de tareas -----
            pw.Text(
              'Detalle de Tareas',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            if (sortedTasks.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                child: pw.Text(
                  'No hay tareas registradas',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: ['Título', 'Descripción', 'Estado', 'Feedback'],
                data: sortedTasks.map((doc) {
                  final data = doc.data();
                  return [
                    data['title'] ?? '',
                    data['description'] ?? '-',
                    data['status'] ?? 'Pendiente',
                    data['feedback'] ?? '-',
                  ];
                }).toList(),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 11,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey300),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ==========================================================================
  // 📄 REPORTE DEL VERIFICADOR
  // ==========================================================================
  static Future<Uint8List> _generateVerifierReport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // ----- Obtener datos del verificador -----
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};
    final name = userData['name'] ?? 'Verificador';
    final email = userData['email'] ?? '';

    // ----- Obtener estudiantes vinculados -----
    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('verificadorId', isEqualTo: user.uid)
        .get();

    // ----- Obtener todas las tareas del verificador (sin orderBy) -----
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('verificadorId', isEqualTo: user.uid)
        .get();

    // 👇 Ordenar en Dart por fecha (descendente)
    final sortedTasks = tasksSnapshot.docs.toList()
      ..sort((a, b) {
        final dateA = a.data()['createdAt'] as Timestamp?;
        final dateB = b.data()['createdAt'] as Timestamp?;
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

    // ----- Agrupar tareas por estudiante -----
    Map<String, List<Map<String, dynamic>>> tasksByStudent = {};
    for (var task in sortedTasks) {
      final data = task.data();
      final userId = data['userId'] as String?;
      if (userId != null) {
        tasksByStudent.putIfAbsent(userId, () => []).add(data);
      }
    }

    // ----- Estadísticas globales -----
    int totalTareas = sortedTasks.length;
    int aprobadas = 0;
    int pendientes = 0;
    for (var doc in sortedTasks) {
      final status = doc.data()['status'] ?? 'Pendiente';
      if (status == 'Aprobado') {
        aprobadas++;
      } else if (status == 'Pendiente') {
        pendientes++;
      }
    }

    // ----- Crear PDF -----
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader('TareaLog - Reporte de Verificador'),
        footer: (context) => _buildFooter(context),
        build: (pw.Context context) {
          final List<pw.Widget> content = [];

          // ----- Info del verificador -----
          content.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nombre: $name',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Correo: $email',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text(
                    'Fecha: ${_formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
          content.add(pw.SizedBox(height: 20));

          // ----- Resumen global -----
          content.add(
            pw.Text(
              'Resumen General',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
          content.add(pw.SizedBox(height: 8));
          content.add(
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox('Estudiantes',
                    studentsSnapshot.docs.length.toString(), PdfColors.blue800),
                _buildStatBox(
                    'Tareas', totalTareas.toString(), PdfColors.purple),
                _buildStatBox(
                    'Pendientes', pendientes.toString(), PdfColors.orange),
                _buildStatBox(
                    'Aprobadas', aprobadas.toString(), PdfColors.green),
              ],
            ),
          );
          content.add(pw.SizedBox(height: 24));

          // ----- Tareas por estudiante -----
          content.add(
            pw.Text(
              'Tareas por Estudiante',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          );
          content.add(pw.SizedBox(height: 8));

          if (studentsSnapshot.docs.isEmpty) {
            content.add(
              pw.Text(
                'No tienes estudiantes vinculados',
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            );
          } else {
            for (var studentDoc in studentsSnapshot.docs) {
              final studentData = studentDoc.data();
              final studentName = studentData['name'] ?? 'Sin nombre';
              final studentEmail = studentData['email'] ?? '';
              final studentTasks = tasksByStudent[studentDoc.id] ?? [];

              content.add(pw.SizedBox(height: 12));
              content.add(
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    '$studentName ($studentEmail) - ${studentTasks.length} tareas',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                ),
              );
              content.add(pw.SizedBox(height: 6));

              if (studentTasks.isEmpty) {
                content.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 12, bottom: 8),
                    child: pw.Text(
                      'Sin tareas asignadas',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                );
              } else {
                content.add(
                  pw.TableHelper.fromTextArray(
                    headers: ['Título', 'Estado', 'Feedback'],
                    data: studentTasks.map((data) {
                      return [
                        data['title'] ?? '',
                        data['status'] ?? 'Pendiente',
                        data['feedback'] ?? '-',
                      ];
                    }).toList(),
                    headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                    headerDecoration: const pw.BoxDecoration(
                      color: PdfColors.blue800,
                    ),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                  ),
                );
              }
            }
          }

          return content;
        },
      ),
    );

    return pdf.save();
  }

  // ==========================================================================
  // 🎨 HELPERS DE DISEÑO
  // ==========================================================================
  static pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue800, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.Text(
            'TareaLog',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado por TareaLog',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatBox(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}