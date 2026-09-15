import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  final List<String> _roles = ['Estudiante', 'Verificador'];
  String _selectedRole = 'Estudiante';

  // Color azul oscuro personalizado para las letras de los botones
  final Color _darkBlueColor = const Color(0xFF0D47A1);

  Future<void> _submitAuthForm() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Por favor llena todos los campos', isError: true);
      return;
    }

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

        // Se agregan verificadorId e inviteCode para soportar la vinculación
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': email,
          'role': _selectedRole,
          'verificadorId': null,
          'inviteCode': null,
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

  void _showResetPasswordDialog() {
    _resetEmailController.text = _emailController.text;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
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
            style: TextButton.styleFrom(
              foregroundColor: _darkBlueColor,
            ),
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: _darkBlueColor,
            ),
            onPressed: _resetPassword,
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isLogin ? 'Iniciar Sesión' : 'Crear Cuenta'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              if (!isLogin) ...[
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
                      setState(() {
                        _selectedRole = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
              ],

              if (isLogin) ...[
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: _darkBlueColor,
                  ),
                  onPressed: _showResetPasswordDialog,
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
                const SizedBox(height: 8),
              ],

              if (isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: _darkBlueColor,
                  ),
                  onPressed: _submitAuthForm,
                  child: Text(isLogin ? 'Ingresar' : 'Registrar Cuenta'),
                ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: _darkBlueColor,
                ),
                onPressed: () => setState(() => isLogin = !isLogin),
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