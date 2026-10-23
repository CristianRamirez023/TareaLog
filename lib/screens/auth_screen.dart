import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/controllers/theme_controller.dart';
import '/controllers/locale_controller.dart';
import '../l10n/app_localizations.dart';
import '../widgets/recaptcha_dialog.dart';
import '../services/session_service.dart';
import '../services/log_service.dart';
import 'politica_datos_screen.dart';

class AuthScreen extends StatefulWidget {
  final ThemeController themeController;
  final LocaleController localeController;

  const AuthScreen({
    super.key,
    required this.themeController,
    required this.localeController,
  });

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
  bool _obscurePassword = true;

  final List<String> _roles = ['Estudiante', 'Verificador'];
  String _selectedRole = 'Estudiante';

  // ==========================================================================
  // 🔐 VALIDAR POLÍTICA DE CONTRASEÑAS
  // Requisitos: 12 chars, 1 Mayus, 1 minus, 1 especial, 3 numeros
  // ==========================================================================
  String? _validatePasswordPolicy(String password) {
    if (password.length < 12) {
      return 'La contraseña debe tener al menos 12 caracteres.';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Debe incluir al menos una letra mayúscula.';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Debe incluir al menos una letra minúscula.';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Debe incluir al menos un carácter especial (!@#\$%^&*...).';
    }
    // Busca al menos 3 números en cualquier posición
    if (!password.contains(RegExp(r'[0-9].*[0-9].*[0-9]'))) {
      return 'Debe incluir al menos 3 números.';
    }
    return null; // ✅ Contraseña válida
  }

  // ==========================================================================
  // ENVÍO DEL FORMULARIO
  // ==========================================================================
  Future<void> _submitAuthForm() async {
    final t = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // ---------- VALIDACIONES BÁSICAS ----------
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
        'Debes aceptar la ${t.privacyPolicy}',
        isError: true,
      );
      return;
    }

    // ---------- VALIDACIÓN DE CONTRASEÑA (solo registro) ----------
    if (!isLogin) {
      final passwordError = _validatePasswordPolicy(password);
      if (passwordError != null) {
        _showSnackBar(passwordError, isError: true);
        return;
      }
    }

    // ---------- CAPTCHA VISUAL ----------
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

        await SessionService.registerSession();
        await LogService.logLogin();
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

        await SessionService.registerSession();
        await LogService.logLogin();
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
        mensajeError = 'La contraseña es muy débil.';
      }

      _showSnackBar(mensajeError, isError: true);
      await LogService.logError('Error de autenticación: ${e.code}');
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
    final t = AppLocalizations.of(context)!;
    _resetEmailController.text = _emailController.text;

    showDialog(
      context: context,
      builder: (ctx) {
        final tCtx = AppLocalizations.of(ctx)!;
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(tCtx.resetPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tCtx.resetPasswordMessage),
              const SizedBox(height: 12),
              TextField(
                controller: _resetEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: tCtx.email,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(tCtx.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
              onPressed: _resetPassword,
              child: Text(tCtx.send),
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
  // 🌐 CAMBIAR IDIOMA
  // ==========================================================================
  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
              title: const Text('Español'),
              trailing: widget.localeController.locale.languageCode == 'es'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                widget.localeController.setLocale(const Locale('es'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              trailing: widget.localeController.locale.languageCode == 'en'
                  ? const Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () {
                widget.localeController.setLocale(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? t.login : t.register),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: t.changeLanguage,
            onPressed: _showLanguageSelector,
          ),
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? t.lightMode : t.darkMode,
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

              // LOGO Y SUBTÍTULO
              Text(
                t.appTitle,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                t.appSubtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF90CAF9)
                      : const Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 40),

              // CAMPO: CORREO
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: t.email,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 12),

              // CAMPO: CONTRASEÑA CON OJITO
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: t.password,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              
              // 👇 TEXTO DE AYUDA PARA LA CONTRASEÑA (SOLO EN REGISTRO)
              if (!isLogin) ...[
                const SizedBox(height: 8),
                Text(
                  'Mínimo 12 caracteres, 1 mayúscula, 1 minúscula, 1 símbolo y 3 números.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              
              const SizedBox(height: 12),

              // CAMPOS EXCLUSIVOS DEL REGISTRO
              if (!isLogin) ...[
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: t.fullName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: t.selectRole,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.badge),
                  ),
                  items: _roles.map((String role) {
                    final roleLabel = role == 'Estudiante'
                        ? t.student
                        : t.verifier;
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(roleLabel),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() => _selectedRole = newValue);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Checkbox de política de datos
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
                            Text(
                              t.acceptPolicy,
                              style: const TextStyle(fontSize: 13),
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
                                t.privacyPolicy,
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

              // BOTÓN PRINCIPAL
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
                  child: Text(isLogin ? t.signIn : t.signUp),
                ),

              // LINK: OLVIDÉ MI CONTRASEÑA (solo login)
              if (isLogin) ...[
                const SizedBox(height: 8),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                  ),
                  onPressed: _showResetPasswordDialog,
                  child: Text(t.forgotPassword),
                ),
              ],

              // LINK: CAMBIAR ENTRE LOGIN/REGISTRO
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    if (isLogin) _acceptedPolicy = false;
                    _obscurePassword = true;
                  });
                },
                child: Text(isLogin ? t.noAccount : t.haveAccount),
              ),
            ],
          ),
        ),
      ),
    );
  }
}