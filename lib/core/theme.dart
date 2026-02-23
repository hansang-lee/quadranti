import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    useMaterial3: true,
  );
  
  static const Color Q1Color = Colors.green;  // High Value, High Urgency
  static const Color Q2Color = Colors.orange; // Low Value, High Urgency
  static const Color Q3Color = Colors.grey;   // Low Value, Low Urgency
  static const Color Q4Color = Colors.blue;   // High Value, Low Urgency
}
