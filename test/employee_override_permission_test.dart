import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Employee-Specific Permission Overrides (Hierarchy Test)', () {
    setUp(() {
      PermissionManager.instance.clear();
    });

    test('Telecaller with Role Default has canViewCalendar = false', () {
      // Default Telecaller permissions from backend
      final roleDefaultTelecaller = [
        const UserPermission(
          module: AppModule.dashboard,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.followUp,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.visits,
          action: PermissionAction.view,
        ),
      ];

      PermissionManager.instance.setPermissions(
        roleDefaultTelecaller,
        role: 'TELECALLER',
      );

      expect(PermissionManager.instance.canView(AppModule.leads), isTrue);
      expect(PermissionManager.instance.canView(AppModule.visits), isTrue);
      // Calendar is OFF by default for Telecaller
      expect(PermissionManager.instance.canViewCalendar, isFalse);
      expect(PermissionManager.instance.canView(AppModule.calendar), isFalse);
    });

    test(
      'Telecaller with Individual Override ALLOW receives Calendar access',
      () {
        // Backend resolved effective permissions with individual ALLOW override on CALENDAR
        final telecallerWithCalendarAllow = [
          const UserPermission(
            module: AppModule.dashboard,
            action: PermissionAction.view,
          ),
          const UserPermission(
            module: AppModule.leads,
            action: PermissionAction.view,
          ),
          const UserPermission(
            module: AppModule.followUp,
            action: PermissionAction.view,
          ),
          const UserPermission(
            module: AppModule.visits,
            action: PermissionAction.view,
          ),
          const UserPermission(
            module: AppModule.calendar,
            action: PermissionAction.view,
          ),
        ];

        PermissionManager.instance.setPermissions(
          telecallerWithCalendarAllow,
          role: 'TELECALLER',
        );

        expect(PermissionManager.instance.canView(AppModule.leads), isTrue);
        // Calendar is enabled via individual ALLOW override!
        expect(PermissionManager.instance.canViewCalendar, isTrue);
        expect(PermissionManager.instance.canView(AppModule.calendar), isTrue);
      },
    );

    test('Designer with Individual Override DENY loses Calendar access', () {
      // Backend resolved effective permissions for Designer where CALENDAR has DENY override
      final designerWithCalendarDeny = [
        const UserPermission(
          module: AppModule.dashboard,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.myWork,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.creativeWork,
          action: PermissionAction.view,
        ),
        // Notice CALENDAR is omitted by backend authorization layer because of DENY override
      ];

      PermissionManager.instance.setPermissions(
        designerWithCalendarDeny,
        role: 'DESIGNER',
      );

      expect(PermissionManager.instance.canView(AppModule.myWork), isTrue);
      expect(
        PermissionManager.instance.canView(AppModule.creativeWork),
        isTrue,
      );
      // Calendar is revoked via individual DENY override!
      expect(PermissionManager.instance.canViewCalendar, isFalse);
      expect(PermissionManager.instance.canView(AppModule.calendar), isFalse);
    });
  });
}
