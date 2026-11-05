import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/shared/services/onboarding_service.dart';
import 'package:quickboom_app/shared/views/auth/login_view.dart';
import 'package:quickboom_app/shared/views/onboarding_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('OnboardingService Tests', () {
    test('Initial onboarding state is false', () async {
      final service = OnboardingService();
      final isCompleted = await service.isCompleted();
      expect(isCompleted, isFalse);
    });

    test('complete() marks onboarding as completed', () async {
      final service = OnboardingService();
      await service.complete();
      final isCompleted = await service.isCompleted();
      expect(isCompleted, isTrue);
    });

    test('reset() resets onboarding state to false', () async {
      final service = OnboardingService();
      await service.complete();
      expect(await service.isCompleted(), isTrue);

      await service.reset();
      expect(await service.isCompleted(), isFalse);
    });
  });

  group('OnboardingView Widget Tests', () {
    testWidgets('Renders Page 1 Welcome content and Skip button', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const OnboardingView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to QuikBoom'), findsOneWidget);
      expect(
        find.text('Manage your work easily from one place.'),
        findsOneWidget,
      );
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Tapping Next navigates across 5 pages to Get Started', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.lightTheme, home: const OnboardingView()),
      );
      await tester.pumpAndSettle();

      // Page 1: Welcome
      expect(find.text('Welcome to QuikBoom'), findsOneWidget);

      // Tap Next -> Page 2: Attendance
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Smart Attendance'), findsOneWidget);

      // Tap Next -> Page 3: Work Management
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Easy Work Management'), findsOneWidget);

      // Tap Next -> Page 4: Data Capture
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Data Capture'), findsOneWidget);

      // Tap Next -> Page 5: Payroll
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Payroll'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets(
      'Tapping Skip completes onboarding and navigates to LoginView',
      (WidgetTester tester) async {
        final service = OnboardingService();
        expect(await service.isCompleted(), isFalse);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const OnboardingView()),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        expect(await service.isCompleted(), isTrue);
        expect(find.byType(LoginView), findsOneWidget);
      },
    );

    testWidgets(
      'Tapping Get Started on last page completes onboarding and navigates to LoginView',
      (WidgetTester tester) async {
        final service = OnboardingService();
        expect(await service.isCompleted(), isFalse);

        await tester.pumpWidget(
          MaterialApp(theme: AppTheme.lightTheme, home: const OnboardingView()),
        );
        await tester.pumpAndSettle();

        // Advance to last page
        for (int i = 0; i < 4; i++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }

        expect(find.text('Get Started'), findsOneWidget);
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        expect(await service.isCompleted(), isTrue);
        expect(find.byType(LoginView), findsOneWidget);
      },
    );
  });
}
