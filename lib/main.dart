import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/auth_wrapper.dart';
import 'features/credentials/screens/credentials_list_screen.dart';

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
      home: const AuthWrapper(
        child: CredentialsListScreen(),
      ),
    );
  }
} 