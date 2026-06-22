import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/ar/screens/ar_screen.dart';
import 'features/map/screens/map_screen.dart';
import 'features/saved_places/screens/saved_places_screen.dart';
import 'features/settings/controllers/settings_controller.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/trips/screens/trips_screen.dart';

class MappARApp extends StatelessWidget {
  const MappARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsController>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'Mapp AR',
          debugShowCheckedModeBanner: false,
          themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: const MappShell(),
        );
      },
    );
  }
}

class MappShell extends StatefulWidget {
  const MappShell({super.key});

  @override
  State<MappShell> createState() => _MappShellState();
}

class _MappShellState extends State<MappShell> {
  int _index = 0;

  final _screens = const [
    MapScreen(),
    ARScreen(),
    SavedPlacesScreen(),
    TripsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        height: 68,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.view_in_ar_outlined), selectedIcon: Icon(Icons.view_in_ar), label: 'AR'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), selectedIcon: Icon(Icons.bookmark), label: 'Saved'),
          NavigationDestination(icon: Icon(Icons.route_outlined), selectedIcon: Icon(Icons.route), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
