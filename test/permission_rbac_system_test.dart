import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/services/secure_storage_service.dart';
import 'package:quickboom_app/shared/widgets/permission_guarded_view.dart';

/// Helper: builds the full set of admin permissions (mirrors backend ROLE_PERMISSION_DEFAULTS).
List<UserPermission> _buildAdminPermissions() {
  const modules = [
    AppModule.dashboard,
    AppModule.leads,
    AppModule.customers,
    AppModule.followUp,
    AppModule.visits,
    AppModule.proposals,
    AppModule.payments,
    AppModule.notifications,
    AppModule.attendance,
    AppModule.leave,
    AppModule.tasks,
    AppModule.salary,
    AppModule.loan,
    AppModule.reports,
    AppModule.settings,
  ];
  const actions = [
    PermissionAction.view,
    PermissionAction.create,
    PermissionAction.edit,
    PermissionAction.delete,
  ];
  return [
    for (final m in modules)
      for (final a in actions) UserPermission(module: m, action: a),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SecureStorageService.clearMockValues();
    PermissionManager.instance.clear();
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 1. Permission Model & Normalization
  // ─────────────────────────────────────────────────────────────────────────
  group('Permission Models & Normalization', () {
    test('AppModule normalizes synonyms correctly', () {
      expect(AppModule.normalize('lead'), AppModule.leads);
      expect(AppModule.normalize('LEADS'), AppModule.leads);
      expect(AppModule.normalize('followup'), AppModule.followUp);
      expect(AppModule.normalize('FOLLOW_UPS'), AppModule.followUp);
      expect(AppModule.normalize('attendance'), AppModule.attendance);
      expect(AppModule.normalize('leaves'), AppModule.leave);
      expect(AppModule.normalize('requests'), AppModule.leave);
      expect(AppModule.normalize('payroll'), AppModule.salary);
      expect(AppModule.normalize('salary_slip'), AppModule.salary);
      expect(AppModule.normalize('tasks'), AppModule.tasks);
      expect(AppModule.normalize('visits'), AppModule.visits);
      expect(AppModule.normalize('home'), AppModule.dashboard);
      expect(AppModule.normalize('client'), AppModule.customers);
      expect(AppModule.normalize('quote'), AppModule.proposals);
      expect(AppModule.normalize('invoice'), AppModule.payments);
    });

    test('PermissionAction normalizes synonyms correctly', () {
      expect(PermissionAction.normalize('read'), PermissionAction.view);
      expect(PermissionAction.normalize('view'), PermissionAction.view);
      expect(PermissionAction.normalize('add'), PermissionAction.create);
      expect(PermissionAction.normalize('create'), PermissionAction.create);
      expect(PermissionAction.normalize('update'), PermissionAction.edit);
      expect(PermissionAction.normalize('edit'), PermissionAction.edit);
      expect(PermissionAction.normalize('remove'), PermissionAction.delete);
      expect(
        PermissionAction.normalize('status'),
        PermissionAction.changeStage,
      );
      expect(
        PermissionAction.normalize('CHANGE_STATUS'),
        PermissionAction.changeStage,
      );
      expect(
        PermissionAction.normalize('CHANGE_STAGE'),
        PermissionAction.changeStage,
      );
    });

    test('UserPermission parses from JSON correctly', () {
      final perm = UserPermission.fromJson({
        'module': 'leads',
        'action': 'view',
      });
      expect(perm.module, AppModule.leads);
      expect(perm.action, PermissionAction.view);
      expect(perm.toJson(), {
        'module': AppModule.leads,
        'action': PermissionAction.view,
      });
    });

    test('UserPermission.parseAny handles List<Map> format', () {
      final perms = UserPermission.parseAny([
        {'module': 'leads', 'action': 'view'},
        {'module': 'leads', 'action': 'create'},
        {'module': 'attendance', 'action': 'view'},
      ]);
      expect(perms.length, 3);
      expect(perms[0].module, AppModule.leads);
      expect(perms[0].action, PermissionAction.view);
    });

    test('UserPermission.parseAny handles effectivePermissions Map format', () {
      final raw = {
        'leads': {'view': true, 'create': true, 'edit': false},
        'attendance': {'view': true, 'create': false},
        'reports': {'view': false},
      };
      final perms = UserPermission.parseAny(raw);
      expect(
        perms.any(
          (p) =>
              p.module == AppModule.leads && p.action == PermissionAction.view,
        ),
        isTrue,
      );
      expect(
        perms.any(
          (p) =>
              p.module == AppModule.leads &&
              p.action == PermissionAction.create,
        ),
        isTrue,
      );
      expect(
        perms.any(
          (p) =>
              p.module == AppModule.leads && p.action == PermissionAction.edit,
        ),
        isFalse,
      );
      expect(
        perms.any(
          (p) =>
              p.module == AppModule.attendance &&
              p.action == PermissionAction.view,
        ),
        isTrue,
      );
      expect(
        perms.any(
          (p) =>
              p.module == AppModule.reports &&
              p.action == PermissionAction.view,
        ),
        isFalse,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 2. ROLE 1: Telecaller
  // ─────────────────────────────────────────────────────────────────────────
  group('ROLE 1: Telecaller — limited CRM access', () {
    setUp(() {
      PermissionManager.instance.setPermissions([
        const UserPermission(
          module: AppModule.dashboard,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.edit,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.changeStage,
        ),
        const UserPermission(module: AppModule.leads, action: 'TAB_OVERVIEW'),
        const UserPermission(module: AppModule.leads, action: 'TAB_ACTIVITY'),
        const UserPermission(
          module: AppModule.followUp,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.followUp,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.customers,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.settings,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.settings,
          action: 'SETTING_PROFILE',
        ),
        const UserPermission(
          module: AppModule.settings,
          action: 'SETTING_NOTIFICATIONS',
        ),
      ], role: 'TELECALLER');
    });

    test(
      'Dashboard is accessible',
      () => expect(
        PermissionManager.instance.canView(AppModule.dashboard),
        isTrue,
      ),
    );
    test(
      'Leads list is visible',
      () => expect(PermissionManager.instance.canView(AppModule.leads), isTrue),
    );
    test(
      'Add Lead button visible (create)',
      () =>
          expect(PermissionManager.instance.canCreate(AppModule.leads), isTrue),
    );
    test(
      'Edit Lead visible',
      () => expect(PermissionManager.instance.canEdit(AppModule.leads), isTrue),
    );
    test(
      'Delete Lead HIDDEN',
      () => expect(
        PermissionManager.instance.canDelete(AppModule.leads),
        isFalse,
      ),
    );
    test(
      'Status Change permitted',
      () => expect(
        PermissionManager.instance.canAction(AppModule.leads, 'CHANGE_STATUS'),
        isTrue,
      ),
    );
    test(
      'Leads Overview tab visible',
      () => expect(
        PermissionManager.instance.canViewTab(AppModule.leads, 'OVERVIEW'),
        isTrue,
      ),
    );
    test(
      'Leads Activity tab visible',
      () => expect(
        PermissionManager.instance.canViewTab(AppModule.leads, 'ACTIVITY'),
        isTrue,
      ),
    );
    test(
      'Follow-up accessible',
      () => expect(
        PermissionManager.instance.canView(AppModule.followUp),
        isTrue,
      ),
    );
    test(
      'Customers list visible (view only)',
      () => expect(
        PermissionManager.instance.canView(AppModule.customers),
        isTrue,
      ),
    );
    test(
      'Add Customer HIDDEN',
      () => expect(
        PermissionManager.instance.canCreate(AppModule.customers),
        isFalse,
      ),
    );
    test(
      'Reports tab ABSENT',
      () => expect(
        PermissionManager.instance.canView(AppModule.reports),
        isFalse,
      ),
    );
    test('Settings shows (profile + notifications)', () {
      expect(PermissionManager.instance.canView(AppModule.settings), isTrue);
      expect(PermissionManager.instance.canViewSetting('PROFILE'), isTrue);
      expect(
        PermissionManager.instance.canViewSetting('NOTIFICATIONS'),
        isTrue,
      );
    });
    test(
      'Integrations settings tile HIDDEN',
      () => expect(
        PermissionManager.instance.canViewSetting('INTEGRATIONS'),
        isFalse,
      ),
    );
    test(
      'Attendance HIDDEN',
      () => expect(
        PermissionManager.instance.canView(AppModule.attendance),
        isFalse,
      ),
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 3. ROLE 2: Sales Executive
  // ─────────────────────────────────────────────────────────────────────────
  group('ROLE 2: Sales Executive — CRM + Visits', () {
    setUp(() {
      PermissionManager.instance.setPermissions([
        const UserPermission(
          module: AppModule.dashboard,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.edit,
        ),
        const UserPermission(module: AppModule.leads, action: 'CHANGE_STATUS'),
        const UserPermission(
          module: AppModule.visits,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.visits,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.visits,
          action: PermissionAction.edit,
        ),
        const UserPermission(
          module: AppModule.followUp,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.followUp,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.customers,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.proposals,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.proposals,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.settings,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.settings,
          action: 'SETTING_PROFILE',
        ),
      ], role: 'SALES_EXECUTIVE');
    });

    test(
      'Dashboard shows',
      () => expect(
        PermissionManager.instance.canView(AppModule.dashboard),
        isTrue,
      ),
    );
    test('Leads with create', () {
      expect(PermissionManager.instance.canView(AppModule.leads), isTrue);
      expect(PermissionManager.instance.canCreate(AppModule.leads), isTrue);
    });
    test('Customers view only', () {
      expect(PermissionManager.instance.canView(AppModule.customers), isTrue);
      expect(
        PermissionManager.instance.canCreate(AppModule.customers),
        isFalse,
      );
    });
    test('Visits CRE (no delete)', () {
      expect(PermissionManager.instance.canView(AppModule.visits), isTrue);
      expect(PermissionManager.instance.canCreate(AppModule.visits), isTrue);
      expect(PermissionManager.instance.canEdit(AppModule.visits), isTrue);
      expect(PermissionManager.instance.canDelete(AppModule.visits), isFalse);
    });
    test(
      'Reports ABSENT',
      () => expect(
        PermissionManager.instance.canView(AppModule.reports),
        isFalse,
      ),
    );
    test('Settings — profile only', () {
      expect(PermissionManager.instance.canView(AppModule.settings), isTrue);
      expect(PermissionManager.instance.canViewSetting('PROFILE'), isTrue);
      expect(PermissionManager.instance.canViewSetting('USERS'), isFalse);
    });
    test(
      'Attendance HIDDEN',
      () => expect(
        PermissionManager.instance.canView(AppModule.attendance),
        isFalse,
      ),
    );
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 4. ROLE 3: Manager
  // ─────────────────────────────────────────────────────────────────────────
  group('ROLE 3: Manager — broad CRM + HRM access', () {
    setUp(() {
      PermissionManager.instance.setPermissions([
        const UserPermission(
          module: AppModule.dashboard,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.edit,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.delete,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.changeStage,
        ),
        const UserPermission(module: AppModule.leads, action: 'EXPORT'),
        const UserPermission(
          module: AppModule.customers,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.customers,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.customers,
          action: PermissionAction.edit,
        ),
        const UserPermission(
          module: AppModule.followUp,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.followUp,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.followUp,
          action: PermissionAction.edit,
        ),
        const UserPermission(
          module: AppModule.followUp,
          action: PermissionAction.delete,
        ),
        const UserPermission(
          module: AppModule.visits,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.visits,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.visits,
          action: PermissionAction.edit,
        ),
        const UserPermission(
          module: AppModule.visits,
          action: PermissionAction.delete,
        ),
        const UserPermission(
          module: AppModule.attendance,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.attendance,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.attendance,
          action: PermissionAction.edit,
        ),
        const UserPermission(
          module: AppModule.leave,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leave,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.leave,
          action: PermissionAction.edit,
        ),
        const UserPermission(
          module: AppModule.leave,
          action: PermissionAction.approve,
        ),
        const UserPermission(
          module: AppModule.leave,
          action: PermissionAction.reject,
        ),
        const UserPermission(
          module: AppModule.tasks,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.tasks,
          action: PermissionAction.create,
        ),
        const UserPermission(
          module: AppModule.tasks,
          action: PermissionAction.edit,
        ),
        const UserPermission(
          module: AppModule.reports,
          action: PermissionAction.view,
        ),
        const UserPermission(module: AppModule.reports, action: 'EXPORT'),
        const UserPermission(
          module: AppModule.settings,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.settings,
          action: 'SETTING_PROFILE',
        ),
      ], role: 'MANAGER');
    });

    test('Full Leads CRUD + actions', () {
      expect(PermissionManager.instance.canView(AppModule.leads), isTrue);
      expect(PermissionManager.instance.canCreate(AppModule.leads), isTrue);
      expect(PermissionManager.instance.canEdit(AppModule.leads), isTrue);
      expect(PermissionManager.instance.canDelete(AppModule.leads), isTrue);
      expect(
        PermissionManager.instance.canAction(AppModule.leads, 'CHANGE_STATUS'),
        isTrue,
      );
      expect(
        PermissionManager.instance.canAction(AppModule.leads, 'EXPORT'),
        isTrue,
      );
    });
    test('Customers CRE (no delete)', () {
      expect(PermissionManager.instance.canView(AppModule.customers), isTrue);
      expect(PermissionManager.instance.canCreate(AppModule.customers), isTrue);
      expect(PermissionManager.instance.canEdit(AppModule.customers), isTrue);
      expect(
        PermissionManager.instance.canDelete(AppModule.customers),
        isFalse,
      );
    });
    test('Visits full CRUD', () {
      expect(PermissionManager.instance.canView(AppModule.visits), isTrue);
      expect(PermissionManager.instance.canDelete(AppModule.visits), isTrue);
    });
    test('Leave approve/reject', () {
      expect(
        PermissionManager.instance.canAction(
          AppModule.leave,
          PermissionAction.approve,
        ),
        isTrue,
      );
      expect(
        PermissionManager.instance.canAction(
          AppModule.leave,
          PermissionAction.reject,
        ),
        isTrue,
      );
    });
    test('Reports visible + export', () {
      expect(PermissionManager.instance.canView(AppModule.reports), isTrue);
      expect(
        PermissionManager.instance.canAction(AppModule.reports, 'EXPORT'),
        isTrue,
      );
    });
    test('Settings — profile only, no team management', () {
      expect(PermissionManager.instance.canView(AppModule.settings), isTrue);
      expect(PermissionManager.instance.canViewSetting('PROFILE'), isTrue);
      expect(PermissionManager.instance.canViewSetting('USERS'), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5. Admin roles — full permission set from backend
  // ─────────────────────────────────────────────────────────────────────────
  group('Super Admin / Company Admin — full permissions from backend', () {
    test('With full permission set has access to all modules', () {
      PermissionManager.instance.setPermissions(
        _buildAdminPermissions(),
        role: 'SUPER_ADMIN',
      );
      expect(PermissionManager.instance.isReady, isTrue);
      expect(PermissionManager.instance.canView(AppModule.attendance), isTrue);
      expect(
        PermissionManager.instance.canCreate(AppModule.attendance),
        isTrue,
      );
      expect(PermissionManager.instance.canDelete(AppModule.leads), isTrue);
      expect(PermissionManager.instance.canView(AppModule.salary), isTrue);
      expect(PermissionManager.instance.canView(AppModule.reports), isTrue);
      expect(PermissionManager.instance.canView(AppModule.settings), isTrue);
    });

    test('After clear, all permissions revoked', () {
      PermissionManager.instance.setPermissions(
        _buildAdminPermissions(),
        role: 'SUPER_ADMIN',
      );
      expect(PermissionManager.instance.canView(AppModule.leads), isTrue);
      PermissionManager.instance.clear();
      expect(PermissionManager.instance.isReady, isFalse);
      expect(PermissionManager.instance.canView(AppModule.leads), isFalse);
    });

    test('Company Admin with full permission set has same access', () {
      PermissionManager.instance.setPermissions(
        _buildAdminPermissions(),
        role: 'COMPANY_ADMIN',
      );
      expect(PermissionManager.instance.canView(AppModule.attendance), isTrue);
      expect(PermissionManager.instance.canView(AppModule.salary), isTrue);
      expect(PermissionManager.instance.canView(AppModule.reports), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Dashboard Cards & Tab Level
  // ─────────────────────────────────────────────────────────────────────────
  group('Dashboard Cards and Tab-level checks', () {
    test('canViewCard gates by module access', () {
      PermissionManager.instance.setPermissions([
        const UserPermission(
          module: AppModule.dashboard,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.view,
        ),
      ], role: 'TELECALLER');
      expect(PermissionManager.instance.canViewCard('LEADS'), isTrue);
      expect(PermissionManager.instance.canViewCard('VISITS'), isFalse);
    });

    test('canViewTab defaults to true when no TAB_ restrictions', () {
      PermissionManager.instance.setPermissions([
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.view,
        ),
      ], role: 'EMPLOYEE');
      expect(
        PermissionManager.instance.canViewTab(AppModule.leads, 'OVERVIEW'),
        isTrue,
      );
      expect(
        PermissionManager.instance.canViewTab(AppModule.leads, 'ACTIVITY'),
        isTrue,
      );
    });

    test('canViewTab respects explicit TAB_ restrictions', () {
      PermissionManager.instance.setPermissions([
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.view,
        ),
        const UserPermission(module: AppModule.leads, action: 'TAB_OVERVIEW'),
      ], role: 'TELECALLER');
      expect(
        PermissionManager.instance.canViewTab(AppModule.leads, 'OVERVIEW'),
        isTrue,
      );
      expect(
        PermissionManager.instance.canViewTab(AppModule.leads, 'ACTIVITY'),
        isFalse,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 7. SecureStorageService Persistence
  // ─────────────────────────────────────────────────────────────────────────
  group('SecureStorageService Permissions Persistence', () {
    test('Saves, retrieves, and clears permissions', () async {
      SecureStorageService.setMockInitialValues({});
      final perms = [
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.view,
        ),
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.create,
        ),
      ];
      await SecureStorageService.savePermissions(perms);
      final retrieved = await SecureStorageService.getPermissions();
      expect(retrieved.length, 2);
      expect(retrieved[0].module, AppModule.leads);
      expect(retrieved[0].action, PermissionAction.view);
      expect(retrieved[1].action, PermissionAction.create);
      await SecureStorageService.clearAll();
      final afterClear = await SecureStorageService.getPermissions();
      expect(afterClear.isEmpty, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 8. PermissionGuardedView Widget
  // ─────────────────────────────────────────────────────────────────────────
  group('PermissionGuardedView Widget', () {
    testWidgets('Renders child when permission is granted', (tester) async {
      PermissionManager.instance.setPermissions([
        const UserPermission(
          module: AppModule.leads,
          action: PermissionAction.view,
        ),
      ], role: 'TELECALLER');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PermissionGuardedView(
              moduleKey: AppModule.leads,
              moduleTitle: 'Leads',
              child: const Text('Authorized Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Authorized Content'), findsOneWidget);
      expect(find.text('Access Restricted'), findsNothing);
    });

    testWidgets('Renders Access Restricted when permission denied', (
      tester,
    ) async {
      PermissionManager.instance.setPermissions([], role: 'TELECALLER');

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PermissionGuardedView(
              moduleKey: AppModule.attendance,
              moduleTitle: 'Attendance',
              child: const Text('Authorized Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Authorized Content'), findsNothing);
      expect(find.text('Access Restricted'), findsOneWidget);
      expect(find.textContaining('Attendance module'), findsOneWidget);
    });

    testWidgets('Admin with full perms can access Reports', (tester) async {
      PermissionManager.instance.setPermissions(
        _buildAdminPermissions(),
        role: 'COMPANY_ADMIN',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PermissionGuardedView(
              moduleKey: AppModule.reports,
              moduleTitle: 'Reports',
              child: const Text('Reports Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reports Content'), findsOneWidget);
      expect(find.text('Access Restricted'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 6. Granular Screen & Action-Level Permission Checks
  // ─────────────────────────────────────────────────────────────────────────
  group('Granular Screen & Action Permission Checks', () {
    test('canAccessScreen and canPerformAction work correctly', () {
      PermissionManager.instance.setPermissions([
        UserPermission(
          module: AppModule.proposals,
          action: PermissionAction.view,
        ),
        UserPermission(
          module: AppModule.payments,
          action: PermissionAction.view,
        ),
        UserPermission(
          module: AppModule.payments,
          action: PermissionAction.create,
        ),
      ], role: 'SALES_EXECUTIVE');

      final pm = PermissionManager.instance;
      expect(pm.canAccessScreen('PROPOSALS'), isTrue);
      expect(pm.canAccessScreen('PAYMENTS'), isTrue);
      expect(pm.canAccessScreen('LEAVE'), isFalse);
      expect(pm.canAccessScreen('LOAN'), isFalse);

      expect(pm.canPerformAction('PROPOSALS', 'VIEW'), isTrue);
      expect(pm.canPerformAction('PROPOSALS', 'CREATE'), isFalse);
      expect(pm.canPerformAction('PROPOSALS', 'EDIT'), isFalse);
      expect(pm.canPerformAction('PROPOSALS', 'DELETE'), isFalse);

      expect(pm.canPerformAction('PAYMENTS', 'VIEW'), isTrue);
      expect(pm.canPerformAction('PAYMENTS', 'CREATE'), isTrue);
      expect(pm.canPerformAction('PAYMENTS', 'DELETE'), isFalse);
    });

    test(
      'Telecaller cannot access Proposals, Payments, or Loans by default',
      () {
        PermissionManager.instance.setPermissions([
          UserPermission(
            module: AppModule.dashboard,
            action: PermissionAction.view,
          ),
          UserPermission(
            module: AppModule.leads,
            action: PermissionAction.view,
          ),
          UserPermission(
            module: AppModule.leads,
            action: PermissionAction.create,
          ),
          UserPermission(
            module: AppModule.customers,
            action: PermissionAction.view,
          ),
        ], role: 'TELECALLER');

        final pm = PermissionManager.instance;
        expect(pm.canView(AppModule.proposals), isFalse);
        expect(pm.canView(AppModule.payments), isFalse);
        expect(pm.canView(AppModule.loan), isFalse);
        expect(pm.canCreate(AppModule.proposals), isFalse);
        expect(pm.canCreate(AppModule.payments), isFalse);
      },
    );
  });
}
