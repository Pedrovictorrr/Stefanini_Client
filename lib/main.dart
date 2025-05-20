import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/project_list_screen.dart';
import 'screens/weather_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Projetos App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/projects') {
          return ProjectListScreen.routeFromArgs(settings);
        }
        if (settings.name == '/weather') {
          final args = settings.arguments as Map?;
          final token = args != null && args['token'] != null ? args['token'] as String : '';
          return MaterialPageRoute(
            builder: (_) => WeatherScreen(token: token),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
