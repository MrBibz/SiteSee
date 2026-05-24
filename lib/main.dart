import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:site_see/widgets/app_theme.dart';
import 'services/profile_service.dart';
import 'services/notification_service.dart';
import 'pages/home_page.dart';
import 'pages/photo_page.dart';
import 'pages/map_page.dart';
import 'widgets/bottom_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ProfileService.instance.initialize();
  await NotificationService.instance.initialize();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SiteSee, where to see a Site, and some even hidden',
      debugShowCheckedModeBanner: false,
      theme: buildSiteSeeTheme(),
      home: const MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;

  final GlobalKey<MapPageState> _mapPageKey = GlobalKey<MapPageState>();

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(
        onPhotoTap: (lat, lng) {
          setState(() => _selectedIndex = 2);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapPageKey.currentState?.moveMapToCoordinates(lat, lng);
          });
        },
      ),
      const PhotoPage(),
      MapPage(key: _mapPageKey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }
}