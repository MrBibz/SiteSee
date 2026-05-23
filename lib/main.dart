// lib/main.dart

import 'package:flutter/material.dart';

void main() {
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
  // L'état local de la page
  int _compteur = 0;
  final List<String> _elements = ['Flutter', 'Dart', 'Android Studio'];

  void _incrementer() {
    setState(() {
      _compteur++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre du haut
      appBar: AppBar(
        title: const Text('Mon App'),
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
            // Section compteur
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Compteur :',
                      style: TextStyle(fontSize: 18),
                    ),
                    Text(
                      '$_compteur',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ],
                ),
              ),
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
        // La flèche "retour" est ajoutée automatiquement
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