import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'estudiante_screen.dart';
import 'verificador_screen.dart';
import '/controllers/theme_controller.dart';
import '../main.dart'; // 👈 Para usar navigatorKey

class PrincipalScreen extends StatefulWidget {
  final ThemeController themeController;

  const PrincipalScreen({super.key, required this.themeController});

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  String? _userRole;
  bool _isLoadingRole = true;

  static const Duration _lockDuration = Duration(minutes: 2, seconds: 30);
  static const Duration _logoutDuration = Duration(minutes: 5);

  Timer? _lockTimer;
  Timer? _logoutTimer;

  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
    _startTimers();
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _logoutTimer?.cancel();
    super.dispose();
  }

  void _startTimers() {
    _lockTimer?.cancel();
    _logoutTimer?.cancel();

    _lockTimer = Timer(_lockDuration, () {
      if (mounted && !_isLocked) {
        _showPasswordLockDialog();
      }
    });

    _logoutTimer = Timer(_logoutDuration, () {
      if (mounted) {
        _logoutDueToInactivity();
      }
    });
  }

  void _registerActivity() {
    if (_isLocked) return;
    _startTimers();
  }

  // ==========================================================================
  // 🔒 CERRAR SESIÓN POR INACTIVIDAD (VERSIÓN DEFINITIVA)
  // ==========================================================================
  Future<void> _logoutDueToInactivity() async {
    if (!mounted) return;

    // 1️⃣ Cancelar timers
    _lockTimer?.cancel();
    _logoutTimer?.cancel();

    // 2️⃣ ⚠️ CLAVE: Cerrar TODOS los diálogos abiertos usando el navigatorKey
    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    // 3️⃣ Resetear estado local
    if (mounted) {
      setState(() => _isLocked = false);
    }

    // 4️⃣ Mostrar aviso
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesión cerrada por inactividad (5 minutos sin uso)'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }

    // 5️⃣ Pequeña pausa
    await Future.delayed(const Duration(milliseconds: 300));

    // 6️⃣ Cerrar sesión
    await FirebaseAuth.instance.signOut();
  }

  // ==========================================================================
  // 🔐 DIÁLOGO DE BLOQUEO
  // ==========================================================================
  void _showPasswordLockDialog() {
    setState(() => _isLocked = true);

    final passwordController = TextEditingController();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final colorScheme = Theme.of(ctx).colorScheme;

            Future<void> verifyPassword() async {
              final password = passwordController.text.trim();

              if (password.isEmpty) {
                setDialogState(() => errorMessage = 'Ingresa tu contraseña');
                return;
              }

              setDialogState(() {
                isLoading = true;
                errorMessage = null;
              });

              try {
                final credential = EmailAuthProvider.credential(
                  email: email,
                  password: password,
                );

                await user!.reauthenticateWithCredential(credential);

                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    setState(() => _isLocked = false);
                    _startTimers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('¡Desbloqueado!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } on FirebaseAuthException catch (e) {
                setDialogState(() {
                  isLoading = false;
                  if (e.code == 'wrong-password' ||
                      e.code == 'invalid-credential') {
                    errorMessage = 'Contraseña incorrecta';
                  } else {
                    errorMessage = 'Error al verificar. Intenta de nuevo.';
                  }
                });
              } catch (e) {
                setDialogState(() {
                  isLoading = false;
                  errorMessage = 'Error inesperado';
                });
              }
            }

            return PopScope(
              canPop: false,
              onPopInvoked: (didPop) {},
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.lock, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Sesión bloqueada')),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Por seguridad, ingresa tu contraseña para continuar.',
                      style: TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autofocus: true,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.password),
                        errorText: errorMessage,
                      ),
                      onSubmitted: (_) => verifyPassword(),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: isLoading
                        ? null
                        : () async {
                            Navigator.of(ctx).pop();
                            _isLocked = false;
                            await FirebaseAuth.instance.signOut();
                          },
                    child: const Text('Cerrar sesión'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: isLoading ? null : verifyPassword,
                    child: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Desbloquear'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    widget.themeController
        .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
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
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            onPressed: _toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Cerrar sesión',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _registerActivity(),
        onPointerMove: (_) => _registerActivity(),
        onPointerUp: (_) => _registerActivity(),
        onPointerSignal: (_) => _registerActivity(),
        child: _isLoadingRole
            ? const Center(child: CircularProgressIndicator())
            : _userRole == 'Verificador'
                ? const VerificadorScreen()
                : const EstudianteScreen(),
      ),
    );
  }
}