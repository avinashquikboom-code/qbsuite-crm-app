import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/dashboard_view.dart';
import 'package:quickboom_app/roles/employee/views/sidebar_views/attendance_view.dart';
import 'package:quickboom_app/shared/widgets/app_drawer.dart';

class MockLoginStateNotifier extends LoginStateNotifier {
  final LoginState mockState;
  MockLoginStateNotifier(this.mockState);

  @override
  LoginState build() => mockState;
}

class MockWorkPermissionsNotifier extends WorkPermissionsNotifier {
  final WorkPermissionsState mockState;
  MockWorkPermissionsNotifier(this.mockState);

  @override
  WorkPermissionsState build() => mockState;

  @override
  Future<void> loadPermissions() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final employeeLoginState = LoginState(
    isInitializing: false,
    isLoggedIn: true,
    userName: 'Avinash Magar',
    employeeCode: 'EMP-777',
    userRole: 'employee',
  );

  final leadsPermissions = WorkPermissionsState(
    isLoading: false,
    permissions: const EmployeeWorkPermissions(
      role: 'employee',
      workPermissions: ['leads'],
      effectivePermissions: {'leads': true},
    ),
  );

  group('Employee Mobile Right-Side Drawer (EndDrawer) Navigation Tests', () {
    testWidgets('DashboardView has endDrawer on RIGHT and NO left drawer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          loginStateProvider.overrideWith(
            () => MockLoginStateNotifier(employeeLoginState),
          ),
          workPermissionsProvider.overrideWith(
            () => MockWorkPermissionsNotifier(leadsPermissions),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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
      // 1. Verify Scaffold has endDrawer (RIGHT) and NO left drawer
      expect(
        scaffoldState.hasEndDrawer,
        isTrue,
        reason: 'Scaffold must have endDrawer on the right',
      );
      expect(
        scaffoldState.hasDrawer,
        isFalse,
        reason: 'Scaffold must NOT have a left drawer',
      );
      expect(scaffoldState.isEndDrawerOpen, isFalse);
      expect(scaffoldState.isDrawerOpen, isFalse);

      // 2. Tap hamburger button
      final menuBtn = find.byTooltip('Open Menu');
      expect(menuBtn, findsOneWidget);
      await tester.tap(menuBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Verify RIGHT drawer opens (endDrawer) and left drawer is not open
      expect(scaffoldState.isEndDrawerOpen, isTrue);
      expect(scaffoldState.isDrawerOpen, isFalse);
      expect(find.byType(AppDrawer), findsOneWidget);

      // 4. Verify drawer position is aligned to right side of viewport
      final drawerRect = tester.getRect(find.byType(AppDrawer));
      final screenWidth = 1080 / 2.0; // 540 logical pixels
      expect(
        drawerRect.right,
        equals(screenWidth),
        reason: 'Drawer must align with the right screen edge',
      );
      expect(
        drawerRect.left > 0,
        isTrue,
        reason: 'Drawer opens from the right side towards left',
      );

      // 5. Verify all required menu items exist inside AppDrawer without redesign
      Finder inDrawer(String text) => find.descendant(
        of: find.byType(AppDrawer),
        matching: find.text(text),
      );
      expect(inDrawer('CRM WORKFLOW'), findsOneWidget);
      expect(inDrawer('Follow-ups'), findsOneWidget);
      expect(inDrawer('Proposals'), findsOneWidget);
      expect(inDrawer('Packages'), findsOneWidget);
      expect(inDrawer('Social Media Work'), findsOneWidget);
      expect(inDrawer('HRM & WORKPLACE'), findsOneWidget);
      expect(inDrawer('Attendance'), findsOneWidget);
      expect(inDrawer('Requests & Leaves'), findsOneWidget);
      expect(inDrawer('Settings'), findsOneWidget);
      expect(inDrawer('Logout'), findsOneWidget);

      // 6. Verify tapping outside (scrim / backdrop overlay) closes the drawer
      // Tap on left side of screen outside the drawer
      await tester.tapAt(const Offset(50, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        scaffoldState.isEndDrawerOpen,
        isFalse,
        reason: 'Tapping backdrop must close right-side drawer',
      );
    });

    testWidgets('Tapping menu item closes drawer and navigates', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          loginStateProvider.overrideWith(
            () => MockLoginStateNotifier(employeeLoginState),
          ),
          workPermissionsProvider.overrideWith(
            () => MockWorkPermissionsNotifier(leadsPermissions),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
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

      // Open right drawer
      scaffoldState.openEndDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scaffoldState.isEndDrawerOpen, isTrue);

      // Tap on Attendance menu item inside the drawer
      final attendanceInDrawer = find.descendant(
        of: find.byType(AppDrawer),
        matching: find.text('Attendance'),
      );
      expect(attendanceInDrawer, findsOneWidget);
      await tester.tap(attendanceInDrawer);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify drawer closed and navigated to AttendanceView
      expect(scaffoldState.isEndDrawerOpen, isFalse);
      expect(find.byType(AttendanceView), findsOneWidget);
    });

    testWidgets('Pop / back button closes right-side endDrawer', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          loginStateProvider.overrideWith(
            () => MockLoginStateNotifier(employeeLoginState),
          ),
          workPermissionsProvider.overrideWith(
            () => MockWorkPermissionsNotifier(leadsPermissions),
          ),
        ],
      );

      late BuildContext savedContext;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (ctx) {
                savedContext = ctx;
                return const DashboardView();
              },
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scaffoldState = tester.state<ScaffoldState>(
        find.byType(Scaffold).first,
      );
      scaffoldState.openEndDrawer();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scaffoldState.isEndDrawerOpen, isTrue);

      // Trigger pop (back button)
      Navigator.of(savedContext).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        scaffoldState.isEndDrawerOpen,
        isFalse,
        reason: 'Back navigation must close right drawer',
      );
    });
  });
}
