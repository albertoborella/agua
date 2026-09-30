import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'features/admin/screens/analysis_types_admin_screen.dart';
import 'features/admin/screens/sampling_frequencies_admin_screen.dart';
import 'features/admin/screens/users_admin_screen.dart';
import 'features/admin/screens/water_sources_admin_screen.dart';
import 'features/alerts/screens/alerts_screen.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/help/screens/help_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/samples/providers/lab_provider.dart';
import 'features/samples/providers/samples_provider.dart';
import 'features/samples/screens/history_screen.dart';
import 'features/samples/screens/lab_analysis_entry_screen.dart';
import 'features/samples/screens/lab_home_screen.dart';
import 'features/samples/screens/lab_samples_screen.dart';
import 'features/samples/screens/new_sample_screen.dart';
import 'features/samples/screens/pendientes_screen.dart';
import 'features/samples/screens/vencidas_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'shared/services/api_service.dart';
import 'shared/models/lab_sample.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiService(baseUrl: EnvConfig.baseUrl);
  final auth = AuthProvider(api: api);

  // Rehydrate the stored session BEFORE the first frame. `initialRoute` is
  // only read when the Navigator is created, so the session has to be resolved
  // first -- building the app first would pin it to '/login' and drop a valid
  // session on every page reload.
  await auth.init();

  // Create providers with the same API instance
  final samples = SamplesProvider(api: api);
  final lab = LabProvider(api: api);

  // `.value` because the provider already exists: creating it here would build
  // a second AuthProvider with an empty session.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<SamplesProvider>.value(value: samples),
        ChangeNotifierProvider<LabProvider>.value(value: lab),
      ],
      child: const AguaApp(),
    ),
  );
}

class AguaApp extends StatelessWidget {
  const AguaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // `main()` guarantees the session is already resolved at this point.
    final isAuthenticated =
        context.select<AuthProvider, bool>((auth) => auth.isAuthenticated);

    return MaterialApp(
      title: 'Agua',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: isAuthenticated ? '/role-home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/role-home': (context) => const RoleBasedHome(),
        '/home': (context) => const HomeScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/new-sample': (context) => const NewSampleScreen(),
        '/history': (context) => const HistoryScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/pendientes': (context) => const PendientesScreen(),
        '/vencidas': (context) => const VencidasScreen(),
        '/help': (context) => const HelpScreen(),
        '/admin/analysis-types': (context) => const AnalysisTypesAdminScreen(),
        '/admin/users': (context) => const UsersAdminScreen(),
        '/admin/water-sources': (context) => const WaterSourcesAdminScreen(),
        '/admin/sampling-frequencies': (context) => const SamplingFrequenciesAdminScreen(),
        // Lab routes
        '/lab/home': (context) => const LabHomeScreen(),
        '/lab/samples': (context) => const LabSamplesScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle LabSamplesScreen with arguments
        if (settings.name == '/lab/samples') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => LabSamplesScreen(
              estadoAnalisis: args?['estadoAnalisis'] as String?,
              tipoAnalisisCodigo: args?['tipoAnalisisCodigo'] as String?,
            ),
          );
        }
        // Handle LabAnalysisEntryScreen with sample argument
        if (settings.name == '/lab/analyze') {
          final sample = settings.arguments as LabSample?;
          if (sample != null) {
            return MaterialPageRoute(
              builder: (context) => LabAnalysisEntryScreen(sample: sample),
            );
          }
        }
        return null;
      },
    );
  }
}

/// Role-based home screen that redirects to the appropriate home based on user role.
class RoleBasedHome extends StatelessWidget {
  const RoleBasedHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.user;
        final role = user?.rol ?? 'OPERARIO';

        // Redirect based on role
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          switch (role) {
            case 'LABORATORISTA':
              Navigator.pushReplacementNamed(context, '/lab/home');
              break;
            case 'ADMIN':
            case 'OPERARIO':
            default:
              Navigator.pushReplacementNamed(context, '/home');
              break;
          }
        });

        // Show loading while redirecting
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('Cargando ${role.toLowerCase()}...'),
              ],
            ),
          ),
        );
      },
    );
  }
}