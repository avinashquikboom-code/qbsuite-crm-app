import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/shared/views/auth/login_view.dart';
import 'package:quickboom_app/shared/views/splash_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Login entry point tests', () {
    testWidgets('opens the employee login without a role picker', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: LoginView())),
      );
      await tester.pumpAndSettle();

      expect(find.text('EMPLOYEE WORKFORCE PORTAL'), findsOneWidget);
      expect(find.text('CUSTOMER WORKFORCE PORTAL'), findsNothing);
      expect(find.text('Change Role'), findsNothing);
      expect(find.text('Customer'), findsNothing);
    });

    testWidgets('customer role requests resolve to employee login', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginView(initialRole: MobileUserRole.customer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('EMPLOYEE WORKFORCE PORTAL'), findsOneWidget);
      expect(find.text('CUSTOMER WORKFORCE PORTAL'), findsNothing);
      expect(find.text('Customer'), findsNothing);
    });
  });

  group('SplashView Error and Retry Tests', () {
    testWidgets(
      'SplashView displays startup error and retry options when error is present',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const SplashView(error: 'Network connectivity failed'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Startup Connection Issue'), findsOneWidget);
        expect(find.text('Network connectivity failed'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.text('Continue to Login'), findsOneWidget);
      },
    );
  });
}
