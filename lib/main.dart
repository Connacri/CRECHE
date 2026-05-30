import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'screens/auth_wrapper.dart';
import 'providers/locale_provider.dart';
import 'providers/auth_provider_v2.dart';
import 'providers/child_enrollment_provider.dart';
import 'providers/course_provider_complete.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProviderV2()),
        ChangeNotifierProvider(create: (_) => ChildEnrollmentProvider()),
        ChangeNotifierProvider(create: (_) => CourseProvider()),
=======
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'theme/app_theme.dart';
import 'services/mock_services.dart';
import 'screens/login_screen.dart';
import 'screens/parent_dashboard.dart';
import 'screens/admin_dashboard.dart';
import 'models/app_models.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockAuthService()),
        Provider(create: (_) => MockDatabaseService()),
>>>>>>> 37b0edb
      ],
      child: const CrecheApp(),
    ),
  );
}

class CrecheApp extends StatelessWidget {
  const CrecheApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp(
          title: 'Crèche App',
          debugShowCheckedModeBanner: false,
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('fr'),
            Locale('ar'),
          ],
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.system,
          home: const AuthWrapper(),
        );
      },
    );
  }
=======
    final authService = context.watch<MockAuthService>();

    return MaterialApp(
      title: 'Crèche',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _getHome(authService),
    );
  }

  Widget _getHome(MockAuthService auth) {
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }
    if (auth.currentUser?.role == UserRole.admin) {
      return const AdminDashboard();
    }
    return const ParentDashboard();
  }
>>>>>>> 37b0edb
}
