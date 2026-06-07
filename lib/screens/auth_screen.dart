import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/auth_provider_v2.dart';
import '../widgets/glass_card.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
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

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProviderV2>();
    final result = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (result.success) {
      _showSnackBar('Connexion Google réussie !', isError: false);
    } else {
      _showSnackBar(result.message ?? 'Erreur connexion Google', isError: true);
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
      _showSnackBar(result.message ?? 'Erreur d\'inscription', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/forest_bg_zoomed.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.blueGrey),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
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
              height: _tabController.index == 1 ? 520 : 330,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginForm(),
                  _buildSignupForm(),
                ],
              ),
            ),
            const SizedBox(height: 16),
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
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.child_care, size: 80),
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (_) => HapticFeedback.selectionClick(),
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
          const SizedBox(height: 16),
          _buildGoogleSignInButton(),
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
          const SizedBox(height: 16),
          _buildGoogleSignInButton(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email_outlined),
        suffixIcon: _emailController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _emailController.clear();
                },
              )
            : null,
      ),
      validator: (v) => v == null || !v.contains('@') ? 'Email invalide' : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
      onFieldSubmitted: (_) => _tabController.index == 0 ? _handleLogin() : _handleSignup(),
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () {
            HapticFeedback.selectionClick();
            setState(() => _obscurePassword = !_obscurePassword);
          },
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
          child: Text('Choisissez votre profil', style: Theme.of(context).textTheme.titleSmall),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roles.map((role) {
            final isSelected = _selectedRole == role['value'];
            return ChoiceChip(
              label: Text(role['label'] as String),
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
          onPressed: auth.state == AppAuthState.loading ? null : _handleLogin,
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
          child: auth.state == AppAuthState.loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Se connecter'),
        );
      },
    );
  }

  Widget _buildSignupButton() {
    return Consumer<AuthProviderV2>(
      builder: (context, auth, _) {
        return FilledButton(
          onPressed: auth.state == AppAuthState.loading ? null : _handleSignup,
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 56)),
          child: auth.state == AppAuthState.loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Créer mon compte'),
        );
      },
    );
  }

  Widget _buildGoogleSignInButton() {
    return OutlinedButton.icon(
      onPressed: _handleGoogleSignIn,
      icon: const FaIcon(FontAwesomeIcons.google, size: 20),
      label: const Text('Continuer avec Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
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

  void _showSnackBar(String message, {required bool isError}) {
    if (isError) HapticFeedback.vibrate();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
