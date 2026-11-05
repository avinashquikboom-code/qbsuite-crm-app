import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_my_work_viewmodel.dart';

void main() {
  group('1. Production Manager Role & Permission Detection', () {
    test('identifies Production Manager and supervisory roles correctly', () {
      const pm1 = EmployeeWorkPermissions(
        role: 'Production Manager',
        workPermissions: ['video_edit', 'post_design', 'reel_shoot'],
      );
      expect(pm1.isProductionManager, isTrue);
      expect(pm1.isSupervisor, isTrue);

      const pm2 = EmployeeWorkPermissions(
        role: 'PRODUCTION_MANAGER',
        workPermissions: [],
      );
      expect(pm2.isProductionManager, isTrue);
      expect(pm2.isSupervisor, isTrue);

      const lead = EmployeeWorkPermissions(
        role: 'Production Lead',
        workPermissions: [],
      );
      expect(lead.isProductionManager, isTrue);
      expect(lead.isSupervisor, isTrue);

      const admin = EmployeeWorkPermissions(role: 'Admin', workPermissions: []);
      expect(admin.isSupervisor, isTrue);
    });

    test(
      'strictly denies Production Manager supervisory role to normal staff',
      () {
        const editor = EmployeeWorkPermissions(
          role: 'Video Editor',
          workPermissions: ['video_edit'],
        );
        expect(editor.isProductionManager, isFalse);
        expect(editor.isSupervisor, isFalse);

        const designer = EmployeeWorkPermissions(
          role: 'Graphic Designer',
          workPermissions: ['post_design'],
        );
        expect(designer.isProductionManager, isFalse);
        expect(designer.isSupervisor, isFalse);

        const shooter = EmployeeWorkPermissions(
          role: 'Photographer',
          workPermissions: ['reel_shoot'],
        );
        expect(shooter.isProductionManager, isFalse);
        expect(shooter.isSupervisor, isFalse);

        const smm = EmployeeWorkPermissions(
          role: 'Social Media Manager',
          workPermissions: ['reel_post'],
        );
        expect(smm.isProductionManager, isFalse);
        expect(smm.isSupervisor, isFalse);
      },
    );
  });

  group('2. Supervisory Filtering & State Management', () {
    test(
      'supervisory filter state stores customer, employee, team, and status selections',
      () {
        final state = EmployeeMyWorkState(
          selectedDate: DateTime(2026, 9, 7),
          selectedCustomerId: 10,
          selectedCustomerName: 'Test Pvt Ltd',
          selectedEmployeeId: 2,
          selectedEmployeeName: 'Employee B',
          selectedTeamId: 5,
          selectedTeamName: 'Video Editing Team',
          selectedStatus: 'IN_PROGRESS',
          selectedDateRange: 'TODAY',
          prodTotal: 15,
          prodInProgress: 5,
          prodPending: 4,
          prodCompleted: 5,
          prodBlocked: 1,
          prodToday: 3,
          prodOverdue: 2,
          availableCustomers: const [
            {'id': 10, 'name': 'Test Pvt Ltd'},
            {'id': 11, 'name': 'Acme Corp'},
          ],
          availableEmployees: const [
            {'id': 1, 'name': 'Employee A'},
            {'id': 2, 'name': 'Employee B'},
          ],
          availableTeams: const [
            {'id': 5, 'name': 'Video Editing Team'},
          ],
        );

        expect(state.selectedCustomerId, 10);
        expect(state.selectedCustomerName, 'Test Pvt Ltd');
        expect(state.selectedEmployeeId, 2);
        expect(state.selectedEmployeeName, 'Employee B');
        expect(state.selectedTeamId, 5);
        expect(state.selectedTeamName, 'Video Editing Team');
        expect(state.selectedStatus, 'IN_PROGRESS');
        expect(state.prodTotal, 15);
        expect(state.prodInProgress, 5);
        expect(state.prodBlocked, 1);
        expect(state.prodOverdue, 2);
      },
    );

    test(
      'copyWith properly clears customer, employee, and team filters when requested',
      () {
        var state = EmployeeMyWorkState(
          selectedDate: DateTime(2026, 9, 7),
          selectedCustomerId: 10,
          selectedCustomerName: 'Test Pvt Ltd',
          selectedEmployeeId: 2,
          selectedEmployeeName: 'Employee B',
        );

        state = state.copyWith(clearCustomer: true);
        expect(state.selectedCustomerId, isNull);
        expect(state.selectedCustomerName, isNull);
        expect(state.selectedEmployeeId, 2);

        state = state.copyWith(clearEmployee: true);
        expect(state.selectedEmployeeId, isNull);
        expect(state.selectedEmployeeName, isNull);
      },
    );
  });

  group('3. Single Source of Truth Work Serialization & Parsing', () {
    test(
      'parses shared Work record with customer, assigned employee, team, date, and employee update notes',
      () {
        final json = {
          'id': '12345',
          'activityId': '12345',
          'customerId': '10',
          'customerName': 'Test Pvt Ltd',
          'title': 'Reel Edit',
          'scheduledDate': '2026-09-07',
          'scheduledTime': '10:00 AM',
          'type': 'REEL_EDIT',
          'status': 'IN_PROGRESS',
          'assignedToId': 2,
          'assignedEmployee': 'Employee B',
          'team': 'Video Editing Team',
          'assignedTeam': 'Video Editing Team',
          'notes': 'First cut completed.',
        };

        final activity = CustomerCalendarActivity.fromJson(json);

        expect(activity.id, '12345');
        expect(activity.customerName, 'Test Pvt Ltd');
        expect(activity.title, 'Reel Edit');
        expect(activity.type, 'REEL_EDIT');
        expect(activity.status, 'IN_PROGRESS');
        expect(activity.assignedEmployee, 'Employee B');
        expect(activity.team, 'Video Editing Team');
        expect(activity.notes, 'First cut completed.');
      },
    );

    test(
      'preserves status change across role representations with identical ID and date',
      () {
        final activityPending = CustomerCalendarActivity.fromJson({
          'id': '12345',
          'customerName': 'Test Pvt Ltd',
          'title': 'Reel Edit',
          'scheduledDate': '2026-09-07',
          'status': 'PENDING',
          'assignedEmployee': 'Employee B',
        });

        final activityCompleted = activityPending.copyWith(status: 'COMPLETED');

        expect(activityCompleted.id, activityPending.id);
        expect(activityCompleted.customerName, 'Test Pvt Ltd');
        expect(activityCompleted.status, 'COMPLETED');
        expect(activityCompleted.assignedEmployee, 'Employee B');
        expect(activityCompleted.date, activityPending.date);
      },
    );
  });
}
