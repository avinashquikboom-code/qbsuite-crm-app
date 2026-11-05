import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_my_work_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/ssm/employee_ssm_work_list_view.dart';
import 'package:quickboom_app/roles/employee/widgets/employee_my_work_card.dart';

class MockWorkPermissionsNotifier extends WorkPermissionsNotifier {
  final WorkPermissionsState mockState;
  MockWorkPermissionsNotifier(this.mockState);

  @override
  WorkPermissionsState build() => mockState;

  @override
  Future<void> loadPermissions() async {}
}

class MockMyWorkNotifier extends EmployeeMyWorkNotifier {
  final EmployeeMyWorkState mockState;
  MockMyWorkNotifier(this.mockState);

  @override
  EmployeeMyWorkState build() => mockState;

  @override
  Future<void> loadInitial() async {}

  @override
  Future<void> refresh() async {}

  @override
  Future<void> setFilter(MyWorkFilter filter) async {}

  @override
  Future<void> setDate(DateTime date) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Employee My Work Redesign - Unit Tests', () {
    test('1. formatActivityDate formats date correctly (08 Sep 2026)', () {
      final dt = DateTime(2026, 9, 8);
      expect(formatActivityDate(dt), '08 Sep 2026');
    });

    test(
      '2. resolveActivityTypeTitle resolves real activity names without generic "Task"',
      () {
        final reelEditAct = CustomerCalendarActivity.fromJson({
          'id': '101',
          'customerName': 'Customer A',
          'type': 'REEL_EDIT',
          'title': 'Reel Edit - Summer Promo',
          'date': '2026-09-08',
        });
        expect(resolveActivityTypeTitle(reelEditAct), 'REEL EDIT');

        final storyDesignAct = CustomerCalendarActivity.fromJson({
          'id': '102',
          'customerName': 'Customer B',
          'type': 'STORY_DESIGN',
          'title': 'Story Design #1',
          'date': '2026-09-08',
        });
        expect(resolveActivityTypeTitle(storyDesignAct), 'STORY DESIGN');

        final postDesignAct = CustomerCalendarActivity.fromJson({
          'id': '103',
          'customerName': 'Customer C',
          'type': 'POST_DESIGN',
          'title': 'Post Design - Product Launch',
          'date': '2026-09-08',
        });
        expect(resolveActivityTypeTitle(postDesignAct), 'POST DESIGN');

        final reelShootAct = CustomerCalendarActivity.fromJson({
          'id': '104',
          'customerName': 'Customer D',
          'type': 'REEL_SHOOT',
          'title': 'Reel Shoot Onsite',
          'date': '2026-09-08',
        });
        expect(resolveActivityTypeTitle(reelShootAct), 'REEL SHOOT');
      },
    );
  });

  group('Employee My Work Card - Widget Tests', () {
    testWidgets(
      '3. EmployeeMyWorkCard displays all required backend data and Start Work CTA',
      (tester) async {
        bool startWorkTapped = false;

        final activity = CustomerCalendarActivity.fromJson({
          'id': 'act_001',
          'customerName': 'Customer A',
          'businessName': 'Social Media Campaign',
          'type': 'REEL_EDIT',
          'title': 'Summer Reel Edit',
          'date': '2026-09-08',
          'time': '11:00 AM',
          'purchaseId': 'PUR-066',
          'team': 'Social Media Team',
          'status': 'SCHEDULED',
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: EmployeeMyWorkCard(
                activity: activity,
                onStartWork: () {
                  startWorkTapped = true;
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('REEL EDIT'), findsOneWidget);
        expect(find.text('SOCIAL MEDIA CAMPAIGN'), findsOneWidget);
        expect(find.text('Customer A'), findsOneWidget);
        expect(find.text('08 Sep 2026'), findsOneWidget);
        expect(find.text('11:00 AM'), findsOneWidget);
        expect(find.text('PUR-066'), findsOneWidget);
        expect(find.text('Social Media Team'), findsOneWidget);
        expect(find.text('SCHEDULED'), findsOneWidget);
        expect(find.text('Start Work'), findsOneWidget);

        await tester.tap(find.text('Start Work'));
        await tester.pump();
        expect(startWorkTapped, isTrue);
      },
    );

    testWidgets('4. EmployeeMyWorkCard shows Complete Work when IN_PROGRESS', (
      tester,
    ) async {
      bool completeWorkTapped = false;

      final activity = CustomerCalendarActivity.fromJson({
        'id': 'act_002',
        'customerName': 'Customer B',
        'type': 'STORY_DESIGN',
        'date': '2026-09-08',
        'time': '02:30 PM',
        'status': 'IN_PROGRESS',
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: EmployeeMyWorkCard(
              activity: activity,
              onCompleteWork: () {
                completeWorkTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('IN_PROGRESS'), findsOneWidget);
      expect(find.text('Complete Work'), findsOneWidget);
      expect(find.text('Start Work'), findsNothing);

      await tester.tap(find.text('Complete Work'));
      await tester.pump();
      expect(completeWorkTapped, isTrue);
    });

    testWidgets('5. EmployeeMyWorkCard removes action button when COMPLETED', (
      tester,
    ) async {
      final activity = CustomerCalendarActivity.fromJson({
        'id': 'act_003',
        'customerName': 'Customer C',
        'type': 'POST_DESIGN',
        'date': '2026-09-08',
        'status': 'COMPLETED',
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(body: EmployeeMyWorkCard(activity: activity)),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('COMPLETED'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Start Work'), findsNothing);
      expect(find.text('Complete Work'), findsNothing);
    });
  });

  group('Employee SSM Work List View - Widget Tests', () {
    testWidgets(
      '6. EmployeeSSMWorkListView renders Today Summary, Filter bar, and activities',
      (tester) async {
        final sampleActivity = CustomerCalendarActivity.fromJson({
          'id': 'act_101',
          'customerName': 'QuikBoom Enterprise Workspace',
          'type': 'STORY_DESIGN',
          'title': 'Story #1: Design',
          'date': '2026-09-09',
          'time': '10:00 AM',
          'purchaseId': 'PUR-001',
          'team': 'PRODUCTION',
          'status': 'SCHEDULED',
        });

        final mockMyWorkState = EmployeeMyWorkState(
          activeFilter: MyWorkFilter.today,
          selectedDate: DateTime(2026, 9, 9),
          isLoading: false,
          activities: [sampleActivity],
          todayTotal: 1,
          todayCompleted: 0,
          todayPending: 1,
          prodTotal: 1,
          prodPending: 1,
        );

        final mockPerms = WorkPermissionsState(
          isLoading: false,
          permissions: const EmployeeWorkPermissions(
            role: 'Graphic Designer',
            workPermissions: ['post_design', 'story_design'],
            effectivePermissions: {'post_design': true, 'story_design': true},
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              employeeMyWorkProvider.overrideWith(
                () => MockMyWorkNotifier(mockMyWorkState),
              ),
              workPermissionsProvider.overrideWith(
                () => MockWorkPermissionsNotifier(mockPerms),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const EmployeeSSMWorkListView(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Header & Summary
        expect(find.text('My Work'), findsOneWidget);
        expect(find.text("Today's Work"), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(
          find.text('Completed'),
          findsWidgets,
        ); // Summary badge + filter pill
        expect(find.text('Pending'), findsOneWidget);
        expect(find.text('1'), findsNWidgets(2)); // total 1 and pending 1
        expect(find.text('0'), findsWidgets); // completed 0

        // Filters
        expect(find.text('Today'), findsOneWidget);
        expect(find.text('Tomorrow'), findsOneWidget);
        expect(find.text('Pick Date'), findsOneWidget);

        // Activity card
        expect(find.text('STORY DESIGN'), findsOneWidget);
        expect(find.text('QuikBoom Enterprise Workspace'), findsOneWidget);
        expect(find.text('PUR-001'), findsOneWidget);
        expect(find.text('PRODUCTION'), findsOneWidget);
        expect(find.text('Start Work'), findsOneWidget);
      },
    );

    testWidgets(
      '7. EmployeeSSMWorkListView renders empty state when no activities assigned',
      (tester) async {
        final mockEmptyState = EmployeeMyWorkState(
          activeFilter: MyWorkFilter.today,
          selectedDate: DateTime(2026, 9, 9),
          isLoading: false,
          activities: const [],
          todayTotal: 0,
          todayCompleted: 0,
          todayPending: 0,
        );

        final mockPerms = WorkPermissionsState(
          isLoading: false,
          permissions: const EmployeeWorkPermissions(
            role: 'Video Editor',
            workPermissions: ['video_edit'],
            effectivePermissions: {'video_edit': true},
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              employeeMyWorkProvider.overrideWith(
                () => MockMyWorkNotifier(mockEmptyState),
              ),
              workPermissionsProvider.overrideWith(
                () => MockWorkPermissionsNotifier(mockPerms),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const EmployeeSSMWorkListView(),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('No work assigned'), findsOneWidget);
        expect(
          find.text('Your assigned activities will appear here.'),
          findsOneWidget,
        );
      },
    );
  });
}
