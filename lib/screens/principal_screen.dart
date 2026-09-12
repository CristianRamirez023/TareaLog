import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Importa las dos pantallas de interfaz
import 'estudiante_screen.dart';
import 'verificador_screen.dart';

class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  String? _userRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (mounted) {
          setState(() {
            _userRole = doc.exists ? (doc.data()?['role'] ?? 'Estudiante') : 'Estudiante';
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoadingRole = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingRole = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_userRole == 'Verificador' ? 'TareaLog - Panel Verificador' : 'TareaLog - Estudiante'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : Center(
              // Si el rol es Verificador muestra VerificadorScreen, de lo contrario EstudianteScreen
              child: _userRole == 'Verificador'
                  ? const VerificadorScreen()
                  : const EstudianteScreen(),
            ),
    );
  }
}