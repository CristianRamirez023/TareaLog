import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'estudiante_screen.dart';
import 'verificador_screen.dart';
import '/controllers/theme_controller.dart'; // 👈 ajusta la ruta

class PrincipalScreen extends StatefulWidget {
  final ThemeController themeController; // 👈 nuevo

  const PrincipalScreen({super.key, required this.themeController});

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
            _userRole = doc.exists
                ? (doc.data()?['role'] ?? 'Estudiante')
                : 'Estudiante';
            _isLoadingRole = false;
          });
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingRole = false);
      }
    } else {
      if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  // 👇 Muestra un bottom sheet con las 3 opciones de tema
  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Modo Claro'),
                onTap: () {
                  widget.themeController.setThemeMode(ThemeMode.light);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Modo Oscuro'),
                onTap: () {
                  widget.themeController.setThemeMode(ThemeMode.dark);
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_suggest),
                title: const Text('Predeterminado del sistema'),
                onTap: () {
                  widget.themeController.setThemeMode(ThemeMode.system);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_userRole == 'Verificador'
            ? 'TareaLog - Panel Verificador'
            : 'TareaLog - Estudiante'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Cambiar tema',
            onPressed: _showThemeSelector,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : _userRole == 'Verificador'
              ? const VerificadorScreen()
              : const EstudianteScreen(),
    );
  }
}