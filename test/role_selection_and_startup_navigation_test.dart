import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/shared/views/auth/role_selection_view.dart';
import 'package:quickboom_app/shared/views/splash_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('RoleSelectionView Tests', () {
    testWidgets('Renders Customer and Employee role cards cleanly without Other role', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RoleSelectionView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('QB SUITE'), findsOneWidget);
      expect(find.text('Select your account type to continue'), findsOneWidget);
      expect(find.text('Customer'), findsOneWidget);
      expect(find.text('Employee'), findsOneWidget);
      expect(find.text('Other'), findsNothing);
    });

    testWidgets('Tapping Customer navigates to LoginView with Customer role', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RoleSelectionView(),
        ),
      );
      await tester.pumpAndSettle();

      final customerCard = find.text('Customer');
      expect(customerCard, findsOneWidget);

      await tester.tap(customerCard);
      await tester.pumpAndSettle();

      // Should be in LoginView with Customer workforce subtitle and Change Role button
      expect(find.text('CUSTOMER WORKFORCE PORTAL'), findsOneWidget);
      expect(find.text('Change Role'), findsOneWidget);
    });

    testWidgets('Tapping Employee navigates to LoginView with Employee role', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const RoleSelectionView(),
        ),
      );
      await tester.pumpAndSettle();

      final employeeCard = find.text('Employee');
      expect(employeeCard, findsOneWidget);

      await tester.tap(employeeCard);
      await tester.pumpAndSettle();

      // Should be in LoginView with Employee workforce subtitle and Change Role button
      expect(find.text('EMPLOYEE WORKFORCE PORTAL'), findsOneWidget);
      expect(find.text('Change Role'), findsOneWidget);
    });
  });

  group('SplashView Error and Retry Tests', () {
    testWidgets('SplashView displays startup error and retry options when error is present', (tester) async {
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
      expect(find.text('Continue to Role Selection'), findsOneWidget);
    });
  });
}
