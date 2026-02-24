import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.indigo,
    scaffoldBackgroundColor: Colors.white,
    textTheme: GoogleFonts.ibmPlexSansKrTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: GoogleFonts.ibmPlexSansKr(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    useMaterial3: true,
  );

  static const Color Q1Color = Colors.green;  // High Value, High Urgency
  static const Color Q2Color = Colors.orange; // Low Value, High Urgency
  static const Color Q3Color = Colors.grey;   // Low Value, Low Urgency
  static const Color Q4Color = Colors.blue;   // High Value, Low Urgency
}
