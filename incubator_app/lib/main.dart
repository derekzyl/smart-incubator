import 'package:flutter/material.dart';
import 'package:incubator_app/services/incubator_service.dart';
import 'package:provider/provider.dart';

import 'screens/analytics_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/direct_incubator_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Use DirectIncubatorService as the source for IncubatorService interface/usage
        // NOTE: Ideally we'd implement an interface or abstract class, but for quick switch:
        // We'll provide DirectIncubatorService and modify dependent widgets if needed,
        // OR make DirectIncubatorService extend/implement IncubatorService.
        // Given complexity, let's provide DirectIncubatorService and make sure UI consumes it.
        // Wait, the UI (dashboard etc) consumes `IncubatorService`.
        // So `DirectIncubatorService` should probably implement `IncubatorService` or we swap the provider type.
        // Let's swap provider type but keep the name usually consumes if feasible.
        // Actually, easiest is to provide `DirectIncubatorService` AND alias it?
        // No, let's just use `DirectIncubatorService` and update `main.dart` imports.
        // But dashboard uses `context.read<IncubatorService>()`.
        // So I should make `DirectIncubatorService` extend `IncubatorService` or provide it AS `IncubatorService`.
        // Explicitly provide as IncubatorService so Consumers can find it
        ChangeNotifierProvider<IncubatorService>(
          create: (_) => DirectIncubatorService(),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Incubator',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const HistoryScreen(),
    const AnalyticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
