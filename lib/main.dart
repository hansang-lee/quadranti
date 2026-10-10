import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'providers/task_provider.dart';
import 'providers/auth_provider.dart';
import 'core/theme.dart';
import 'services/prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(createApp());
}

/// The app with its providers wired: the signed-in user's tasks load
/// whenever the user changes. Scenario tests call it with their own [clock].
/// Hive must already be initialised.
QuadrantiApp createApp({DateTime Function()? clock}) {
  final auth = AuthProvider();
  final tasks = TaskProvider(clock: clock);
  auth.addListener(() => tasks.setUser(auth.currentUser?.id));
  auth.checkAuthState();
  return QuadrantiApp(auth: auth, tasks: tasks, prefs: HivePrefs());
}

class QuadrantiApp extends StatelessWidget {
  const QuadrantiApp({super.key, required this.auth, required this.tasks, required this.prefs});

  final AuthProvider auth;
  final TaskProvider tasks;
  final Prefs prefs;

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
        darkTheme: AppTheme.darkTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return auth.isLoggedIn ? HomeScreen(prefs: prefs) : const LoginScreen();
          },
        ),
      ),
    );
  }
}
