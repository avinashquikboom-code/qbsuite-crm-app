import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';
import 'package:quickboom_app/roles/company_admin/views/company_admin_main_view.dart';
import 'package:quickboom_app/roles/company_admin/views/home/admin_home_tab.dart';
import 'package:quickboom_app/roles/company_admin/views/more/data_capture/admin_data_capture_view.dart';
import 'package:quickboom_app/roles/company_admin/views/more/visits/admin_visits_view.dart';
import 'package:quickboom_app/roles/company_admin/views/work/admin_work_detail_view.dart';

void main() {
  group('Company Admin State & Mutation Tests', () {
    test('Initial Seed Data has correct KPIs', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(companyAdminProvider);
      expect(state.profile.companyName, 'ABC Digital Solutions');
      expect(state.totalEmployees, 24);
      expect(state.customers.length, greaterThanOrEqualTo(48));
      expect(state.activeSSMWorkCount, greaterThanOrEqualTo(10));
      expect(state.todayVisitsCount, 6);
      expect(state.openLeads, 18);
      expect(state.pendingProposalsCount, 4);
    });

    test('addCustomer inserts locally and logs audit event', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialCount = container
          .read(companyAdminProvider)
          .customers
          .length;
      final newClient = AdminCustomer(
        id: 'TEST-CUST-999',
        name: 'Test Crossfit Arena',
        businessName: 'Test Crossfit Arena Pvt Ltd',
        mobile: '+91 99999 11111',
        email: 'test@crossfit.com',
        city: 'Pune',
        assignedEmployee: 'Amit',
        assignedTeam: 'SSM Team B',
        activeWork: 'Reel Shoot',
        customerSince: 'Today',
        nextFollowUp: 'Tomorrow',
      );

      container.read(companyAdminProvider.notifier).addCustomer(newClient);

      final updatedState = container.read(companyAdminProvider);
      expect(updatedState.customers.length, initialCount + 1);
      expect(updatedState.customers.first.name, 'Test Crossfit Arena');
      expect(updatedState.auditLogs.first.action, 'Customer Created');
    });

    test(
      'addWork schedules SSM work with correct default duration and tasks',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final work = AdminSSMWork(
          id: 'TEST-WRK-001',
          customerName: 'Care Fitness Gym',
          socialAccount: '@carefitness',
          platform: 'Instagram',
          workType: WorkType.reel,
          team: 'SSM Team A',
          teamMembers: ['Demo User', 'Rahul', 'Sneha'],
          assignedEmployee: 'Demo User',
          startDate: DateTime(2026, 8, 18),
          endDate: DateTime(2026, 8, 20),
          durationDays: 3,
          currentDay: 1,
          todayTask: 'Day 1: Shoot / Content Capture',
          allTasks: [
            DayTask(
              day: 1,
              title: 'Shoot / Content Capture',
              description: 'Capture footage',
            ),
            DayTask(
              day: 2,
              title: 'Editing / Production',
              description: 'Video edit',
            ),
            DayTask(
              day: 3,
              title: 'Final Review / Submission',
              description: 'Review & post',
            ),
          ],
          status: WorkStatus.scheduled,
        );

        container.read(companyAdminProvider.notifier).addWork(work);

        final updatedState = container.read(companyAdminProvider);
        expect(updatedState.workList.first.customerName, 'Care Fitness Gym');
        expect(updatedState.workList.first.durationDays, 3);
        expect(updatedState.workList.first.allTasks.length, 3);
      },
    );
  });

  group('Company Admin UI & Navigation Tests', () {
    Widget createWidgetForTesting(Widget child) {
      return ProviderScope(child: MaterialApp(home: child));
    }

    testWidgets('CompanyAdminMainView renders all 5 bottom destinations', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createWidgetForTesting(const CompanyAdminMainView()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Clients'), findsOneWidget);
      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
    });

    testWidgets('Tapping between tabs switches active views', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createWidgetForTesting(const CompanyAdminMainView()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('WORKSPACE'), findsWidgets);

      // Tap Clients Tab
      await tester.tap(find.byIcon(Remix.building_2_line).last);
      await tester.pumpAndSettle();
      expect(find.text('Search Customers by name, city...'), findsOneWidget);

      // Tap Trending Tab
      await tester.tap(find.byIcon(Remix.fire_line).last);
      await tester.pumpAndSettle();
      expect(find.text('TRENDING STORIES & HOOKS'), findsOneWidget);

      // Tap Calendar Tab
      await tester.tap(find.byIcon(Remix.calendar_2_line).last);
      await tester.pumpAndSettle();
      expect(find.text('Team Calendar'), findsOneWidget);

      // Tap More Tab
      await tester.tap(find.byIcon(Remix.more_fill).last);
      await tester.pumpAndSettle();
      expect(find.text('Employees & Teams'), findsOneWidget);
      expect(find.text('Company Profile'), findsOneWidget);
    });

    testWidgets('AdminWorkDetailView renders day-wise timeline correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final work = AdminSSMWork(
        id: 'WRK-001',
        customerName: 'Care Fitness Gym',
        socialAccount: '@carefitness_official',
        platform: 'Instagram',
        workType: WorkType.reel,
        team: 'SSM Team A',
        teamMembers: ['Demo User', 'Rahul', 'Sneha'],
        assignedEmployee: 'Demo User',
        startDate: DateTime(2026, 8, 18),
        endDate: DateTime(2026, 8, 20),
        durationDays: 3,
        currentDay: 1,
        todayTask: 'Day 1: Shoot / Content Capture',
        allTasks: [
          DayTask(
            day: 1,
            title: 'Shoot / Content Capture',
            description: 'Capture video footage',
            isCurrent: true,
          ),
          DayTask(
            day: 2,
            title: 'Editing / Production',
            description: 'Color grading & sound sync',
          ),
          DayTask(
            day: 3,
            title: 'Final Review / Submission',
            description: 'Client review',
          ),
        ],
        status: WorkStatus.inProgress,
      );

      await tester.pumpWidget(
        createWidgetForTesting(AdminWorkDetailView(work: work)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Day-wise Work Breakdown & Tasks'), findsOneWidget);
      expect(find.text('Day 1: Shoot / Content Capture'), findsOneWidget);
      expect(find.text('Day 2: Editing / Production'), findsOneWidget);
      expect(find.text('Day 3: Final Review / Submission'), findsOneWidget);
    });

    testWidgets(
      'AdminHomeTab renders Customer Calendar section and horizontal date strip',
      (tester) async {
        tester.view.physicalSize = const Size(400, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(createWidgetForTesting(const AdminHomeTab()));
        await tester.pumpAndSettle();

        expect(find.text('Customer Calendar'), findsOneWidget);
        expect(find.text('Schedule'), findsOneWidget);
        expect(find.text('View All'), findsWidgets);
        expect(find.text('Care Fitness Gym'), findsWidgets);
      },
    );

    testWidgets(
      'Responsive screen test across 320px, 360px, 390px, 414px, 430px',
      (tester) async {
        final widths = [320.0, 360.0, 375.0, 390.0, 414.0, 430.0];

        final originalOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          debugPrint('=== OVERFLOW SUMMARY ===: ${details.summary}');
          for (final node in details.informationCollector?.call() ?? []) {
            debugPrint('INFO: $node');
          }
        };
        addTearDown(() => FlutterError.onError = originalOnError);

        for (final width in widths) {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            createWidgetForTesting(const CompanyAdminMainView()),
          );
          await tester.pumpAndSettle();
          final err = tester.takeException();
          expect(err, isNull, reason: 'MainView overflow at $width');

          await tester.pumpWidget(
            createWidgetForTesting(const AdminDataCaptureView()),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'DataCapture overflow at $width',
          );

          await tester.pumpWidget(
            createWidgetForTesting(const AdminVisitsView()),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'VisitsView overflow at $width',
          );
        }
        tester.view.resetPhysicalSize();
      },
    );
  });
}
