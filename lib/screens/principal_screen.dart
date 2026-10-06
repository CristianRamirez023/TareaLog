import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'estudiante_screen.dart';
import 'verificador_screen.dart';
import '../services/pdf_service.dart';
import '../services/excel_service.dart';
import '../services/session_service.dart'; // 👈 NUEVO
import '/controllers/theme_controller.dart';
import '../main.dart';

class PrincipalScreen extends StatefulWidget {
  final ThemeController themeController;
  final String userRole;

  const PrincipalScreen({
    super.key,
    required this.themeController,
    required this.userRole,
  });

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  // ==========================================================================
  // CACHE DEL ROL
  // ==========================================================================
  late String _cachedRole;

  // ==========================================================================
  // TIMERS DE SEGURIDAD
  // ==========================================================================
  static const Duration _lockDuration = Duration(minutes: 2, seconds: 30);
  static const Duration _logoutDuration = Duration(minutes: 5);

  Timer? _lockTimer;
  Timer? _logoutTimer;

  bool _isLocked = false;
  bool _isDownloading = false;

  // ==========================================================================
  // GETTER: Rol actual
  // ==========================================================================
  String get _userRole => _cachedRole;

  // ==========================================================================
  // INITSTATE
  // ==========================================================================
  @override
  void initState() {
    super.initState();
    _cachedRole = widget.userRole;
    _startTimers();

    // 👇 NUEVO: Escuchar cambios de sesión (bloquea otros dispositivos)
    SessionService.listenSessionChanges();
  }

  // ==========================================================================
  // DIDUPDATEWIDGET
  // ==========================================================================
  @override
  void didUpdateWidget(PrincipalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userRole != widget.userRole) {
      _cachedRole = widget.userRole;
    }
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================
  @override
  void dispose() {
    _lockTimer?.cancel();
    _logoutTimer?.cancel();
    SessionService.dispose(); // 👈 NUEVO: cancelar suscripción
    super.dispose();
  }

  // ==========================================================================
  // TIMERS
  // ==========================================================================
  void _startTimers() {
    _lockTimer?.cancel();
    _logoutTimer?.cancel();

    _lockTimer = Timer(_lockDuration, () {
      if (mounted && !_isLocked) _showPasswordLockDialog();
    });

    _logoutTimer = Timer(_logoutDuration, () {
      if (mounted) _logoutDueToInactivity();
    });
  }

  void _registerActivity() {
    if (_isLocked) return;
    _startTimers();
  }

  // ==========================================================================
  // CERRAR SESIÓN POR INACTIVIDAD
  // ==========================================================================
  Future<void> _logoutDueToInactivity() async {
    if (!mounted) return;

    _lockTimer?.cancel();
    _logoutTimer?.cancel();

    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    if (mounted) setState(() => _isLocked = false);

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

    await Future.delayed(const Duration(milliseconds: 300));
    await FirebaseAuth.instance.signOut();
  }

  // ==========================================================================
  // DIÁLOGO DE BLOQUEO
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
                  errorMessage = (e.code == 'wrong-password' ||
                          e.code == 'invalid-credential')
                      ? 'Contraseña incorrecta'
                      : 'Error al verificar. Intenta de nuevo.';
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

  // ==========================================================================
  // ALTERNAR TEMA
  // ==========================================================================
  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    widget.themeController
        .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  // ==========================================================================
  // DESCARGAR PDF
  // ==========================================================================
  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Generando PDF...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final bytes = await PdfService.generateReport(_userRole);
      final dir = await getTemporaryDirectory();
      final fileName = _userRole == 'Verificador'
          ? 'reporte_verificador.pdf'
          : 'reporte_estudiante.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Reporte TareaLog',
        text: 'Reporte generado desde TareaLog',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ==========================================================================
  // DESCARGAR EXCEL
  // ==========================================================================
  Future<void> _downloadExcel() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Generando Excel...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final file = await ExcelService.generateReport(_userRole);

      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'Reporte TareaLog',
        text: 'Reporte generado desde TareaLog',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar Excel: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appBarForegroundColor =
        Theme.of(context).appBarTheme.foregroundColor ?? Colors.white;

    final role = _cachedRole;
    final bool isVerifier = role == 'Verificador';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'TareaLog',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isVerifier ? Icons.verified_user : Icons.school,
              color: appBarForegroundColor,
              size: 22,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: _isDownloading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: appBarForegroundColor,
                    ),
                  )
                : const Icon(Icons.download),
            tooltip: 'Descargar reporte',
            enabled: !_isDownloading,
            onSelected: (value) {
              if (value == 'pdf') {
                _downloadPdf();
              } else if (value == 'excel') {
                _downloadExcel();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Descargar PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    Icon(Icons.table_chart, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Descargar Excel'),
                  ],
                ),
              ),
            ],
          ),
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
        child: isVerifier
            ? const VerificadorScreen()
            : const EstudianteScreen(),
      ),
    );
  }
}