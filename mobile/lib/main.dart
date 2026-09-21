import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'shared/services/api_service.dart';

void main() {
  runApp(const AguaApp());
}

class AguaApp extends StatelessWidget {
  const AguaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final api = ApiService(baseUrl: 'http://10.0.2.2:8000');

    return ChangeNotifierProvider(
      create: (_) => AuthProvider(api: api)..init(),
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Agua',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.system,
            initialRoute: auth.isAuthenticated ? '/home' : '/login',
            routes: {
              '/login': (context) => const LoginScreen(),
              '/home': (context) => const HomeScreen(),
              // TODO: add remaining routes
            },
          );
        },
      ),
    );
  }
}
