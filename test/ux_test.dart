import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creche/screens/auth_screen.dart';
import 'package:creche/screens/email_confirmation_screen.dart';
import 'package:creche/screens/forgot_password_screen.dart';
import 'package:creche/providers/auth_provider_v2.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Use a truly fake provider that doesn't call Supabase.instance
class FakeAuthProvider extends ChangeNotifier implements AuthProviderV2 {
  @override
  AppAuthState get state => AppAuthState.unauthenticated;

  @override
  User? get currentUser => null;

  @override
  Map<String, dynamic>? get userData => null;

  @override
  String? get errorMessage => null;

  @override
  bool get needsEmailConfirmation => false;

  @override
  bool get needsProfileCompletion => false;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isLoading => false;

  @override
  Future<void> logout() async {}

  @override
  void clearError() {}

  @override
  Future<bool> checkEmailConfirmationStatus() async => false;

  // Implement other necessary methods with no-ops or default values
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AuthScreen has tooltip for password visibility', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProviderV2>(
          create: (_) => FakeAuthProvider(),
          child: const AuthScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.byTooltip('Afficher le mot de passe'), findsOneWidget);
  });

  testWidgets('ForgotPasswordScreen has tooltip for back button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ForgotPasswordScreen(),
      ),
    );

    expect(find.byTooltip('Retour'), findsOneWidget);
  });

  testWidgets('EmailConfirmationScreen has verify status button', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProviderV2>(
          create: (_) => FakeAuthProvider(),
          child: const EmailConfirmationScreen(),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('J\'ai confirmé mon email'), findsOneWidget);
  });
}
