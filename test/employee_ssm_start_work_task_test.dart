import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/roles/employee/models/employee_ssm_work_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_ssm_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/ssm/employee_work_task_view.dart';
import 'package:quickboom_app/roles/employee/widgets/ssm/work_task_card.dart';

final sampleWork1 = SSMWorkSchedule.fromJson({
  'id': 'ssm_work_1',
  'customerName': 'Care Fitness Gym',
  'customerBusiness': 'Fitness & Wellness',
  'socialMediaAccount': '@carefitnessgym',
  'platform': 'Instagram',
  'assignedTeam': 'SSM Team A',
  'assignedEmployees': ['Avinash', 'Rahul'],
  'workType': 'REEL',
  'scheduledDate': '2026-08-20T00:00:00.000Z',
  'status': 'SCHEDULED',
  'durationDays': 3,
  'tasks': [
    {
      'stepOrder': 1,
      'title': 'Shoot / Content Capture',
      'description': 'Capture 4K fitness footage',
      'isCompleted': false,
    },
    {
      'stepOrder': 2,
      'title': 'Video Editing',
      'description': 'Edit and color grade reel',
      'isCompleted': false,
    },
    {
      'stepOrder': 3,
      'title': 'Client Review & Posting',
      'description': 'Final approval & publishing',
      'isCompleted': false,
    },
  ],
});

class MockStartWorkSSMNotifier extends EmployeeSSMNotifier {
  final List<SSMWorkSchedule> initialSchedules;
  final DateTime? testTodayDate;
  MockStartWorkSSMNotifier(this.initialSchedules, {this.testTodayDate});

  @override
  EmployeeSSMState build() {
    final tDate = testTodayDate ?? DateTime(2026, 8, 20);
    return EmployeeSSMState(
      allSchedules: initialSchedules,
      activityEvents: const [],
      currentEmployeeName: 'Avinash',
      currentEmployeeTeam: 'SSM Team A',
      selectedCalendarDate: tDate,
      todayDate: tDate,
      isLoading: false,
    );
  }

  @override
  Future<bool> startWork(String workId) async {
    state = state.copyWith(
      allSchedules: state.allSchedules.map((work) {
        if (work.id == workId) {
          return work.copyWith(status: SSMWorkStatus.inProgress);
        }
        return work;
      }).toList(),
    );
    return true;
  }
}

ProviderContainer createContainer({
  List<SSMWorkSchedule>? schedules,
  DateTime? todayDate,
}) {
  final list = schedules ?? [sampleWork1];
  return ProviderContainer(
    overrides: [
      employeeSSMProvider.overrideWith(
        () => MockStartWorkSSMNotifier(list, testTodayDate: todayDate),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Employee SSM Team & Start Work Task Logic Tests', () {
    test(
      'SSM Work Schedule has assigned team and team members from parsed work data',
      () {
        expect(sampleWork1.assignedTeam, 'SSM Team A');
        expect(sampleWork1.assignedEmployees, contains('Avinash'));
        expect(sampleWork1.status, SSMWorkStatus.scheduled);
      },
    );

    test(
      'Start work changes status from SCHEDULED to IN PROGRESS and unlocks Day 1 task',
      () {
        final container = createContainer();
        final notifier = container.read(employeeSSMProvider.notifier);

        final initialWork = container
            .read(employeeSSMProvider)
            .allSchedules
            .firstWhere((s) => s.id == 'ssm_work_1');
        expect(initialWork.status, SSMWorkStatus.scheduled);
        expect(initialWork.assignedTeam, 'SSM Team A');

        notifier.startWork('ssm_work_1');

        final updatedWork = container
            .read(employeeSSMProvider)
            .allSchedules
            .firstWhere((s) => s.id == 'ssm_work_1');
        expect(updatedWork.status, SSMWorkStatus.inProgress);
        expect(updatedWork.dailyTasks.first.title, 'Shoot / Content Capture');
        expect(updatedWork.dailyTasks.first.dayNumber, 1);
      },
    );

    test(
      'Completing day tasks advances task completion state through Day 1, 2, 3',
      () {
        final container = createContainer();
        final notifier = container.read(employeeSSMProvider.notifier);

        notifier.startWork('ssm_work_1');

        // Complete Day 1
        notifier.completeDayTask('ssm_work_1', 1);
        var work = container
            .read(employeeSSMProvider)
            .allSchedules
            .firstWhere((s) => s.id == 'ssm_work_1');
        expect(work.dailyTasks[0].isCompleted, isTrue);
        expect(work.dailyTasks[1].isCompleted, isFalse);
        expect(work.status, SSMWorkStatus.inProgress);

        // Complete Day 2
        notifier.completeDayTask('ssm_work_1', 2);
        work = container
            .read(employeeSSMProvider)
            .allSchedules
            .firstWhere((s) => s.id == 'ssm_work_1');
        expect(work.dailyTasks[1].isCompleted, isTrue);
        expect(work.status, SSMWorkStatus.inProgress);

        // Complete Day 3 (final day)
        notifier.completeDayTask('ssm_work_1', 3);
        work = container
            .read(employeeSSMProvider)
            .allSchedules
            .firstWhere((s) => s.id == 'ssm_work_1');
        expect(work.dailyTasks[2].isCompleted, isTrue);
        expect(work.status, SSMWorkStatus.completed);
      },
    );
  });

  group('WorkTaskCard & EmployeeWorkTaskView UI Tests', () {
    testWidgets('WorkTaskCard renders all required details and badges', (
      tester,
    ) async {
      final container = createContainer();
      container.read(employeeSSMProvider.notifier).startWork('ssm_work_1');
      final work = container
          .read(employeeSSMProvider)
          .allSchedules
          .firstWhere((s) => s.id == 'ssm_work_1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: WorkTaskCard(work: work, targetDate: DateTime(2026, 8, 20)),
            ),
          ),
        ),
      );

      expect(find.text("TODAY'S TASK"), findsOneWidget);
      expect(find.text('Reel Shoot'), findsOneWidget);
      expect(find.text('Care Fitness Gym'), findsOneWidget);
      expect(find.text('SSM Team A'), findsOneWidget);
      expect(find.text('Day 1 of 3'), findsOneWidget);
      expect(find.text('Shoot / Content Capture'), findsOneWidget);
      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.text('View Task'), findsOneWidget);
    });

    testWidgets(
      'EmployeeWorkTaskView renders full task specs and complete button',
      (tester) async {
        final container = createContainer();
        container.read(employeeSSMProvider.notifier).startWork('ssm_work_1');

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: EmployeeWorkTaskView(workId: 'ssm_work_1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Work Task'), findsOneWidget);
        expect(find.text('Care Fitness Gym'), findsOneWidget);
        expect(find.text('SSM Team A'), findsOneWidget);
        expect(find.text('Shoot / Content Capture'), findsWidgets);
        expect(find.text('WORK SPECIFICATIONS'), findsOneWidget);

        final completeBtnFinder = find.text('Mark Day 1 Task Complete');
        await tester.scrollUntilVisible(completeBtnFinder, 200);
        expect(completeBtnFinder, findsOneWidget);

        // Tap Mark Day 1 Task Complete
        await tester.tap(completeBtnFinder);
        await tester.pumpAndSettle();

        expect(find.text("Mark today's task as completed?"), findsOneWidget);
        await tester.tap(find.text('Complete'));
        await tester.pumpAndSettle();

        expect(find.text('Day 1 Task Completed ✓'), findsOneWidget);
      },
    );

    testWidgets('WorkTaskCard renders in progress status after starting work', (
      tester,
    ) async {
      final container = createContainer();
      container.read(employeeSSMProvider.notifier).startWork('ssm_work_1');
      final work = container
          .read(employeeSSMProvider)
          .allSchedules
          .firstWhere((s) => s.id == 'ssm_work_1');

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: WorkTaskCard(work: work, targetDate: DateTime(2026, 8, 20)),
            ),
          ),
        ),
      );

      expect(find.byType(WorkTaskCard), findsOneWidget);
      expect(find.text('IN PROGRESS'), findsOneWidget);
      expect(find.text('Care Fitness Gym'), findsOneWidget);
    });
  });

  group('Responsive Layout Tests across screen widths (320px - 430px)', () {
    final widths = [320.0, 360.0, 375.0, 390.0, 414.0, 430.0];

    for (final width in widths) {
      testWidgets(
        'Renders EmployeeWorkTaskView at ${width}px without RenderFlex overflow',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final container = createContainer();
          container.read(employeeSSMProvider.notifier).startWork('ssm_work_1');

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: EmployeeWorkTaskView(workId: 'ssm_work_1'),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.text('Work Task'), findsOneWidget);
        },
      );
    }
  });
}
