import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:family_safety_tracker/services/auth_service.dart';
import 'package:family_safety_tracker/screens/auth/login_screen.dart';
import 'package:family_safety_tracker/screens/home/map_screen.dart';
import 'package:family_safety_tracker/screens/home/family_screen.dart';
import 'package:family_safety_tracker/screens/home/settings_screen.dart';

class FamilySafetyApp extends StatelessWidget {
  const FamilySafetyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'Family Safety Tracker',
        theme: ThemeData(
          colorSchemeSeed: Colors.blue,
          useMaterial3: true,
        ),
        home: StreamBuilder(
          stream: AuthService().authState,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasData) {
              return const MainShell();
            }
            return const LoginScreen();
          },
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    MapScreen(),
    FamilyScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.people), label: 'Family'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
