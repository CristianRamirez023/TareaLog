// lib/screens/principal_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({super.key}); //constructor

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState(); // le delegamos la logica de la pantalla a _PrincipalScreenState
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  // Controlador para capturar el texto del campo de nueva tarea
  final _tareaController = TextEditingController();
  
  // Obtiene los datos del usuario activo que inició sesión
  final _usuario = FirebaseAuth.instance.currentUser;

  // Función para guardar una nueva tarea en Cloud Firestore
  Future<void> _agregarTarea() async {
    final textoTarea = _tareaController.text.trim();
    if (textoTarea.isEmpty || _usuario == null) return;

    // Crea un nuevo documento dentro de la colección 'tasks'
    await FirebaseFirestore.instance.collection('tasks').add({
      'title': textoTarea,
      'userId': _usuario!.uid, // Asocia la tarea al ID único del usuario
      'createdAt': Timestamp.now(),
      'isDone': false,
    });

    _tareaController.clear(); // Limpia el input
  }

  // Función para alternar entre tarea completada o pendiente
  Future<void> _cambiarEstadoTarea(String idDoc, bool estadoActual) async {
    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(idDoc)
        .update({'isDone': !estadoActual});
  }

  // Función para borrar el documento de la tarea en Firestore
  Future<void> _eliminarTarea(String idDoc) async {
    await FirebaseFirestore.instance.collection('tasks').doc(idDoc).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TareaLog - Mis Tareas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            // Al cerrar sesión, authStateChanges() en main.dart lo detecta 
            // y devuelve automáticamente al usuario a AuthScreen
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Sección superior: Input para escribir y agregar tareas
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tareaController,
                    decoration: const InputDecoration(
                      labelText: 'Nueva tarea...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _agregarTarea,
                ),
              ],
            ),
          ),
          
          // Sección inferior: Lista de tareas en tiempo real desde Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Realiza la consulta filtrando solo las tareas del usuario logueado
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('userId', isEqualTo: _usuario?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No tienes tareas registradas aún.'),
                  );
                }

                final documentos = snapshot.data!.docs;

                // Renderiza cada tarea obtenida de la base de datos
                return ListView.builder(
                  itemCount: documentos.length,
                  itemBuilder: (context, index) {
                    final datos = documentos[index].data() as Map<String, dynamic>;
                    final idDoc = documentos[index].id;
                    final estaCompletada = datos['isDone'] ?? false;

                    return ListTile(
                      leading: Checkbox(
                        value: estaCompletada,
                        onChanged: (_) => _cambiarEstadoTarea(idDoc, estaCompletada),
                      ),
                      title: Text(
                        datos['title'] ?? '',
                        style: TextStyle(
                          decoration: estaCompletada
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _eliminarTarea(idDoc),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}