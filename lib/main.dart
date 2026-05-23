// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the connection between the database and the app
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Main code running
  runApp(const MyApp());
}

// Widget racine — configure le thème et la navigation
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mon App Flutter',
      debugShowCheckedModeBanner: false, // retire le ruban "debug"
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

// ─── PAGE PRINCIPALE ────────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // L'état local pour d'autres éléments
  final List<String> _elements = ['Flutter', 'Dart', 'Android Studio'];

  // Référence au document Firestore
  final DocumentReference _counterRef = 
      FirebaseFirestore.instance.collection('app_data').doc('counter');

  void _incrementer() {
    // Utilisation d'une transaction ouFieldValue.increment pour être sûr du résultat
    _counterRef.set({
      'value': FieldValue.increment(1)
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre du haut
      appBar: AppBar(
        title: const Text('Mon App (Firebase)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Navigation vers une autre page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DetailPage()),
              );
            },
          ),
        ],
      ),

      // Corps de la page
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section compteur avec StreamBuilder pour le temps réel
            StreamBuilder<DocumentSnapshot>(
              stream: _counterRef.snapshots(),
              builder: (context, snapshot) {
                int count = 0;
                if (snapshot.hasData && snapshot.data!.exists) {
                  count = (snapshot.data!.data() as Map<String, dynamic>)['value'] ?? 0;
                }

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Compteur (Cloud) :',
                          style: TextStyle(fontSize: 18),
                        ),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Text(
                            '$count',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24), // espace vertical

            // Section liste
            const Text(
              'Technologies :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Liste dynamique
            Expanded(
              child: ListView.builder(
                itemCount: _elements.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.indigo),
                    title: Text(_elements[index]),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Sélectionné : ${_elements[index]}')),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bouton flottant
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementer,
        tooltip: 'Incrémenter',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ─── PAGE DE DÉTAIL ─────────────────────────────────────────────

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.flutter_dash, size: 80, color: Colors.indigo),
            const SizedBox(height: 16),
            const Text(
              'Page de détail',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Navigation Flutter, c\'est simple !'),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context), // retour
              icon: const Icon(Icons.arrow_back),
              label: const Text('Retour'),
            ),
          ],
        ),
      ),
    );
  }
}
