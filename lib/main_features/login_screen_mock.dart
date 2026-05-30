import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mock_services.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    final success = await context.read<MockAuthService>().login(
      _emailController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);
    if (success && mounted) {
      // Navigation will be handled by the router/wrapper
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.softBlue, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/8e16ab25c9b6075a09c2d7990984e21d.jpg', height: 150),
                const SizedBox(height: 20),
                Text(
                  'Bienvenue à la Crèche',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Un petit nid douillet pour vos enfants'),
                const SizedBox(height: 40),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Mot de passe',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Se connecter'),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('Ou continuer avec', style: TextStyle(color: AppColors.textLight)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => _emailController.text = 'parent@example.com', // Demo shortcut
                  icon: const Icon(Icons.g_mobiledata, size: 30),
                  label: const Text('Google Sign-In'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
                TextButton(
                  onPressed: () => _emailController.text = 'admin@creche.com', // Demo shortcut
                  child: const Text('Accès Admin (Démo)'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {}, // Link to APK download in real app
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Télécharger l\'App'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.softGreen,
                    foregroundColor: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
