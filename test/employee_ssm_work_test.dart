import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/roles/employee/models/employee_ssm_work_model.dart';
import 'package:quickboom_app/roles/employee/services/employee_ssm_service.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_my_work_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_ssm_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/ssm/employee_ssm_work_detail_view.dart';
import 'package:quickboom_app/roles/employee/views/ssm/employee_ssm_work_list_view.dart';
import 'package:quickboom_app/roles/employee/widgets/ssm/ssm_work_card.dart';
import 'package:quickboom_app/roles/employee/widgets/ssm/team_calendar_widget.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/team_calendar_viewmodel.dart';

class MockWorkPermissionsNotifier extends WorkPermissionsNotifier {
  @override
  WorkPermissionsState build() {
    return const WorkPermissionsState(
      permissions: EmployeeWorkPermissions(
        role: 'Creative Staff',
        workPermissions: [
          'video_edit',
          'post_design',
          'reel_shoot',
          'story_design',
        ],
      ),
      isLoading: false,
    );
  }
}

class MockEmployeeSSMNotifier extends EmployeeSSMNotifier {
  final SSMWorkSchedule initialWork;
  MockEmployeeSSMNotifier(this.initialWork);

  @override
  EmployeeSSMState build() {
    return EmployeeSSMState(
      allSchedules: [initialWork],
      activityEvents: const [],
      selectedCalendarDate: DateTime(2026, 8, 20),
      todayDate: DateTime(2026, 8, 20),
      isLoading: false,
    );
  }
}

class MockEmployeeMyWorkNotifier extends EmployeeMyWorkNotifier {
  @override
  EmployeeMyWorkState build() {
    return EmployeeMyWorkState(selectedDate: DateTime(2026, 10, 10));
  }

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> refresh() async {}
}

class MockPermissionNotifier extends PermissionNotifier {
  @override
  PermissionState build() => const PermissionState();
}

class MockTeamCalendarNotifier extends TeamCalendarNotifier {
  @override
  TeamCalendarState build() {
    return TeamCalendarState(
      currentMonth: DateTime(2026, 8, 1),
      selectedDate: DateTime(2026, 8, 20),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Employee SSM Work Model & Service Unit Tests', () {
    test('Work types have proper default durations', () {
      expect(SSMWorkType.reel.defaultDurationDays, 3);
      expect(SSMWorkType.shoot.defaultDurationDays, 3);
      expect(SSMWorkType.post.defaultDurationDays, 1);
    });

    test('Generates 3-day tasks for Reel and Shoot accurately', () {
      final aug20 = DateTime(2026, 8, 20);
      final reelTasks = EmployeeSSMService.generateDailyTasks(
        workType: SSMWorkType.reel,
        startDate: aug20,
        durationDays: 3,
      );

      expect(reelTasks.length, 3);
      expect(reelTasks[0].dayNumber, 1);
      expect(reelTasks[0].title, 'Shoot / Content Capture');
      expect(reelTasks[0].date, aug20);

      expect(reelTasks[1].dayNumber, 2);
      expect(reelTasks[1].title, 'Editing / Production');
      expect(reelTasks[1].date, DateTime(2026, 8, 21));

      expect(reelTasks[2].dayNumber, 3);
      expect(reelTasks[2].title, 'Final Review / Submission');
      expect(reelTasks[2].date, DateTime(2026, 8, 22));

      final shootTasks = EmployeeSSMService.generateDailyTasks(
        workType: SSMWorkType.shoot,
        startDate: aug20,
        durationDays: 3,
      );

      expect(shootTasks.length, 3);
      expect(shootTasks[0].title, 'Location / Preparation');
      expect(shootTasks[1].title, 'Shooting');
      expect(shootTasks[2].title, 'Remaining Shots / Backup');
    });

    test('SSMWorkSchedule.fromJson maps real backend payload correctly', () {
      final json = {
        'id': '101',
        'customerName': 'Apex Fitness Club',
        'customerBusiness': 'Apex Wellness Ltd',
        'socialMediaAccount': 'Instagram — @apexwellness',
        'platform': 'Instagram',
        'workType': 'REEL',
        'scheduledDate': '2026-09-10T10:00:00.000Z',
        'durationDays': 3,
        'assignedTeam': 'Creative Studio Team',
        'assignedEmployees': ['John Doe', 'Sarah Connor'],
        'status': 'SCHEDULED',
        'tasks': [
          {'dayNumber': 1, 'title': 'Footage Capture', 'status': 'PENDING'},
          {'dayNumber': 2, 'title': 'Video Editing', 'status': 'PENDING'},
          {'dayNumber': 3, 'title': 'Final Approval', 'status': 'PENDING'},
        ],
      };

      final schedule = SSMWorkSchedule.fromJson(json);
      expect(schedule.id, '101');
      expect(schedule.customerName, 'Apex Fitness Club');
      expect(schedule.customerBusiness, 'Apex Wellness Ltd');
      expect(schedule.platform, 'Instagram');
      expect(schedule.socialMediaAccount, 'Instagram — @apexwellness');
      expect(schedule.workType, SSMWorkType.reel);
      expect(schedule.status, SSMWorkStatus.scheduled);
      expect(schedule.durationDays, 3);
      expect(schedule.assignedTeam, 'Creative Studio Team');
      expect(schedule.assignedEmployees, ['John Doe', 'Sarah Connor']);
      expect(schedule.dailyTasks.length, 3);
      expect(schedule.dailyTasks[0].title, 'Footage Capture');
    });

    test(
      'Multi-day work correctly spans across start, middle, and end dates',
      () {
        final aug20 = DateTime(2026, 8, 20);
        final work = SSMWorkSchedule(
          id: 'test_1',
          customerName: 'Apex Fitness',
          customerBusiness: 'Apex Fitness Club',
          socialMediaAccount: 'Instagram — @apexfitness',
          platform: 'Instagram',
          workType: SSMWorkType.reel,
          startDate: aug20,
          durationDays: 3,
          endDate: DateTime(2026, 8, 22),
          assignedTeam: 'Creative Team',
          assignedEmployees: ['John Doe'],
          dailyTasks: EmployeeSSMService.generateDailyTasks(
            workType: SSMWorkType.reel,
            startDate: aug20,
            durationDays: 3,
          ),
          createdAt: DateTime(2026, 8, 18),
        );

        expect(work.spansDate(DateTime(2026, 8, 19)), isFalse);
        expect(work.spansDate(DateTime(2026, 8, 20)), isTrue); // Day 1
        expect(work.spansDate(DateTime(2026, 8, 21)), isTrue); // Day 2
        expect(work.spansDate(DateTime(2026, 8, 22)), isTrue); // Day 3
        expect(work.spansDate(DateTime(2026, 8, 23)), isFalse);

        expect(work.getCurrentDayNumber(DateTime(2026, 8, 20)), 1);
        expect(work.getCurrentDayNumber(DateTime(2026, 8, 21)), 2);
        expect(work.getCurrentDayNumber(DateTime(2026, 8, 22)), 3);
      },
    );
  });

  group('Employee SSM State & ViewModel Tests', () {
    test(
      'Employee SSM state initializes cleanly with empty list and loading',
      () {
        final container = ProviderContainer();
        final state = container.read(employeeSSMProvider);

        expect(state.isLoading, isTrue);
        expect(state.allSchedules, isEmpty);
        expect(state.myWorkSchedules, isEmpty);
        expect(state.isError, isFalse);
      },
    );

    test('Start work changes status to inProgress', () {
      final container = ProviderContainer();
      final notifier = container.read(employeeSSMProvider.notifier);

      final sampleWork = SSMWorkSchedule.fromJson({
        'id': 'work_dyn_1',
        'customerName': 'Horizon Corp',
        'workType': 'REEL',
        'status': 'SCHEDULED',
        'durationDays': 3,
        'scheduledDate': '2026-09-10T00:00:00.000Z',
      });
      notifier.scheduleNewWork(sampleWork);

      expect(
        container.read(employeeSSMProvider).allSchedules.first.status,
        SSMWorkStatus.scheduled,
      );

      notifier.startWork('work_dyn_1');

      final updatedWork = container
          .read(employeeSSMProvider)
          .allSchedules
          .firstWhere((w) => w.id == 'work_dyn_1');
      expect(updatedWork.status, SSMWorkStatus.inProgress);
    });

    test(
      'Completing day tasks advances task completion and marks work completed on final day',
      () {
        final container = ProviderContainer();
        final notifier = container.read(employeeSSMProvider.notifier);

        final sampleWork = SSMWorkSchedule.fromJson({
          'id': 'work_dyn_1',
          'customerName': 'Horizon Corp',
          'workType': 'REEL',
          'status': 'SCHEDULED',
          'durationDays': 3,
          'scheduledDate': '2026-09-10T00:00:00.000Z',
        });
        notifier.scheduleNewWork(sampleWork);

        notifier.startWork('work_dyn_1');
        notifier.completeDayTask('work_dyn_1', 1);

        var work = container
            .read(employeeSSMProvider)
            .allSchedules
            .firstWhere((w) => w.id == 'work_dyn_1');
        expect(work.dailyTasks[0].isCompleted, isTrue);
        expect(work.dailyTasks[1].isCompleted, isFalse);
        expect(work.status, SSMWorkStatus.inProgress);

        notifier.completeDayTask('work_dyn_1', 2);
        notifier.completeDayTask('work_dyn_1', 3);

        work = container
            .read(employeeSSMProvider)
            .allSchedules
            .firstWhere((w) => w.id == 'work_dyn_1');
        expect(work.dailyTasks[2].isCompleted, isTrue);
        expect(work.status, SSMWorkStatus.completed);
      },
    );

    test(
      'Calendar filters: Team A, Team B, All, My Work and overlapping dates',
      () {
        final container = ProviderContainer();
        final notifier = container.read(employeeSSMProvider.notifier);

        final work1 = SSMWorkSchedule.fromJson({
          'id': 'w1',
          'customerName': 'Client A',
          'assignedTeam': 'SSM Team A',
          'scheduledDate': '2026-08-20T00:00:00.000Z',
          'durationDays': 1,
        });
        final work2 = SSMWorkSchedule.fromJson({
          'id': 'w2',
          'customerName': 'Client B',
          'assignedTeam': 'SSM Team B',
          'scheduledDate': '2026-08-20T00:00:00.000Z',
          'durationDays': 1,
        });
        notifier.scheduleNewWork(work1);
        notifier.scheduleNewWork(work2);

        notifier.selectCalendarDate(DateTime(2026, 8, 20));

        notifier.setCalendarFilter('All');
        expect(
          container.read(employeeSSMProvider).schedulesForSelectedDate.length,
          2,
        );

        notifier.setCalendarFilter('SSM Team A');
        var list = container.read(employeeSSMProvider).schedulesForSelectedDate;
        expect(list.length, 1);
        expect(list.first.assignedTeam, 'SSM Team A');

        notifier.setCalendarFilter('SSM Team B');
        list = container.read(employeeSSMProvider).schedulesForSelectedDate;
        expect(list.length, 1);
        expect(list.first.assignedTeam, 'SSM Team B');

        notifier.setCalendarFilter('My Work');
        list = container.read(employeeSSMProvider).schedulesForSelectedDate;
        expect(list.length, 2);
      },
    );
  });

  group('Employee SSM UI & Widget Tests', () {
    Widget buildTestableWidget(Widget child) {
      return ProviderScope(
        child: MaterialApp(home: Scaffold(body: child)),
      );
    }

    testWidgets(
      'SSMWorkCard displays customer, 3-day info, day 1 task, and action buttons',
      (tester) async {
        final aug20 = DateTime(2026, 8, 20);
        final work = SSMWorkSchedule(
          id: 'card_test',
          customerName: 'Prime Media',
          customerBusiness: 'Prime Media Group',
          socialMediaAccount: 'Instagram — @primemedia',
          platform: 'Instagram',
          workType: SSMWorkType.reel,
          startDate: aug20,
          durationDays: 3,
          endDate: DateTime(2026, 8, 22),
          assignedTeam: 'Creative Team A',
          assignedEmployees: ['John Doe', 'Alice'],
          dailyTasks: EmployeeSSMService.generateDailyTasks(
            workType: SSMWorkType.reel,
            startDate: aug20,
            durationDays: 3,
          ),
          createdAt: DateTime(2026, 8, 18),
        );

        bool started = false;

        await tester.pumpWidget(
          buildTestableWidget(
            SSMWorkCard(
              work: work,
              targetDate: aug20,
              onStartWork: () => started = true,
            ),
          ),
        );

        expect(find.text('Prime Media'), findsOneWidget);
        expect(find.text('Reel Shoot'), findsOneWidget);
        expect(find.text('Creative Team A'), findsOneWidget);
        expect(find.text('Day 1 of 3'), findsOneWidget);
        expect(find.text('Shoot / Content Capture'), findsOneWidget);
        expect(find.text('START WORK'), findsOneWidget);

        await tester.tap(find.text('START WORK'));
        expect(started, isTrue);
      },
    );

    testWidgets(
      'EmployeeSSMWorkDetailView renders timeline stages, specs, and dialogs',
      (tester) async {
        final sampleWork = SSMWorkSchedule.fromJson({
          'id': 'work_detail_test',
          'customerName': 'Studio Alpha',
          'workType': 'REEL',
          'status': 'SCHEDULED',
          'durationDays': 3,
          'scheduledDate': '2026-08-20T00:00:00.000Z',
        });

        final container = ProviderContainer(
          overrides: [
            workPermissionsProvider.overrideWith(
              () => MockWorkPermissionsNotifier(),
            ),
            employeeSSMProvider.overrideWith(
              () => MockEmployeeSSMNotifier(sampleWork),
            ),
          ],
        );

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: EmployeeSSMWorkDetailView(workId: 'work_detail_test'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Work Details'), findsOneWidget);
        expect(find.text('Studio Alpha'), findsWidgets);
        expect(find.text('SPECIFICATIONS & TIMELINE'), findsOneWidget);
        expect(find.text('DAILY TASK STAGES (3 DAYS)'), findsOneWidget);

        final startBtn = find.text('START WORK');
        await tester.scrollUntilVisible(startBtn, 300);
        await tester.tap(startBtn);
        await tester.pumpAndSettle();

        expect(find.text('Start this work?'), findsOneWidget);
        expect(find.text('Day:'), findsOneWidget);
      },
    );

    testWidgets('TeamCalendarWidget renders date selector', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teamCalendarProvider.overrideWith(
              () => MockTeamCalendarNotifier(),
            ),
          ],
          child: buildTestableWidget(
            const SingleChildScrollView(child: TeamCalendarWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // TeamCalendarWidget renders month name and day labels
      expect(find.byType(TeamCalendarWidget), findsOneWidget);
    });

    testWidgets(
      'EmployeeSSMWorkListView renders header and empty state when no works assigned',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workPermissionsProvider.overrideWith(
                () => MockWorkPermissionsNotifier(),
              ),
              employeeMyWorkProvider.overrideWith(
                () => MockEmployeeMyWorkNotifier(),
              ),
              permissionManagerProvider.overrideWith(
                () => MockPermissionNotifier(),
              ),
            ],
            child: const MaterialApp(home: EmployeeSSMWorkListView()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Production Overview'), findsOneWidget);
        expect(find.text('Authorized Modules'), findsOneWidget);
        expect(find.text('Production Metrics'), findsOneWidget);
        expect(find.text('No work assigned'), findsOneWidget);
      },
    );
  });
}
