import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/employee/views/dashboard_view.dart';
import 'package:quickboom_app/roles/employee/views/profile_view.dart';

void main() {
  group('Dashboard and ProfileView Tests', () {
    testWidgets('DashboardView renders 5-tab employee shell without crashing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardView(),
          ),
        ),
      );
      expect(find.byType(DashboardView), findsOneWidget);
    });

    testWidgets(
      'ProfileView renders menu card and tiles without Material assertion errors',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: ProfileView()),
          ),
        );

        expect(find.byType(ProfileView), findsOneWidget);
        expect(find.text('My Attendance Logs'), findsOneWidget);
        expect(find.text('My Field Visits'), findsOneWidget);
        expect(find.text('Salary Slips & Payslips'), findsOneWidget);
      },
    );

    testWidgets(
      'Dashboard navigation to Profile tab renders ProfileView cleanly',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DashboardView(),
            ),
          ),
        );

        // Tap Profile tab
        await tester.tap(find.text('Profile'));
        await tester.pumpAndSettle();

        expect(find.byType(ProfileView), findsOneWidget);
        expect(find.text('My Attendance Logs'), findsOneWidget);
      },
    );
  });
}
