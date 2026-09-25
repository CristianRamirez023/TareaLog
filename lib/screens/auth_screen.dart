// ============================================================================
// PANTALLA DE AUTENTICACIÓN (LOGIN / REGISTRO)
// ----------------------------------------------------------------------------
// - Login y registro con Firebase Auth
// - Verificación con CAPTCHA visual antes de continuar
// - Aceptación de Política de Datos (solo registro)
// - Toggle de tema claro/oscuro
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/controllers/theme_controller.dart';
import '../widgets/recaptcha_dialog.dart'; // 👈 CAPTCHA visual
import 'politica_datos_screen.dart';

class AuthScreen extends StatefulWidget {
  final ThemeController themeController;

  const AuthScreen({super.key, required this.themeController});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // ==========================================================================
  // CONTROLADORES DE CAMPOS
  // ==========================================================================
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  final _nameController = TextEditingController();

  // ==========================================================================
  // VARIABLES DE ESTADO
  // ==========================================================================
  bool isLogin = true;
  bool isLoading = false;
  bool _acceptedPolicy = false;

  final List<String> _roles = ['Estudiante', 'Verificador'];
  String _selectedRole = 'Estudiante';

  // ==========================================================================
  // ENVÍO DEL FORMULARIO (LOGIN O REGISTRO)
  // ==========================================================================
  Future<void> _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // ---------- VALIDACIONES ----------
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor llena todos los campos', isError: true);
      return;
    }

    if (!isLogin && name.isEmpty) {
      _showSnackBar('Por favor ingresa tu nombre', isError: true);
      return;
    }

    if (!isLogin && !_acceptedPolicy) {
      _showSnackBar(
        'Debes aceptar la Política de Tratamiento de Datos',
        isError: true,
      );
      return;
    }

    // ==========================================================================
    // 👇 CAPTCHA VISUAL ANTES DE CONTINUAR
    // ==========================================================================
    final captchaPassed = await RecaptchaDialog.show(context);

    if (!captchaPassed) {
      _showSnackBar('Verificación de seguridad cancelada', isError: true);
      return;
    }

    // ---------- LOGIN / REGISTRO ----------
    setState(() => isLoading = true);

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          'name': name,
          'role': _selectedRole,
          'verificadorId': null,
          'inviteCode': null,
          'acceptedPolicy': true,
          'acceptedPolicyAt': Timestamp.now(),
          'createdAt': Timestamp.now(),
        });
      }
    } on FirebaseAuthException catch (e) {
      String mensajeError = 'Ocurrió un error en la autenticación.';

      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        mensajeError = 'Correo no registrado o contraseña incorrecta.';
      } else if (e.code == 'wrong-password') {
        mensajeError = 'La contraseña es incorrecta.';
      } else if (e.code == 'invalid-email') {
        mensajeError = 'El formato del correo no es válido.';
      } else if (e.code == 'email-already-in-use') {
        mensajeError = 'Este correo ya se encuentra registrado.';
      } else if (e.code == 'weak-password') {
        mensajeError = 'La contraseña debe tener al menos 6 caracteres.';
      }

      _showSnackBar(mensajeError, isError: true);
    } catch (e) {
      _showSnackBar('Error al procesar la solicitud', isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ==========================================================================
  // RESTABLECER CONTRASEÑA
  // ==========================================================================
  Future<void> _resetPassword() async {
    final email = _resetEmailController.text.trim();

    if (email.isEmpty) {
      _showSnackBar('Ingresa tu correo electrónico', isError: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar('Correo de restablecimiento enviado', isError: false);
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = 'Error al enviar el correo.';
      if (e.code == 'user-not-found') {
        mensaje = 'No existe una cuenta con este correo.';
      } else if (e.code == 'invalid-email') {
        mensaje = 'El correo no es válido.';
      }
      _showSnackBar(mensaje, isError: true);
    }
  }

  // ==========================================================================
  // DIÁLOGO DE RESTABLECER CONTRASEÑA
  // ==========================================================================
  void _showResetPasswordDialog() {
    _resetEmailController.text = _emailController.text;

    showDialog(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Restablecer contraseña'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu correo para recibir un enlace de recuperación.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: _resetPassword,
              child: const Text('Enviar'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================================
  // HELPER: SNACKBAR
  // ==========================================================================
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // ==========================================================================
  // ALTERNAR TEMA
  // ==========================================================================
  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    widget.themeController
        .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Iniciar Sesión' : 'Crear Cuenta'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            onPressed: _toggleTheme,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // ==============================================================
              // LOGO Y SUBTÍTULO
              // ==============================================================
              Text(
                'TareaLog',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Organiza tus tareas',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF90CAF9)
                      : const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 40),

              // ==============================================================
              // CAMPO: CORREO
              // ==============================================================
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ==============================================================
              // CAMPO: CONTRASEÑA
              // ==============================================================
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ==============================================================
              // CAMPOS EXCLUSIVOS DEL REGISTRO
              // ==============================================================
              if (!isLogin) ...[
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Selecciona tu Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: _roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedRole = newValue);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // ----- Checkbox de política de datos -----
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _acceptedPolicy
                          ? colorScheme.primary
                          : Colors.grey.shade400,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _acceptedPolicy,
                        activeColor: colorScheme.primary,
                        onChanged: (value) {
                          setState(() => _acceptedPolicy = value ?? false);
                        },
                      ),
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Acepto la ',
                              style: TextStyle(fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (ctx) =>
                                        const PoliticaDatosScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Política de Tratamiento de Datos',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ==============================================================
              // BOTÓN PRINCIPAL
              // ==============================================================
              if (isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 12,
                    ),
                  ),
                  onPressed: _submitAuthForm,
                  child: Text(isLogin ? 'Ingresar' : 'Registrar Cuenta'),
                ),

              // ==============================================================
              // LINK: OLVIDÉ MI CONTRASEÑA (solo login)
              // ==============================================================
              if (isLogin) ...[
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                  onPressed: _showResetPasswordDialog,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],

              // ==============================================================
              // LINK: CAMBIAR ENTRE LOGIN/REGISTRO
              // ==============================================================
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    if (isLogin) _acceptedPolicy = false;
                  });
                },
                child: Text(
                  isLogin
                      ? '¿No tienes cuenta? Regístrate aquí'
                      : '¿Ya tienes cuenta? Inicia sesión',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}