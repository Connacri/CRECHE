import 'package:flutter/material.dart';
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
      ],
      child: const CrecheApp(),
    ),
  );
}

class CrecheApp extends StatelessWidget {
  const CrecheApp({super.key});

  @override
  Widget build(BuildContext context) {
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
}
