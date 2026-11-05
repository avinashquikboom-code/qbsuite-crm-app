import '../views/customers/admin_customers_view.dart';
import "package:quickboom_app/core/models/permission_model.dart";
import "package:quickboom_app/core/services/permission_manager.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:remixicon/remixicon.dart';

import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';

import 'package:quickboom_app/roles/company_admin/views/more/audit_logs/admin_audit_logs_view.dart';
import 'package:quickboom_app/roles/company_admin/views/more/company_profile/admin_company_profile_view.dart';

import 'package:quickboom_app/roles/company_admin/views/more/employees/admin_employees_view.dart';

import 'package:quickboom_app/roles/company_admin/views/more/packages/admin_packages_view.dart';
import 'package:quickboom_app/roles/company_admin/views/more/proposals/admin_proposals_view.dart';
import 'package:quickboom_app/roles/company_admin/views/more/reports/admin_reports_view.dart';
import 'package:quickboom_app/roles/company_admin/views/more/settings/admin_settings_view.dart';
import 'package:quickboom_app/roles/company_admin/views/more/visits/admin_visits_view.dart';
import 'package:quickboom_app/roles/company_admin/views/more/data_capture/admin_data_capture_view.dart';
import 'package:quickboom_app/shared/views/leads/leads_view.dart';
import 'package:quickboom_app/roles/company_admin/views/team_management/admin_team_members_view.dart';
import 'package:quickboom_app/roles/company_admin/views/team_management/admin_work_types_view.dart';
import 'package:quickboom_app/roles/employee/views/notifications_view.dart';

/// Right-side Drawer for Company Admin Mobile Workspace.
class AdminAppDrawer extends ConsumerWidget {
  final void Function(int tabIndex)? onNavigateToTab;
  final int? currentTabIndex;

  const AdminAppDrawer({super.key, this.onNavigateToTab, this.currentTabIndex});

  void _handleLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(
              Remix.logout_box_r_line,
              color: AppColors.error,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to end your Company Admin session?',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (Navigator.canPop(ctx)) {
                Navigator.pop(ctx); // Close dialog
              }
              if (Navigator.canPop(context)) {
                Navigator.pop(context); // Close drawer
              }
              debugPrint(
                '[AUTH_DEBUG] logoutReason: User clicked Admin Logout',
              );
              await ref.read(loginStateProvider.notifier).logout();
            },
            child: Text(
              'Logout',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget targetScreen) {
    Navigator.pop(context); // Close drawer first
    Navigator.push(context, MaterialPageRoute(builder: (_) => targetScreen));
  }

  void _selectTab(BuildContext context, int tabIndex) {
    Navigator.pop(context); // Close drawer
    if (onNavigateToTab != null && currentTabIndex != tabIndex) {
      onNavigateToTab!(tabIndex);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionManagerProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final drawerWidth = (screenWidth * 0.84).clamp(270.0, 350.0);
    final state = ref.watch(companyAdminProvider);

    final authState = ref.watch(loginStateProvider);

    final companyName = state.profile.companyName.isNotEmpty
        ? state.profile.companyName
        : (authState.customerName?.isNotEmpty == true
              ? authState.customerName!
              : 'QB Suite Enterprise');
    final adminName =
        (authState.userName != null &&
            authState.userName!.trim().isNotEmpty &&
            authState.userName!.trim().toLowerCase() != 'demo user')
        ? authState.userName!.trim()
        : 'Admin User';

    return SizedBox(
      width: drawerWidth,
      child: Drawer(
        backgroundColor: Colors.white,
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // 1. Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
                  left: 20,
                  right: 20,
                  bottom: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryDark,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Remix.shield_user_fill,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            'ADMIN',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      adminName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      companyName,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 2. Navigation Items List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildSectionHeader('PRIMARY MODULES'),
                    if (perms.canView(AppModule.dashboard))
                      _buildDrawerItem(
                        icon: Remix.home_5_line,
                        title: 'Dashboard Home',
                        isSelected: currentTabIndex == 0,
                        onTap: () => _selectTab(context, 0),
                      ),
                    if (perms.canView(AppModule.customers))
                      _buildDrawerItem(
                        icon: Remix.building_2_line,
                        title: 'Clients & Accounts',
                        isSelected: currentTabIndex == 1,
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminCustomersView(),
                            ),
                          );
                        },
                      ),
                    if (perms.canView(AppModule.tasks))
                      _buildDrawerItem(
                        icon: Remix.clapperboard_line,
                        title: 'Work / SSM Management',
                        isSelected: currentTabIndex == 2,
                        onTap: () => _selectTab(context, 2),
                      ),
                    if (perms.canView(AppModule.visits) ||
                        perms.canView(AppModule.tasks))
                      _buildDrawerItem(
                        icon: Remix.calendar_2_line,
                        title: 'Calendar & Schedule',
                        isSelected: currentTabIndex == 3,
                        onTap: () => _selectTab(context, 3),
                      ),

                    const SizedBox(height: 8),
                    _buildSectionHeader('COMPANY OPERATIONS'),
                    if (perms.canView('EMPLOYEES') ||
                        perms.canView(AppModule.tasks) ||
                        perms.canView(AppModule.settings))
                      _buildDrawerItem(
                        icon: Remix.team_line,
                        title: 'Employees & Teams',
                        badge: '${state.employees.length}',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminEmployeesView(),
                        ),
                      ),

                    if (perms.canView(AppModule.visits))
                      _buildDrawerItem(
                        icon: Remix.map_pin_user_line,
                        title: 'Client Visits',
                        badge: '${state.visits.length}',
                        onTap: () =>
                            _navigateToScreen(context, const AdminVisitsView()),
                      ),
                    if (perms.canView(AppModule.leads) ||
                        perms.canView('DATA_CAPTURE'))
                      _buildDrawerItem(
                        icon: Remix.database_2_line,
                        title: 'Data Capture',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminDataCaptureView(),
                        ),
                      ),
                    if (perms.canView(AppModule.leads))
                      _buildDrawerItem(
                        icon: Remix.user_follow_line,
                        title: 'Leads Pipeline',
                        onTap: () =>
                            _navigateToScreen(context, const LeadsView()),
                      ),

                    if (perms.canView(AppModule.proposals))
                      _buildDrawerItem(
                        icon: Remix.file_list_3_line,
                        title: 'Proposals & Quotes',
                        badge: '${state.proposals.length}',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminProposalsView(),
                        ),
                      ),
                    if (perms.canView(AppModule.proposals) ||
                        perms.canView('PACKAGES'))
                      _buildDrawerItem(
                        icon: Remix.gift_2_line,
                        title: 'Subscription Packages',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminPackagesView(),
                        ),
                      ),

                    if (perms.canViewSetting('USERS')) ...[
                      const SizedBox(height: 8),
                      _buildSectionHeader('TEAM MANAGEMENT'),
                      _buildDrawerItem(
                        icon: Remix.task_line,
                        title: 'Work Types',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminWorkTypesView(),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Remix.team_line,
                        title: 'Team Members',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminTeamMembersView(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    _buildSectionHeader('ANALYTICS & GOVERNANCE'),
                    if (perms.canView(AppModule.reports))
                      _buildDrawerItem(
                        icon: Remix.bar_chart_box_line,
                        title: 'Performance Reports',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminReportsView(),
                        ),
                      ),
                    if (perms.canView(AppModule.settings) ||
                        perms.canView('AUDIT_LOGS'))
                      _buildDrawerItem(
                        icon: Remix.history_line,
                        title: 'System Audit Logs',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminAuditLogsView(),
                        ),
                      ),
                    if (perms.canViewSetting('PROFILE'))
                      _buildDrawerItem(
                        icon: Remix.building_4_line,
                        title: 'Company Profile',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminCompanyProfileView(),
                        ),
                      ),
                    if (perms.canView(AppModule.settings))
                      _buildDrawerItem(
                        icon: Remix.settings_3_line,
                        title: 'Settings & Config',
                        onTap: () => _navigateToScreen(
                          context,
                          const AdminSettingsView(),
                        ),
                      ),
                    _buildDrawerItem(
                      icon: Remix.notification_3_line,
                      title: 'Notifications',
                      onTap: () =>
                          _navigateToScreen(context, const NotificationsView()),
                    ),
                    _buildDrawerItem(
                      icon: Remix.logout_box_r_line,
                      title: 'Logout',
                      isDestructive: true,
                      onTap: () => _handleLogout(context, ref),
                    ),
                  ],
                ),
              ),

              // 3. Footer Branding
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'QB Suite v1.0.0 • Company Admin Workspace',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 10, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF94A3B8),
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? badge,
    bool isSelected = false,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final itemColor = isDestructive
        ? AppColors.error
        : isSelected
        ? AppColors.primaryDark
        : AppColors.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppColors.primaryLight : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 2,
          ),
          leading: Icon(icon, color: itemColor, size: 20),
          title: Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: itemColor,
            ),
          ),
          trailing: badge != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.outfit(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                )
              : const Icon(
                  Remix.arrow_right_s_line,
                  size: 16,
                  color: Color(0xFFCBD5E1),
                ),
          onTap: onTap,
        ),
      ),
    );
  }
}
