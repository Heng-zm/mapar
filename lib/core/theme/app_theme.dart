import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const _seed = Color(0xFF2563EB);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF7F8FC),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF070B14),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      ),
    );
  }
}
