// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 👈 Importante
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/principal_screen.dart';
import 'controllers/theme_controller.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeController _themeController = ThemeController();

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
          navigatorKey: navigatorKey,

          // ☀️ TEMA CLARO
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

          // 🌙 TEMA OSCURO
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

          // 🚦 GUARDIÁN DE RUTAS
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Mientras verifica → loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Si hay usuario → cargar su rol y mostrar PrincipalScreen
              if (snapshot.hasData) {
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(snapshot.data!.uid)
                      .get(),
                  builder: (context, roleSnapshot) {
                    if (!roleSnapshot.hasData) {
                      return const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final data = roleSnapshot.data!.data();
                    final role = (data is Map && data['role'] != null)
                        ? data['role'] as String
                        : 'Estudiante';

                    return PrincipalScreen(
                      themeController: _themeController,
                      userRole: role, // 👈 Pasar el rol
                    );
                  },
                );
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