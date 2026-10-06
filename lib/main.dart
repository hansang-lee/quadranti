import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/task_provider.dart';
import 'providers/auth_provider.dart';
import 'core/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final auth = AuthProvider();
  final tasks = TaskProvider();
  // Load the signed-in user's tasks whenever the user changes.
  auth.addListener(() => tasks.setUser(auth.currentUser?.id));
  auth.checkAuthState();

  runApp(QuadrantiApp(auth: auth, tasks: tasks));
}

class QuadrantiApp extends StatelessWidget {
  const QuadrantiApp({super.key, required this.auth, required this.tasks});

  final AuthProvider auth;
  final TaskProvider tasks;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tasks),
        ChangeNotifierProvider.value(value: auth),
      ],
      child: MaterialApp(
        title: 'Quadranti',
        theme: AppTheme.lightTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return auth.isLoggedIn ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
