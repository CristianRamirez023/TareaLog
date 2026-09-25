// lib/main.dart
// ============================================================================
// ARCHIVO PRINCIPAL DE LA APP
// Inicializa Firebase, App Check y configura el tema claro/oscuro global.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/principal_screen.dart';
import 'controllers/theme_controller.dart';

// ============================================================================
// 👈 CLAVE GLOBAL DEL NAVIGATOR
// Permite cerrar diálogos desde cualquier parte de la app
// ============================================================================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// ============================================================================
// PUNTO DE ENTRADA DE LA APP
// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1️⃣ Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==========================================================================
  // 2️⃣ ACTIVAR FIREBASE APP CHECK
  // --------------------------------------------------------------------------
  // Verifica que cada petición a Firebase venga de la app legítima.
  //
  // ⚠️ MODO DEBUG: Usar mientras desarrollas en el celular.
  //    Recuerda registrar el Debug Token en Firebase Console.
  //
  // 🚀 MODO PRODUCCIÓN: Cambiar a playIntegrity cuando hagas el build final.
  // ==========================================================================
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug, // ✅ MODO DEBUG
    appleProvider: AppleProvider.debug,
  );

  runApp(const MyApp());
}

// ============================================================================
// WIDGET RAÍZ DE LA APP
// ============================================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Controlador del tema (ChangeNotifier)
  final ThemeController _themeController = ThemeController();

  // ==========================================================================
  // PALETA DE COLORES DE LA MARCA TAREALOG
  // ==========================================================================
  static const Color _azulOscuro = Color(0xFF0D47A1);
  static const Color _azulClaro = Color(0xFF64B5F6);
  static const Color _azulMedio = Color(0xFF1565C0);
  static const Color _azulSuave = Color(0xFF90CAF9);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TareaLog',
          navigatorKey: navigatorKey, // 👈 Clave global

          // ==================================================================
          // ☀️ TEMA CLARO
          // ==================================================================
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: _azulOscuro,
              brightness: Brightness.light,
              primary: _azulOscuro,
              onPrimary: Colors.white,
              secondary: _azulMedio,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: _azulOscuro,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
          ),

          // ==================================================================
          // 🌙 TEMA OSCURO
          // ==================================================================
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: _azulClaro,
              brightness: Brightness.dark,
              primary: _azulClaro,
              onPrimary: Colors.black,
              secondary: _azulSuave,
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: _azulClaro,
              elevation: 0,
            ),
          ),

          themeMode: _themeController.themeMode,

          // ==================================================================
          // 🚦 GUARDIÁN DE RUTAS
          // Escucha el estado de autenticación y decide qué pantalla mostrar.
          // ==================================================================
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Mientras verifica → loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Si hay usuario → PrincipalScreen
              if (snapshot.hasData) {
                return PrincipalScreen(themeController: _themeController);
              }

              // Si NO hay usuario → AuthScreen
              return AuthScreen(themeController: _themeController);
            },
          ),
        );
      },
    );
  }
}