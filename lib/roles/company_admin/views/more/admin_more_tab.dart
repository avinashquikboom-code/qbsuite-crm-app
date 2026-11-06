import 'package:quickboom_app/core/icons/remix_icon.dart';
import "package:quickboom_app/core/models/permission_model.dart";
import "package:quickboom_app/core/services/permission_manager.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';
import 'package:quickboom_app/shared/views/auth/login_view.dart';
import 'audit_logs/admin_audit_logs_view.dart';
import 'company_profile/admin_company_profile_view.dart';
import 'data_capture/admin_data_capture_view.dart';
import 'employees/admin_employees_view.dart';
import 'marketing/admin_marketing_banners_view.dart';
import 'packages/admin_packages_view.dart';
import 'proposals/admin_proposals_view.dart';
import 'reports/admin_reports_view.dart';
import 'settings/admin_settings_view.dart';
import 'visits/admin_visits_view.dart';
import '../influencers/admin_influencer_booking_management_view.dart';

class AdminMoreTab extends ConsumerWidget {
  const AdminMoreTab({super.key});

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Confirm Logout',
          style: AppTypography.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: AppTypography.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const LoginView(initialRole: MobileUserRole.admin),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: Text(
              'Logout',
              style: AppTypography.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionManagerProvider);
    final state = ref.watch(companyAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Remix.building_4_fill,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.profile.companyName,
                            style: AppTypography.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Company Admin Control Center',
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Modules List
              Text(
                'Agency Modules & Operations',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Builder(
                builder: (ctx) {
                  final items = <Widget>[
                    if (perms.canView("MARKETING"))
                      _buildMenuItem(
                        context,
                        icon: Remix.megaphone_line,
                        color: const Color(0xFF7C3AED),
                        bgColor: const Color(0xFFEDE9FE),
                        title: "Marketing & Coupons",
                        subtitle: "Manage promotional banners & offer codes",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminMarketingBannersView(),
                          ),
                        ),
                      ),
                    if (perms.canView("INFLUENCERS") ||
                        perms.canView(AppModule.dashboard))
                      _buildMenuItem(
                        context,
                        icon: Remix.star_smile_line,
                        color: const Color(0xFF059669),
                        bgColor: const Color(0xFFECFDF5),
                        title: "Influencer Bookings",
                        subtitle:
                            "Campaign requests, creator management & revenue",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AdminInfluencerBookingManagementView(),
                          ),
                        ),
                      ),
                    if (perms.canView("EMPLOYEES") ||
                        perms.canView(AppModule.tasks) ||
                        perms.canView(AppModule.settings))
                      _buildMenuItem(
                        context,
                        icon: Remix.user_star_line,
                        color: const Color(0xFF0284C7),
                        bgColor: const Color(0xFFE0F2FE),
                        title: "Employees & Teams",
                        subtitle: "Staff members and assigned teams",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminEmployeesView(),
                          ),
                        ),
                      ),
                    if (perms.canView(AppModule.visits))
                      _buildMenuItem(
                        context,
                        icon: Remix.map_pin_time_line,
                        color: const Color(0xFF9333EA),
                        bgColor: const Color(0xFFF3E8FF),
                        title: "Field Visits",
                        subtitle: "Scheduled client visits",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminVisitsView(),
                          ),
                        ),
                      ),
                    if (perms.canView("DATA_CAPTURE"))
                      _buildMenuItem(
                        context,
                        icon: Remix.database_2_line,
                        color: const Color(0xFF0D9488),
                        bgColor: const Color(0xFFCCFBF1),
                        title: "Data Capture",
                        subtitle: "Verified credentials & client assets",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminDataCaptureView(),
                          ),
                        ),
                      ),
                    if (perms.canView(AppModule.proposals))
                      _buildMenuItem(
                        context,
                        icon: Remix.file_paper_2_line,
                        color: const Color(0xFFD97706),
                        bgColor: const Color(0xFFFEF3C7),
                        title: "Proposals",
                        subtitle: "Pricing proposals and contracts",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminProposalsView(),
                          ),
                        ),
                      ),
                    if (perms.canView(AppModule.proposals) ||
                        perms.canView("PACKAGES"))
                      _buildMenuItem(
                        context,
                        icon: Remix.vip_diamond_line,
                        color: const Color(0xFFEA580C),
                        bgColor: const Color(0xFFFFEDD5),
                        title: "Service Packages",
                        subtitle: "Starter, Growth, Premium tiers",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminPackagesView(),
                          ),
                        ),
                      ),
                    if (perms.canView(AppModule.reports))
                      _buildMenuItem(
                        context,
                        icon: Remix.pie_chart_2_line,
                        color: const Color(0xFF4F46E5),
                        bgColor: const Color(0xFFEEF2FF),
                        title: "Reports & Analytics",
                        subtitle: "Agency throughput and SLA metrics",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminReportsView(),
                          ),
                        ),
                      ),
                    if (perms.canView(AppModule.settings) ||
                        perms.canView("AUDIT_LOGS"))
                      _buildMenuItem(
                        context,
                        icon: Remix.history_line,
                        color: const Color(0xFF475569),
                        bgColor: const Color(0xFFF1F5F9),
                        title: "Audit Logs",
                        subtitle: "Immutable record of staff actions",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminAuditLogsView(),
                          ),
                        ),
                      ),
                  ];
                  if (items.isEmpty) return const SizedBox.shrink();

                  final divided = <Widget>[];
                  for (int i = 0; i < items.length; i++) {
                    divided.add(items[i]);
                    if (i < items.length - 1) divided.add(_buildDivider());
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(children: divided),
                  );
                },
              ),
              const SizedBox(height: 18),

              // General & Account
              Text(
                'Company Administration',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Builder(
                builder: (ctx) {
                  final adminItems = <Widget>[
                    if (perms.canViewSetting("PROFILE"))
                      _buildMenuItem(
                        context,
                        icon: Remix.building_4_line,
                        color: const Color(0xFF0F172A),
                        bgColor: const Color(0xFFF1F5F9),
                        title: "Company Profile",
                        subtitle: "Business credentials, logo & address",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminCompanyProfileView(),
                          ),
                        ),
                      ),
                    if (perms.canView(AppModule.settings))
                      _buildMenuItem(
                        context,
                        icon: Remix.settings_3_line,
                        color: const Color(0xFF64748B),
                        bgColor: const Color(0xFFF1F5F9),
                        title: "Settings",
                        subtitle: "Language, currency, and security",
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminSettingsView(),
                          ),
                        ),
                      ),
                    _buildMenuItem(
                      context,
                      icon: Remix.logout_box_r_line,
                      color: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEE2E2),
                      title: "Logout",
                      subtitle: "Exit Company Admin workspace",
                      onTap: () => _handleLogout(context),
                    ),
                  ];

                  final divided = <Widget>[];
                  for (int i = 0; i < adminItems.length; i++) {
                    divided.add(adminItems[i]);
                    if (i < adminItems.length - 1) divided.add(_buildDivider());
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(children: divided),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                LegacyRemixIcons.arrowForwardIosRounded,
                size: 14,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9));
  }
}
