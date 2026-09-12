import 'package:flutter/material.dart';

class VerificadorScreen extends StatelessWidget {
  const VerificadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.fact_check, size: 60, color: Colors.green),
        SizedBox(height: 16),
        Text(
          'Panel del Verificador',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('Aquí podrás revisar y calificar las entregas.'),
      ],
    );
  }
}