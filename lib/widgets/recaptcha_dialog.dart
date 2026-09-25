// ============================================================================
// CAPTCHA tipo reCAPTCHA (SIMULADO)
// ----------------------------------------------------------------------------
// Simula visualmente el reCAPTCHA de Google.
// Funciona 100% en cualquier plataforma (Android, iOS, Windows, etc.)
// y no requiere configuración externa.
//
// 💡 En producción real se usaría Firebase App Check con reCAPTCHA Enterprise.
// ============================================================================

import 'package:flutter/material.dart';

class RecaptchaDialog extends StatefulWidget {
  const RecaptchaDialog({super.key});

  /// Muestra el diálogo y retorna true si el usuario pasó la verificación.
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const RecaptchaDialog(),
    );
    return result ?? false;
  }

  @override
  State<RecaptchaDialog> createState() => _RecaptchaDialogState();
}

class _RecaptchaDialogState extends State<RecaptchaDialog> {
  bool _checked = false;      // Si marcó la casilla
  bool _verifying = false;    // Si está verificando (spinner)
  bool _verified = false;     // Si ya pasó la verificación

  // ==========================================================================
  // VERIFICAR
  // Simula el proceso de verificación (2 segundos)
  // ==========================================================================
  Future<void> _verify() async {
    if (!_checked || _verifying) return;

    setState(() => _verifying = true);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _verifying = false;
      _verified = true;
    });

    // Pequeña pausa para mostrar el check verde
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = _verified
        ? Colors.green
        : (_checked ? colorScheme.primary : Colors.grey.shade400);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.security, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Expanded(child: Text('Verificación de seguridad')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Para proteger tu cuenta, confirma que no eres un robot.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 20),

          // ================================================================
          // CASILLA ESTILO reCAPTCHA
          // ================================================================
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Checkbox / Spinner / Check
                SizedBox(
                  width: 32,
                  height: 32,
                  child: _verifying
                      ? const Padding(
                          padding: EdgeInsets.all(4),
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                      : _verified
                          ? const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            )
                          : Checkbox(
                              value: _checked,
                              activeColor: colorScheme.primary,
                              onChanged: (value) {
                                setState(() => _checked = value ?? false);
                              },
                            ),
                ),
                const SizedBox(width: 12),

                // Texto
                Expanded(
                  child: Text(
                    _verifying
                        ? 'Verificando...'
                        : (_verified ? 'Verificado' : 'No soy un robot'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _verified ? Colors.green : null,
                    ),
                  ),
                ),

                // Logo reCAPTCHA
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 26,
                      color: Colors.blue.shade400,
                    ),
                    Text(
                      'reCAPTCHA',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Al verificar aceptas los términos de seguridad de TareaLog.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed:
              _verifying ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: _checked && !_verifying && !_verified ? _verify : null,
          child: const Text('Verificar'),
        ),
      ],
    );
  }
}