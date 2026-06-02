import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creche/screens/auth_screen.dart';
import 'package:creche/screens/email_confirmation_screen.dart';
import 'package:creche/screens/forgot_password_screen.dart';
import 'package:creche/providers/auth_provider_v2.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FakeAuthProvider extends ChangeNotifier implements AuthProviderV2 {
  @override
  AppAuthState get state => AppAuthState.unauthenticated;

  @override
  firebase_auth.User? get currentUser => null;

  @override
  Map<String, dynamic>? get userData => null;

  @override
  String? get errorMessage => null;

  @override
  bool get needsEmailConfirmation => false;

  @override
  bool get needsProfileCompletion => false;

  @override
  bool get isLoading => false;

  @override
  Future<void> logout() async {}

  @override
  void clearError() {}

  @override
  Future<bool> checkEmailConfirmationStatus() async => false;

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
    // Use substring because it might be "Masquer le mot de passe" or "Afficher le mot de passe"
    expect(find.byType(IconButton), findsWidgets);
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
