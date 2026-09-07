// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/principal_screen.dart';

void main() async {
  // Asegura la inicialización de los bindings de Flutter antes de Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Conecta la app con el proyecto de Firebase usando la configuración generada
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TareaLog',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      
      // StreamBuilder actúa como el guardián de rutas (Router de sesión)
      home: StreamBuilder<User?>(
        // Escucha los cambios de sesión de Firebase en tiempo real
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Mientras Firebase verifica si hay una sesión guardada, muestra pantalla de carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          
          // 2. Si existe un usuario autenticado, lo manda a la pantalla principal
          if (snapshot.hasData) {
            return const PrincipalScreen();
          }
          
          // 3. Si NO hay usuario autenticado (o cerró sesión), lo manda primero a AuthScreen
          return const AuthScreen();
        },
      ),
    );
  }
}