// ============================================================================
// SERVICIO DE EXCEL
// Genera reportes en Excel (.xlsx) según el rol del usuario.
// Ordena las tareas en Dart para evitar índices compuestos en Firestore.
// ============================================================================

import 'dart:io';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExcelService {
  // ==========================================================================
  // GENERAR EXCEL SEGÚN EL ROL
  // ==========================================================================
  static Future<File> generateReport(String role) async {
    if (role == 'Verificador') {
      return _generateVerifierExcel();
    }
    return _generateStudentExcel();
  }

  // ==========================================================================
  // 📊 EXCEL DEL ESTUDIANTE
  // ==========================================================================
  static Future<File> _generateStudentExcel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};
    final name = userData['name'] ?? 'Estudiante';

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
        return dateB.compareTo(dateA);
      });

    // ----- Crear workbook -----
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Mis Tareas';

    // ----- Encabezados -----
    sheet.getRangeByName('A1').setText('Título');
    sheet.getRangeByName('B1').setText('Descripción');
    sheet.getRangeByName('C1').setText('Estado');
    sheet.getRangeByName('D1').setText('Feedback');
    sheet.getRangeByName('E1').setText('Fecha creación');

    // Estilo encabezados
    final Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#0D47A1';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.fontSize = 12;

    sheet.getRangeByName('A1:E1').cellStyle = headerStyle;

    // ----- Datos -----
    int row = 2;
    for (var doc in sortedTasks) {
      final data = doc.data();
      final createdAt = data['createdAt'] as Timestamp?;
      final dateStr = createdAt != null
          ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
          : '-';

      sheet.getRangeByIndex(row, 1).setText(data['title'] ?? '');
      sheet.getRangeByIndex(row, 2).setText(data['description'] ?? '');
      sheet.getRangeByIndex(row, 3).setText(data['status'] ?? 'Pendiente');
      sheet.getRangeByIndex(row, 4).setText(data['feedback'] ?? '-');
      sheet.getRangeByIndex(row, 5).setText(dateStr);
      row++;
    }

    // ----- Ajustar columnas -----
    sheet.getRangeByName('A1:E1').autoFitColumns();

    // ----- Guardar archivo -----
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getTemporaryDirectory();
    final safeName = name.replaceAll(' ', '_');
    final path = '${directory.path}/reporte_tareas_$safeName.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  // ==========================================================================
  // 📊 EXCEL DEL VERIFICADOR
  // ==========================================================================
  static Future<File> _generateVerifierExcel() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};
    final name = userData['name'] ?? 'Verificador';

    final studentsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('verificadorId', isEqualTo: user.uid)
        .get();

    // ----- Obtener tareas (sin orderBy) -----
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('verificadorId', isEqualTo: user.uid)
        .get();

    // 👇 Ordenar en Dart
    final sortedTasks = tasksSnapshot.docs.toList()
      ..sort((a, b) {
        final dateA = a.data()['createdAt'] as Timestamp?;
        final dateB = b.data()['createdAt'] as Timestamp?;
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

    // Agrupar tareas por estudiante
    Map<String, List<Map<String, dynamic>>> tasksByStudent = {};
    for (var task in sortedTasks) {
      final data = task.data();
      final userId = data['userId'] as String?;
      if (userId != null) {
        tasksByStudent.putIfAbsent(userId, () => []).add(data);
      }
    }

    // ----- Crear workbook -----
    final Workbook workbook = Workbook();

    // ===== HOJA 1: Resumen =====
    final Worksheet summarySheet = workbook.worksheets[0];
    summarySheet.name = 'Resumen';

    summarySheet.getRangeByName('A1').setText('Resumen General');
    summarySheet.getRangeByName('A1').cellStyle.bold = true;
    summarySheet.getRangeByName('A1').cellStyle.fontSize = 16;

    summarySheet.getRangeByName('A3').setText('Nombre:');
    summarySheet.getRangeByName('B3').setText(name);
    summarySheet.getRangeByName('A4').setText('Total estudiantes:');
    summarySheet.getRangeByName('B4').setText(
        studentsSnapshot.docs.length.toString());
    summarySheet.getRangeByName('A5').setText('Total tareas:');
    summarySheet.getRangeByName('B5').setText(sortedTasks.length.toString());

    // ===== HOJA 2: Tareas detalladas =====
    final Worksheet tasksSheet = workbook.worksheets.addWithName('Tareas');

    tasksSheet.getRangeByName('A1').setText('Estudiante');
    tasksSheet.getRangeByName('B1').setText('Título');
    tasksSheet.getRangeByName('C1').setText('Descripción');
    tasksSheet.getRangeByName('D1').setText('Estado');
    tasksSheet.getRangeByName('E1').setText('Feedback');

    final Style headerStyle = workbook.styles.add('headerStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#0D47A1';
    headerStyle.fontColor = '#FFFFFF';
    tasksSheet.getRangeByName('A1:E1').cellStyle = headerStyle;

    int row = 2;
    for (var studentDoc in studentsSnapshot.docs) {
      final studentData = studentDoc.data();
      final studentName = studentData['name'] ?? 'Sin nombre';
      final studentTasks = tasksByStudent[studentDoc.id] ?? [];

      for (var task in studentTasks) {
        tasksSheet.getRangeByIndex(row, 1).setText(studentName);
        tasksSheet.getRangeByIndex(row, 2).setText(task['title'] ?? '');
        tasksSheet.getRangeByIndex(row, 3).setText(task['description'] ?? '');
        tasksSheet.getRangeByIndex(row, 4).setText(
            task['status'] ?? 'Pendiente');
        tasksSheet.getRangeByIndex(row, 5).setText(task['feedback'] ?? '-');
        row++;
      }
    }

    tasksSheet.getRangeByName('A1:E1').autoFitColumns();

    // ----- Guardar archivo -----
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getTemporaryDirectory();
    final safeName = name.replaceAll(' ', '_');
    final path = '${directory.path}/reporte_verificador_$safeName.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }
}