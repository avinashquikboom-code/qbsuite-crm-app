import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/company_admin/views/company_admin_main_view.dart';
import 'package:quickboom_app/roles/company_admin/widgets/admin_app_drawer.dart';
import 'package:quickboom_app/roles/employee/views/dashboard_view.dart';
import 'package:quickboom_app/shared/widgets/app_drawer.dart';

void main() {
  group('Left-Side Drawer (Scaffold.drawer) Tests for All Roles', () {
    testWidgets('Employee Menu Button opens Left Drawer (Scaffold.drawer)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const DashboardView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scaffoldState = tester.state<ScaffoldState>(
        find.byType(Scaffold).first,
      );
      expect(scaffoldState.hasDrawer, isTrue);
      expect(scaffoldState.hasEndDrawer, isFalse);
      expect(scaffoldState.isDrawerOpen, isFalse);
      expect(scaffoldState.isEndDrawerOpen, isFalse);

      // Tap Menu button in header to open left drawer
      final menuBtn = find.byTooltip('Open Menu');
      expect(menuBtn, findsOneWidget);
      await tester.tap(menuBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Left Drawer is open and endDrawer is not open
      expect(scaffoldState.isDrawerOpen, isTrue);
      expect(scaffoldState.isEndDrawerOpen, isFalse);

      // Verify Employee Drawer contents
      expect(find.byType(AppDrawer), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('HRM & WORKPLACE'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Attendance'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Requests & Leaves'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Logout'),
        ),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Company Admin Menu Button opens Left Drawer (Scaffold.drawer)',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const CompanyAdminMainView(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final scaffoldState = tester.state<ScaffoldState>(
          find.byType(Scaffold).first,
        );
        expect(scaffoldState.hasDrawer, isTrue);
        expect(scaffoldState.hasEndDrawer, isFalse);
        expect(scaffoldState.isDrawerOpen, isFalse);
        expect(scaffoldState.isEndDrawerOpen, isFalse);

        // Tap Menu button in AppBar to open left drawer
        final menuBtn = find.byTooltip('Open Menu');
        expect(menuBtn, findsOneWidget);
        await tester.tap(menuBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify Left Drawer is open and endDrawer is not open
        expect(scaffoldState.isDrawerOpen, isTrue);
        expect(scaffoldState.isEndDrawerOpen, isFalse);

        // Verify Company Admin Drawer contents
        expect(find.byType(AdminAppDrawer), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('PRIMARY MODULES'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Dashboard Home'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Clients & Accounts'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Work / SSM Management'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Calendar & Schedule'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('COMPANY OPERATIONS'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Employees & Teams'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Leads & Pipeline'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Client Visits'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Data Capture'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Proposals & Quotes'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Subscription Packages'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('TEAM MANAGEMENT'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Roles'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Work Types'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Team Members'),
          ),
          findsOneWidget,
        );

        await tester.scrollUntilVisible(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Logout'),
          ),
          100,
          scrollable: find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Performance Reports'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('System Audit Logs'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Company Profile'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Settings & Config'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminAppDrawer),
            matching: find.text('Logout'),
          ),
          findsOneWidget,
        );

        expect(tester.takeException(), isNull);
      },
    );

    final screenWidths = [320.0, 360.0, 375.0, 390.0, 414.0, 430.0];

    for (final width in screenWidths) {
      testWidgets(
        'Renders all 3 role left drawers (Scaffold.drawer) at ${width}px without overflow',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          // 1. Employee Drawer (Scaffold.drawer)
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const Scaffold(
                  drawer: AppDrawer(),
                  body: Text('Employee'),
                ),
              ),
            ),
          );
          final empScaffold = tester.state<ScaffoldState>(
            find.byType(Scaffold),
          );
          empScaffold.openDrawer();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(AppDrawer), findsOneWidget);
          expect(empScaffold.isDrawerOpen, isTrue);
          expect(empScaffold.isEndDrawerOpen, isFalse);
          expect(tester.takeException(), isNull);

          // 3. Admin Drawer (Scaffold.drawer)
          await tester.pumpWidget(
            ProviderScope(
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const Scaffold(
                  drawer: AdminAppDrawer(),
                  body: Text('Admin'),
                ),
              ),
            ),
          );
          final adminScaffold = tester.state<ScaffoldState>(
            find.byType(Scaffold),
          );
          adminScaffold.openDrawer();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byType(AdminAppDrawer), findsOneWidget);
          expect(adminScaffold.isDrawerOpen, isTrue);
          expect(adminScaffold.isEndDrawerOpen, isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
