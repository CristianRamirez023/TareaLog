// ============================================================================
// PANTALLA DE AUTENTICACIÓN (LOGIN / REGISTRO)
// ----------------------------------------------------------------------------
// Esta pantalla permite:
// - Iniciar sesión con correo y contraseña
// - Registrar una cuenta nueva con nombre + rol
// - Restablecer contraseña por correo
// - Aceptar la Política de Tratamiento de Datos (solo en registro)
// - Alternar entre modo claro/oscuro
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/controllers/theme_controller.dart';
import 'politica_datos_screen.dart';

class AuthScreen extends StatefulWidget {
  final ThemeController themeController;

  const AuthScreen({super.key, required this.themeController});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  // ==========================================================================
  // CONTROLADORES DE CAMPOS DE TEXTO
  // Cada uno gestiona el texto que el usuario escribe en los TextField.
  // ==========================================================================
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();
  final _nameController = TextEditingController();

  // ==========================================================================
  // VARIABLES DE ESTADO
  // ==========================================================================
  bool isLogin = true;            // true = login | false = registro
  bool isLoading = false;         // true = muestra spinner mientras procesa
  bool _acceptedPolicy = false;   // true = aceptó la política de datos

  // Lista de roles disponibles y rol actualmente seleccionado
  final List<String> _roles = ['Estudiante', 'Verificador'];
  String _selectedRole = 'Estudiante';

  // ==========================================================================
  // ENVÍO DEL FORMULARIO (LOGIN O REGISTRO SEGÚN isLogin)
  // ==========================================================================
  Future<void> _submitAuthForm() async {
    // Obtener los valores de los campos y quitar espacios extra
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // ---------- VALIDACIÓN: campos vacíos ----------
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor llena todos los campos', isError: true);
      return;
    }

    // ---------- VALIDACIÓN: nombre obligatorio al registrarse ----------
    if (!isLogin && name.isEmpty) {
      _showSnackBar('Por favor ingresa tu nombre', isError: true);
      return;
    }

    // ---------- VALIDACIÓN: aceptar política al registrarse ----------
    if (!isLogin && !_acceptedPolicy) {
      _showSnackBar(
        'Debes aceptar la Política de Tratamiento de Datos',
        isError: true,
      );
      return;
    }

    // Activar el spinner de carga
    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // ==================================================================
        // 🔐 LOGIN CON FIREBASE AUTH
        // ==================================================================
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        // ==================================================================
        // 📝 REGISTRO CON FIREBASE AUTH
        // 1. Crea el usuario en Authentication
        // 2. Guarda sus datos en Firestore (users/{uid})
        // ==================================================================
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Guardar datos del usuario en Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          'name': name,
          'role': _selectedRole,
          'verificadorId': null,
          'inviteCode': null,
          'acceptedPolicy': true,           // Registro de aceptación
          'acceptedPolicyAt': Timestamp.now(), // Fecha de aceptación
          'createdAt': Timestamp.now(),
        });
      }
    } on FirebaseAuthException catch (e) {
      // ==================================================================
      // ❌ MANEJO DE ERRORES DE FIREBASE AUTH
      // Traducimos los códigos de error a mensajes en español.
      // ==================================================================
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
      // Cualquier otro error inesperado
      _showSnackBar('Error al procesar la solicitud', isError: true);
    } finally {
      // Desactivar el spinner SIEMPRE (haya éxito o error)
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // ==========================================================================
  // 🔑 RESTABLECER CONTRASEÑA POR CORREO
  // Envía un enlace de recuperación al correo ingresado.
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
        Navigator.of(context).pop(); // Cerrar el diálogo
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
  // 💬 DIÁLOGO DE RESTABLECER CONTRASEÑA
  // Muestra un AlertDialog con un TextField para ingresar el correo.
  // ==========================================================================
  void _showResetPasswordDialog() {
    // Pre-rellenar con el correo que ya escribió en el login
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
            // Botón cancelar
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            // Botón enviar correo
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
  // 💬 HELPER: MOSTRAR SNACKBAR
  // isError = true → fondo rojo | isError = false → fondo verde
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
  // 🌗 ALTERNAR TEMA CLARO / OSCURO
  // Un solo toque cambia entre los dos modos (según el actual).
  // ==========================================================================
  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    widget.themeController
        .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  // ==========================================================================
  // 📄 NAVEGAR A LA PANTALLA DE POLÍTICA DE DATOS
  // Se llama desde el checkbox de aceptación en el registro.
  // ==========================================================================
  void _openPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => const PoliticaDatosScreen(),
      ),
    );
  }

  // ==========================================================================
  // 🎨 BUILD: CONSTRUCCIÓN DE LA INTERFAZ
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    // Detecta si el tema actual es oscuro para adaptar colores
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // ----------------------------------------------------------------------
      // APPBAR: título dinámico + botón de cambiar tema
      // ----------------------------------------------------------------------
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

      // ----------------------------------------------------------------------
      // BODY: formulario con scroll (por si el teclado tapa contenido)
      // ----------------------------------------------------------------------
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
              // CAMPO: CORREO ELECTRÓNICO (común para login y registro)
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
              // CAMPO: CONTRASEÑA (oculta con puntos)
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
              // CAMPOS EXCLUSIVOS DEL MODO REGISTRO
              // Solo se muestran si NO estamos en modo login.
              // ==============================================================
              if (!isLogin) ...[
                // -------- Campo: Nombre completo --------
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // -------- Dropdown: Selección de Rol --------
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

                // -------- Checkbox: Aceptar política de datos --------
                // El borde cambia de color cuando se acepta
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
                      // Checkbox
                      Checkbox(
                        value: _acceptedPolicy,
                        activeColor: colorScheme.primary,
                        onChanged: (value) {
                          setState(() => _acceptedPolicy = value ?? false);
                        },
                      ),
                      // Texto con link a la política
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Acepto la ',
                              style: TextStyle(fontSize: 13),
                            ),
                            GestureDetector(
                              onTap: _openPolicy, // Abre la política
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
              // BOTÓN PRINCIPAL: Ingresar / Registrar Cuenta
              // Muestra spinner mientras isLoading = true
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
              // LINK: ¿OLVIDASTE TU CONTRASEÑA? (solo en modo login)
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
              // LINK: CAMBIAR ENTRE LOGIN / REGISTRO
              // Al cambiar, se resetea el checkbox de política
              // ==============================================================
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    // Si volvemos a login, reseteamos la aceptación
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