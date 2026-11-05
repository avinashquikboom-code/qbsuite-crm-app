import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/employee/views/dashboard_view.dart';
import 'package:quickboom_app/roles/employee/views/home_view.dart';
import 'package:quickboom_app/roles/employee/views/notifications_view.dart';
import 'package:quickboom_app/roles/employee/widgets/employee_home_calendar_section.dart';
import 'package:quickboom_app/shared/widgets/app_drawer.dart';

import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';

class MockLoginStateNotifier extends LoginStateNotifier {
  final LoginState mockState;
  MockLoginStateNotifier(this.mockState);

  @override
  LoginState build() => mockState;

  @override
  Future<void> refreshPermissions() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PermissionManager.instance.setPermissions([
      const UserPermission(module: 'ATTENDANCE', action: 'VIEW'),
      const UserPermission(module: 'CALENDAR', action: 'VIEW'),
    ], role: 'EMPLOYEE');
  });

  tearDown(() {
    PermissionManager.instance.clear();
  });

  final employeeLoginState = LoginState(
    isInitializing: false,
    isLoggedIn: true,
    userName: 'Avinash Magar',
    employeeCode: 'EMP-777',
    userRole: 'employee',
  );

  group('Employee Home Header Tests', () {
    testWidgets(
      'Header displays greeting, real employee name, notifications and hamburger menu',
      (tester) async {
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
          ],
        );

        bool drawerOpened = false;

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: EmployeeHomeView(
                  onOpenDrawer: () {
                    drawerOpened = true;
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify Greeting & Real Employee Name
        expect(find.text('Avinash Magar'), findsOneWidget);
        expect(find.text('Demo User'), findsNothing);
        expect(find.text('EMP-777'), findsOneWidget);

        final greetingFinder = find.byWidgetPredicate((widget) {
          if (widget is Text && widget.data != null) {
            return widget.data!.startsWith('Good Morning') ||
                widget.data!.startsWith('Good Afternoon') ||
                widget.data!.startsWith('Good Evening');
          }
          return false;
        });
        expect(greetingFinder, findsOneWidget);

        // 2. Verify Notification Icon
        final notificationIcon = find.byIcon(Remix.notification_3_line);
        expect(notificationIcon, findsOneWidget);

        // 3. Verify Hamburger Menu Icon with 'Open Menu' tooltip
        final menuBtn = find.byTooltip('Open Menu');
        expect(menuBtn, findsOneWidget);
        expect(find.byIcon(Remix.menu_line), findsOneWidget);

        // 4. Tap Menu button and verify callback triggers
        await tester.tap(menuBtn);
        await tester.pumpAndSettle();
        expect(drawerOpened, isTrue);

        // 5. Verify Header is above Attendance and Calendar
        final headerPos = tester.getTopLeft(find.text('Avinash Magar'));
        final attendancePos = tester.getTopLeft(
          find.text("Today's Attendance"),
        );
        final calendarPos = tester.getTopLeft(
          find.byType(EmployeeHomeCalendarSection),
        );

        expect(headerPos.dy < attendancePos.dy, isTrue);
        expect(attendancePos.dy < calendarPos.dy, isTrue);

        // 6. Verify tapping notification bell pushes NotificationsView
        await tester.tap(notificationIcon);
        await tester.pumpAndSettle();
        expect(find.byType(NotificationsView), findsOneWidget);
      },
    );

    testWidgets('DashboardView integration: Hamburger button opens AppDrawer', (
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
      await tester.pumpAndSettle();

      // Verify Header on DashboardView
      expect(find.text('Avinash Magar'), findsOneWidget);

      // Tap Open Menu button
      final menuBtn = find.byTooltip('Open Menu');
      expect(menuBtn, findsOneWidget);
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      // Verify AppDrawer opened
      expect(find.byType(AppDrawer), findsOneWidget);
    });

    // Responsive screen width checks (320px to 430px)
    final screenWidths = [320.0, 360.0, 375.0, 390.0, 414.0, 430.0];
    for (final width in screenWidths) {
      testWidgets(
        'Renders EmployeeHomeView Header at ${width}px width without overflow',
        (tester) async {
          PermissionManager.instance.setPermissions(const [], role: 'employee');
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final container = ProviderContainer(
            overrides: [
              loginStateProvider.overrideWith(
                () => MockLoginStateNotifier(employeeLoginState),
              ),
            ],
          );

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const Scaffold(body: EmployeeHomeView()),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Avinash Magar'), findsOneWidget);
          expect(find.byTooltip('Open Menu'), findsOneWidget);
          expect(find.byIcon(Remix.notification_3_line), findsOneWidget);
        },
      );
    }
  });
}
