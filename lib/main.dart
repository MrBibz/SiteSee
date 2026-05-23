import 'package:flutter/material.dart';
import 'package:site_see/pages/camera_page.dart';
import 'package:site_see/pages/map_page.dart';

void main() {
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
        "/map": (context) => const MapPage(),
      }
    );
  }
}
