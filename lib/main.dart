// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/principal_screen.dart';
import 'controllers/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'TareaLog',
          theme: ThemeData(
            primarySwatch: Colors.deepPurple,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.deepPurple,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
          ),
          themeMode: _themeController.themeMode,

          // StreamBuilder actúa como el guardián de rutas (Router de sesión)
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // 1. Mientras Firebase verifica si hay sesión, loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // 2. Si existe usuario autenticado → PrincipalScreen
              if (snapshot.hasData) {
                return PrincipalScreen(themeController: _themeController);
              }

              // 3. Si NO hay usuario → AuthScreen
              return AuthScreen(themeController: _themeController);
            },
          ),
        );
      },
    );
  }
}