import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:creche/main.dart';
import 'package:creche/providers/locale_provider.dart';
import 'package:creche/providers/auth_provider_v2.dart';
import 'package:creche/providers/child_enrollment_provider.dart';
import 'package:creche/providers/course_provider_complete.dart';

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

    when(() => mockLocaleProvider.locale).thenReturn(const Locale('fr'));
    when(() => mockAuthProvider.state).thenReturn(AppAuthState.initial);
    when(() => mockAuthProvider.isLoading).thenReturn(false);
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
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

    expect(find.byType(CrecheApp), findsOneWidget);
  });
}
