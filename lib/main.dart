import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'providers/task_provider.dart';
import 'core/theme.dart';

void main() {
  runApp(const QuadrantiApp());
}

class QuadrantiApp extends StatelessWidget {
  const QuadrantiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: MaterialApp(
        title: 'Quadranti',
        theme: AppTheme.lightTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
