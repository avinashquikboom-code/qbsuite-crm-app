import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickboom_app/core/theme/app_theme.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/roles/employee/models/work_permission_model.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_my_work_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/ssm/employee_ssm_work_list_view.dart';

class MockWorkPermissionsNotifier extends WorkPermissionsNotifier {
  final WorkPermissionsState mockState;
  MockWorkPermissionsNotifier(this.mockState);

  @override
  WorkPermissionsState build() => mockState;

  @override
  Future<void> loadPermissions() async {}

  @override
  Future<void> refresh() async {}
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EmployeeSSMWorkListView Banner Row RenderFlex Overflow Tests', () {
    final screenWidths = [320.0, 360.0, 375.0, 390.0, 414.0, 430.0];

    for (final width in screenWidths) {
      testWidgets(
        'Renders at ${width}px with long employee role without RenderFlex overflow',
        (tester) async {
          tester.view.physicalSize = Size(width, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          final mockPerms = WorkPermissionsState(
            isLoading: false,
            permissions: const EmployeeWorkPermissions(
              role: 'Senior Video Editor & Motion Graphics Lead',
              workPermissions: ['video_edit', 'post_design'],
              effectivePermissions: {'video_edit': true, 'post_design': true},
            ),
          );

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                workPermissionsProvider.overrideWith(
                  () => MockWorkPermissionsNotifier(mockPerms),
                ),
                employeeMyWorkProvider.overrideWith(
                  () => MockEmployeeMyWorkNotifier(),
                ),
                permissionManagerProvider.overrideWith(
                  () => MockPermissionNotifier(),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const EmployeeSSMWorkListView(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Must not throw any RenderFlex overflow exception
          expect(tester.takeException(), isNull);
          expect(find.text('Authorized Modules'), findsOneWidget);
        },
      );
    }

    testWidgets('Renders at 360px with default permissions without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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
            workPermissionsProvider.overrideWith(
              () => MockWorkPermissionsNotifier(mockPerms),
            ),
            employeeMyWorkProvider.overrideWith(
              () => MockEmployeeMyWorkNotifier(),
            ),
            permissionManagerProvider.overrideWith(
              () => MockPermissionNotifier(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const EmployeeSSMWorkListView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Authorized Modules'), findsOneWidget);
      expect(find.text('Video Editor'), findsOneWidget);
    });
  });
}
