import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider_v2.dart';
import '../widgets/glass_card.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late TabController _tabController;
  bool _obscurePassword = true;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = context.read<AuthProviderV2>();
    final result = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (result.success) {
      _showSnackBar('Connexion réussie !', isError: false);
    } else {
      _showSnackBar(result.message ?? 'Erreur de connexion', isError: true);
    }
  }

  Future<void> _handleSignup() async {
    if (_selectedRole == null) {
      _showSnackBar('Veuillez sélectionner votre rôle', isError: true);
      return;
    }
    final authProvider = context.read<AuthProviderV2>();
    final result = await authProvider.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole!,
    );
    if (!mounted) return;
    if (result.success) {
      _showSnackBar('Compte créé avec succès !', isError: false);
    } else {
      if (result.errorCode == 'email_exists') {
        _showSnackBar(
          result.message!,
          isError: false,
          action: SnackBarAction(
            label: 'Connexion',
            textColor: Colors.white,
            onPressed: () => _tabController.animateTo(0),
          ),
        );
      } else {
        _showSnackBar(result.message ?? 'Erreur d\'inscription', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/forest_bg_zoomed.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Darker overlay for readability
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildAuthCard(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
      child: GlassCard(
        padding: const EdgeInsets.all(32),
        opacity: 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTabBar(colorScheme),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _tabController.index == 1 ? 480 : 250,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginForm(),
                  _buildSignupForm(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildForgotPasswordButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/creche_logo.png',
          height: 80,
        ),
        const SizedBox(height: 16),
        Text(
          'Bienvenue chez CRECHE',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        Text(
          'Votre espace de sérénité',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(26),
        ),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Connexion'),
          Tab(text: 'Inscription'),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildRoleSelector(),
          const SizedBox(height: 24),
          _buildSignupButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _obscurePassword ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) => v == null || v.length < 6 ? '6 caractères min.' : null,
    );
  }

  Widget _buildRoleSelector() {
    final roles = [
      {'value': 'parent', 'label': 'Parent', 'icon': Icons.family_restroom},
      {'value': 'coach', 'label': 'Coach', 'icon': Icons.sports},
      {'value': 'school', 'label': 'École', 'icon': Icons.school},
      {'value': 'autres', 'label': 'Autres', 'icon': Icons.more_horiz},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Choisissez votre profil',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: roles.map((role) {
            final isSelected = _selectedRole == role['value'];
            return ChoiceChip(
              label: Text(role['label'] as String),
              avatar: Icon(
                role['icon'] as IconData,
                size: 18,
                color: isSelected ? Colors.white : null,
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedRole = selected ? role['value'] as String : null);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProviderV2>(
      builder: (context, auth, _) {
        return FilledButton(
          onPressed: auth.isLoading ? null : _handleLogin,
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
          child: auth.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Se connecter'),
        );
      },
    );
  }

  Widget _buildSignupButton() {
    return Consumer<AuthProviderV2>(
      builder: (context, auth, _) {
        return FilledButton(
          onPressed: auth.isLoading || _selectedRole == null ? null : _handleSignup,
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
          child: auth.isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Créer mon compte'),
        );
      },
    );
  }

  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
        );
      },
      child: const Text('Mot de passe oublié ?'),
    );
  }

  void _showSnackBar(String message, {required bool isError, SnackBarAction? action}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        action: action,
      ),
    );
  }
}
