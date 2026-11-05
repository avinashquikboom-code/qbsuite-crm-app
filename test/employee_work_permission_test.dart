import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/employee/models/employee_ssm_work_model.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_ssm_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/ssm/employee_ssm_work_list_view.dart';
import 'package:quickboom_app/roles/employee/views/ssm/employee_ssm_work_detail_view.dart';

void main() {
  group('Employee Work Permissions Unit Tests', () {
    test(
      '1. EmployeeWorkPermissions parses Video Editor permissions correctly (Leads = OFF)',
      () {
        final json = {
          'employeeId': 101,
          'employeeCode': 'EMP-002',
          'role': 'Video Editor',
          'workPermissions': ['video_edit'],
          'effectivePermissions': {
            'leads': false,
            'video_edit': true,
            'post_design': false,
            'story_design': false,
            'reel_shoot': false,
          },
          'commonModules': [
            'dashboard',
            'attendance',
            'leave',
            'calendar',
            'profile',
          ],
        };

        final perms = EmployeeWorkPermissions.fromJson(json);
        expect(perms.role, 'Video Editor');
        expect(perms.hasPermission('video_edit'), isTrue);
        expect(perms.hasPermission('leads'), isFalse);
        expect(perms.hasPermission('post_design'), isFalse);
        expect(perms.hasPermission('story_design'), isFalse);
        expect(perms.hasPermission('reel_shoot'), isFalse);
        expect(perms.commonModules, contains('dashboard'));
      },
    );

    test(
      '2. EmployeeWorkPermissions parses Graphic Designer permissions correctly (Leads = OFF)',
      () {
        final json = {
          'employeeId': 102,
          'employeeCode': 'EMP-003',
          'role': 'Graphic Designer',
          'workPermissions': ['post_design', 'story_design'],
          'effectivePermissions': {
            'leads': false,
            'video_edit': false,
            'post_design': true,
            'story_design': true,
            'reel_shoot': false,
          },
        };

        final perms = EmployeeWorkPermissions.fromJson(json);
        expect(perms.role, 'Graphic Designer');
        expect(perms.hasPermission('post_design'), isTrue);
        expect(perms.hasPermission('story_design'), isTrue);
        expect(perms.hasPermission('leads'), isFalse);
        expect(perms.hasPermission('video_edit'), isFalse);
        expect(perms.hasPermission('reel_shoot'), isFalse);
      },
    );

    test(
      '3. EmployeeWorkPermissions parses Photographer permissions correctly (Leads = OFF)',
      () {
        final json = {
          'employeeId': 103,
          'employeeCode': 'EMP-004',
          'role': 'Photographer',
          'workPermissions': ['reel_shoot'],
          'effectivePermissions': {
            'leads': false,
            'video_edit': false,
            'post_design': false,
            'story_design': false,
            'reel_shoot': true,
          },
        };

        final perms = EmployeeWorkPermissions.fromJson(json);
        expect(perms.role, 'Photographer');
        expect(perms.hasPermission('reel_shoot'), isTrue);
        expect(perms.hasPermission('leads'), isFalse);
        expect(perms.hasPermission('video_edit'), isFalse);
        expect(perms.hasPermission('post_design'), isFalse);
      },
    );

    test(
      '4. EmployeeWorkPermissions parses Employee Overrides (ALLOW leads for Designer)',
      () {
        final json = {
          'employeeId': 102,
          'employeeCode': 'EMP-003',
          'role': 'Graphic Designer',
          'workPermissions': ['post_design', 'story_design', 'leads'],
          'effectivePermissions': {
            'leads': true,
            'post_design': true,
            'story_design': true,
            'video_edit': false,
            'reel_shoot': false,
          },
        };

        final perms = EmployeeWorkPermissions.fromJson(json);
        expect(perms.hasPermission('leads'), isTrue);
        expect(perms.hasPermission('post_design'), isTrue);
        expect(perms.hasPermission('story_design'), isTrue);
      },
    );

  });

  group('Employee Work Permission Widget Tests', () {
    testWidgets(
      '6. EmployeeSSMWorkListView dynamically renders only authorized module chips',
      (tester) async {
        final videoEditorPerms = const EmployeeWorkPermissions(
          employeeId: 101,
          employeeCode: 'EMP-002',
          role: 'Video Editor',
          workPermissions: ['video_edit'],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workPermissionsProvider.overrideWith(() {
                return MockWorkPermissionsNotifier(
                  WorkPermissionsState(permissions: videoEditorPerms),
                );
              }),
            ],
            child: const MaterialApp(home: EmployeeSSMWorkListView()),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('My Work'), findsOneWidget);
        expect(find.text('Authorized Modules'), findsOneWidget);
        expect(find.text('Video Editor'), findsOneWidget);
        expect(find.text('Request Access'), findsNothing);
      },
    );

    testWidgets(
      '8. EmployeeSSMWorkDetailView renders Access Denied when employee lacks permission',
      (tester) async {
        // Graphic designer lacks reel_shoot permission
        final graphicDesignerPerms = const EmployeeWorkPermissions(
          employeeId: 102,
          employeeCode: 'EMP-003',
          role: 'Graphic Designer',
          workPermissions: ['post_design', 'story_design'],
        );

        final sampleWork = SSMWorkSchedule.fromJson({
          'id': 'ssm_work_1',
          'customerName': 'Test Corp',
          'workType': 'REEL',
          'status': 'SCHEDULED',
        });

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              workPermissionsProvider.overrideWith(() {
                return MockWorkPermissionsNotifier(
                  WorkPermissionsState(permissions: graphicDesignerPerms),
                );
              }),
              employeeSSMProvider.overrideWith(() {
                return MockPermissionSSMNotifier([sampleWork]);
              }),
            ],
            child: const MaterialApp(
              home: EmployeeSSMWorkDetailView(workId: 'ssm_work_1'),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Access Denied'), findsWidgets);
        expect(find.text('Request Access from Admin'), findsNothing);
      },
    );

    test(
      '7. Shared color coding maps all activity types to exact required palette',
      () {
        // Reel Shoot -> Orange (#F97316)
        expect(resolveTaskColor('REEL_SHOOT'), const Color(0xFFF97316));
        expect(
          resolveTaskColor(null, title: 'Reels Video Shoot'),
          const Color(0xFFF97316),
        );

        // Reel Edit / Video Editing -> Blue (#2563EB)
        expect(resolveTaskColor('REEL_EDIT'), const Color(0xFF2563EB));
        expect(resolveTaskColor('VIDEO_EDITING'), const Color(0xFF2563EB));
        expect(
          resolveTaskColor(null, title: 'Video Editing & Color Grading'),
          const Color(0xFF2563EB),
        );

        // Reel Post -> Green (#16A34A)
        expect(resolveTaskColor('REEL_POST'), const Color(0xFF16A34A));
        expect(
          resolveTaskColor(null, title: 'Reel Post #1'),
          const Color(0xFF16A34A),
        );

        // Story Design -> Purple (#9333EA)
        expect(resolveTaskColor('STORY_DESIGN'), const Color(0xFF9333EA));
        expect(
          resolveTaskColor(null, title: 'Story Design #1'),
          const Color(0xFF9333EA),
        );

        // Story Post -> Pink (#EC4899)
        expect(resolveTaskColor('STORY_POST'), const Color(0xFFEC4899));
        expect(
          resolveTaskColor(null, title: 'Story Post #1'),
          const Color(0xFFEC4899),
        );

        // Post Design -> Teal (#0D9488)
        expect(resolveTaskColor('POST_DESIGN'), const Color(0xFF0D9488));
        expect(
          resolveTaskColor(null, title: 'Creative Post Design'),
          const Color(0xFF0D9488),
        );

        // Influencer Promo -> Dark Orange (#EA580C)
        expect(resolveTaskColor('INFLUENCER_PROMO'), const Color(0xFFEA580C));
        expect(
          resolveTaskColor('INFLUENCER_PROMOTION'),
          const Color(0xFFEA580C),
        );
      },
    );

    test(
      '8. Multi-dot calendar cell extracts up to 3 distinct colors with +X overflow',
      () {
        final acts = [
          CustomerCalendarActivity.fromJson({
            'id': '1',
            'type': 'REEL_SHOOT',
            'activityType': 'REEL_SHOOT',
            'date': '2026-08-20',
          }),
          CustomerCalendarActivity.fromJson({
            'id': '2',
            'type': 'REEL_EDIT',
            'activityType': 'REEL_EDIT',
            'date': '2026-08-20',
          }),
          CustomerCalendarActivity.fromJson({
            'id': '3',
            'type': 'REEL_POST',
            'activityType': 'REEL_POST',
            'date': '2026-08-20',
          }),
          CustomerCalendarActivity.fromJson({
            'id': '4',
            'type': 'STORY_DESIGN',
            'activityType': 'STORY_DESIGN',
            'date': '2026-08-20',
          }),
        ];

        final uniqueColors = <Color>[];
        final seenCategories = <TaskCategory>{};
        for (final act in acts) {
          final cat = resolveTaskCategory(act);
          if (seenCategories.add(cat)) {
            uniqueColors.add(resolveTaskColor(act));
          }
        }

        final int extraCount = uniqueColors.length > 3
            ? uniqueColors.length - 3
            : 0;
        final displayedColors = uniqueColors.take(3).toList();

        expect(uniqueColors.length, 4);
        expect(displayedColors.length, 3);
        expect(extraCount, 1);
        expect(displayedColors[0], const Color(0xFFF97316)); // Orange
        expect(displayedColors[1], const Color(0xFF2563EB)); // Blue
        expect(displayedColors[2], const Color(0xFF16A34A)); // Green
      },
    );
  });
}

class MockPermissionSSMNotifier extends EmployeeSSMNotifier {
  final List<SSMWorkSchedule> _schedules;
  MockPermissionSSMNotifier(this._schedules);

  @override
  EmployeeSSMState build() {
    return EmployeeSSMState(
      allSchedules: _schedules,
      activityEvents: const [],
      selectedCalendarDate: DateTime(2026, 8, 20),
      todayDate: DateTime(2026, 8, 20),
      isLoading: false,
    );
  }
}

class MockWorkPermissionsNotifier extends WorkPermissionsNotifier {
  final WorkPermissionsState _initial;
  MockWorkPermissionsNotifier(this._initial);

  @override
  WorkPermissionsState build() {
    return _initial;
  }

  @override
  Future<void> loadPermissions() async {}
}
