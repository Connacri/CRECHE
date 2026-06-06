import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creche/screens/auth_screen.dart';
import 'package:creche/providers/auth_provider_v2.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class FakeAuthProvider extends ChangeNotifier implements AuthProviderV2 {
  @override AppAuthState get state => AppAuthState.unauthenticated;
  @override firebase_auth.User? get currentUser => null;
  @override Map<String, dynamic>? get userData => null;
  @override String? get errorMessage => null;
  @override bool get needsEmailConfirmation => false;
  @override bool get needsProfileCompletion => false;
  @override bool get isLoading => false;
  @override Future<void> logout() async {}
  @override void clearError() {}
  @override Future<bool> checkEmailConfirmationStatus({bool forceBypass = false}) async => false;
  @override dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AuthScreen has AutofillHints and TextInputAction', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<AuthProviderV2>(
          create: (_) => FakeAuthProvider(),
          child: const AuthScreen(),
        ),
      ),
    );

    final emailFieldFinder = find.widgetWithText(TextFormField, 'Email');
    final emailTextField = tester.widget<TextField>(
      find.descendant(of: emailFieldFinder, matching: find.byType(TextField))
    );
    expect(emailTextField.autofillHints, contains(AutofillHints.email));
    expect(emailTextField.textInputAction, TextInputAction.next);

    final passwordFieldFinder = find.widgetWithText(TextFormField, 'Mot de passe');
    final passwordTextField = tester.widget<TextField>(
      find.descendant(of: passwordFieldFinder, matching: find.byType(TextField))
    );
    expect(passwordTextField.autofillHints, contains(AutofillHints.password));
    expect(passwordTextField.textInputAction, TextInputAction.done);
  });
}
