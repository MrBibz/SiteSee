import 'package:flutter/material.dart';
import 'package:site_see/pages/camera_page.dart';
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

  runApp(const SiteSee());
}

class SiteSee extends StatelessWidget {
  const SiteSee({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SiteSee",
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => const CameraPage(),
      }
    );
  }
}
