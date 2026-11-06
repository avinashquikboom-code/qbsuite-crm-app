import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:google_fonts/google_fonts.dart";
import "package:remixicon/remixicon.dart";
import "package:quickboom_app/core/models/permission_model.dart";
import "package:quickboom_app/core/services/permission_manager.dart";
import "package:quickboom_app/core/theme/app_colors.dart";
import "package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart";
import "app_app_bar.dart";

class PermissionGuardedView extends ConsumerWidget {
  final String moduleKey;
  final String moduleTitle;
  final String action;
  final Widget child;

  const PermissionGuardedView({
    super.key,
    required this.moduleKey,
    required this.moduleTitle,
    this.action = PermissionAction.view,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Check RBAC permissions first
    final permState = ref.watch(permissionManagerProvider);
    final normModule = AppModule.normalize(moduleKey);
    final isEmployeeCrmModule = const {
      AppModule.dataCapture,
      AppModule.leads,
      AppModule.customers,
    }.contains(normModule);

    // If normalized module is a customer module or recognized CRM module, use RBAC check
    if (normModule.startsWith('CUSTOMER_')) {
      if (permState.customerCan(normModule, action)) {
        return child;
      }
    } else if (AppModule.all.contains(normModule)) {
      if (permState.hasPermission(normModule, action) &&
          (!isEmployeeCrmModule || permState.isCrmEligible)) {
        return child;
      }
    } else {
      // Legacy creative work permission check
      final permsState = ref.watch(workPermissionsProvider);
      if (permsState.hasWorkPermission(moduleKey)) {
        return child;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppAppBar(title: moduleTitle),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Remix.lock_2_line,
                  size: 36,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Access Restricted",
                style: AppTypography.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "You do not have permission to access the $moduleTitle module. Contact your administrator if you need access.",
                textAlign: TextAlign.center,
                style: AppTypography.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Remix.arrow_left_line, size: 16),
                    label: Text(
                      "Go Back",
                      style: AppTypography.inter(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
