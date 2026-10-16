import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

import 'estudiante_screen.dart';
import 'verificador_screen.dart';
import '../services/pdf_service.dart';
import '../services/excel_service.dart';
import '../services/session_service.dart';
import '../services/backup_service.dart';
import '../services/log_service.dart';
import '../controllers/theme_controller.dart';
import '../controllers/locale_controller.dart';
import '../l10n/app_localizations.dart'; // 👈 NUEVO
import '../main.dart';

class PrincipalScreen extends StatefulWidget {
  final ThemeController themeController;
  final LocaleController localeController;
  final String userRole;

  const PrincipalScreen({
    super.key,
    required this.themeController,
    required this.localeController,
    required this.userRole,
  });

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  late String _cachedRole;

  static const Duration _lockDuration = Duration(minutes: 2, seconds: 30);
  static const Duration _logoutDuration = Duration(minutes: 5);

  Timer? _lockTimer;
  Timer? _logoutTimer;

  bool _isLocked = false;
  bool _isDownloading = false;

  String get _userRole => _cachedRole;

  @override
  void initState() {
    super.initState();
    _cachedRole = widget.userRole;
    _startTimers();
    SessionService.listenSessionChanges();
  }

  @override
  void didUpdateWidget(PrincipalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userRole != widget.userRole) {
      _cachedRole = widget.userRole;
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    _logoutTimer?.cancel();
    SessionService.dispose();
    super.dispose();
  }

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

  Future<void> _logoutDueToInactivity() async {
    if (!mounted) return;

    _lockTimer?.cancel();
    _logoutTimer?.cancel();

    navigatorKey.currentState?.popUntil((route) => route.isFirst);

    if (mounted) setState(() => _isLocked = false);

    await LogService.logLogoutInactivity();

    if (mounted) {
      final t = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.logoutInactivityMessage),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    await Future.delayed(const Duration(milliseconds: 300));
    await FirebaseAuth.instance.signOut();
  }

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
            final t = AppLocalizations.of(ctx)!;
            final colorScheme = Theme.of(ctx).colorScheme;

            Future<void> verifyPassword() async {
              final password = passwordController.text.trim();

              if (password.isEmpty) {
                setDialogState(() => errorMessage = t.enterPassword);
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
                      SnackBar(
                        content: Text(t.unlocked),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              } on FirebaseAuthException catch (e) {
                setDialogState(() {
                  isLoading = false;
                  errorMessage = (e.code == 'wrong-password' ||
                          e.code == 'invalid-credential')
                      ? t.wrongPassword
                      : t.verifyError;
                });
              } catch (e) {
                setDialogState(() {
                  isLoading = false;
                  errorMessage = t.unexpectedError;
                });
              }
            }

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {},
              child: AlertDialog(
                title: Row(
                  children: [
                    Icon(Icons.lock, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(t.sessionLocked)),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t.sessionLockedMessage,
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autofocus: true,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: t.password,
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
                            await LogService.logLogout();
                            await FirebaseAuth.instance.signOut();
                          },
                    child: Text(t.logout),
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
                        : Text(t.unlock),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _toggleTheme() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    widget.themeController
        .setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

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
  // DESCARGAR PDF
  // ==========================================================================
  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    final t = AppLocalizations.of(context)!;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(t.generatingPdf),
            ],
          ),
          duration: const Duration(seconds: 2),
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
            content: Text('Error: $e'),
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
    final t = AppLocalizations.of(context)!;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(t.generatingExcel),
            ],
          ),
          duration: const Duration(seconds: 2),
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
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ==========================================================================
  // 💾 CREAR BACKUP
  // ==========================================================================
  Future<void> _createBackup() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    final t = AppLocalizations.of(context)!;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Text(t.creatingBackup),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      final file = await BackupService.createBackup();
      await LogService.logBackup();

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/json')],
        subject: 'Backup TareaLog',
        text: 'Backup generado desde TareaLog',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t.backupCreated),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // ==========================================================================
  // 🔄 RESTAURAR BACKUP
  // ==========================================================================
  Future<void> _restoreBackup() async {
    if (_isDownloading) return;
    final t = AppLocalizations.of(context)!;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: t.restoreBackup,
      );

      if (result == null || result.files.single.path == null) return;
      final file = File(result.files.single.path!);

      if (!mounted) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.orange),
              const SizedBox(width: 8),
              Text(t.restoreBackup),
            ],
          ),
          content: Text(t.restoreWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(t.cancel),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                t.restore,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _isDownloading = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(t.restoringBackup),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      final resumen = await BackupService.restoreBackup(file);
      await LogService.logRestore(resumen['tasksRestored'] ?? 0);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${t.backupRestored}\n'
              '${resumen['tasksRestored']} tareas',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleLogout() async {
    await LogService.logLogout();
    await FirebaseAuth.instance.signOut();
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
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
            Text(
              t.appTitle,
              style: const TextStyle(
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
                : const Icon(Icons.more_vert),
            tooltip: t.download,
            enabled: !_isDownloading,
            onSelected: (value) {
              if (value == 'pdf') {
                _downloadPdf();
              } else if (value == 'excel') {
                _downloadExcel();
              } else if (value == 'backup') {
                _createBackup();
              } else if (value == 'restore') {
                _restoreBackup();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 12),
                    Text(t.downloadPdf),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'excel',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.green),
                    const SizedBox(width: 12),
                    Text(t.downloadExcel),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'backup',
                child: Row(
                  children: [
                    const Icon(Icons.backup, color: Colors.blue),
                    const SizedBox(width: 12),
                    Text(t.createBackup),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'restore',
                child: Row(
                  children: [
                    const Icon(Icons.restore, color: Colors.orange),
                    const SizedBox(width: 12),
                    Text(t.restoreBackup),
                  ],
                ),
              ),
            ],
          ),
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
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: t.logout,
            onPressed: _handleLogout,
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