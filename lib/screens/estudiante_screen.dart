import 'package:flutter/material.dart';

class EstudianteScreen extends StatelessWidget {
  const EstudianteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.assignment, size: 60, color: Colors.blue),
        SizedBox(height: 16),
        Text(
          'Panel del Estudiante',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('Aquí podrás ver tus tareas asignadas y subirlas.'),
      ],
    );
  }
}