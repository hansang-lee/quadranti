import 'package:flutter/material.dart';

class AppTheme {
  /// Bundled in assets/fonts (see pubspec.yaml).
  static const String fontFamily = 'IBMPlexSansKR';

  static final ThemeData lightTheme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
    scaffoldBackgroundColor: Colors.white,
    fontFamily: fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
      // An explicit style does not inherit ThemeData.fontFamily.
      titleTextStyle: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    useMaterial3: true,
  );

  static const Color q1Color = Colors.green;  // Focus: high value, really urgent
  static const Color q2Color = Colors.orange; // Caution: low value, urgent
  static const Color q3Color = Colors.grey;   // Eliminate: low value, not urgent
  static const Color q4Color = Colors.blue;   // Plan: high value, not urgent
}
