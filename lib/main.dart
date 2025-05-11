import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/credentials/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Credentials Store',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _authenticated = false;

  void _onAuthenticated() {
    setState(() {
      _authenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_authenticated) {
      return AuthScreen(onAuthenticated: _onAuthenticated);
    } else {
      return const HomeScreen();
    }
  }
} 