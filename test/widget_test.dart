import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:creche/main.dart';
import 'package:creche/providers/locale_provider.dart';
import 'package:creche/providers/auth_provider_v2.dart';
import 'package:creche/providers/child_enrollment_provider.dart';
import 'package:creche/providers/course_provider_complete.dart';

// Create mock classes
class MockLocaleProvider extends Mock implements LocaleProvider {}
class MockAuthProviderV2 extends Mock implements AuthProviderV2 {}
class MockChildEnrollmentProvider extends Mock implements ChildEnrollmentProvider {}
class MockCourseProvider extends Mock implements CourseProvider {}

void main() {
  late MockLocaleProvider mockLocaleProvider;
  late MockAuthProviderV2 mockAuthProvider;
  late MockChildEnrollmentProvider mockChildEnrollmentProvider;
  late MockCourseProvider mockCourseProvider;

  setUp(() {
    mockLocaleProvider = MockLocaleProvider();
    mockAuthProvider = MockAuthProviderV2();
    mockChildEnrollmentProvider = MockChildEnrollmentProvider();
    mockCourseProvider = MockCourseProvider();

    // Stub necessary methods and getters
    when(() => mockLocaleProvider.locale).thenReturn(const Locale('fr'));
    when(() => mockAuthProvider.state).thenReturn(AppAuthState.initial);
    when(() => mockAuthProvider.isAuthenticated).thenReturn(false);
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Use ChangeNotifierProvider.value to provide the mock instances
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<LocaleProvider>.value(value: mockLocaleProvider),
          ChangeNotifierProvider<AuthProviderV2>.value(value: mockAuthProvider),
          ChangeNotifierProvider<ChildEnrollmentProvider>.value(value: mockChildEnrollmentProvider),
          ChangeNotifierProvider<CourseProvider>.value(value: mockCourseProvider),
        ],
        child: const CrecheApp(),
      ),
    );

    // Verify that the app starts (finds the CrecheApp)
    expect(find.byType(CrecheApp), findsOneWidget);
  });
}
