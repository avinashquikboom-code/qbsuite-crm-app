import "package:quickboom_app/core/models/permission_model.dart";
import "package:quickboom_app/core/services/permission_manager.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/utils/app_date_formatter.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';
import 'package:quickboom_app/roles/company_admin/widgets/admin_stat_card.dart';
import 'package:quickboom_app/roles/company_admin/widgets/admin_quick_action_sheet.dart';
import '../work/admin_work_detail_view.dart';
import '../more/employees/admin_employees_view.dart';
import '../more/visits/admin_visits_view.dart';
import '../more/proposals/admin_proposals_view.dart';
import '../more/audit_logs/admin_audit_logs_view.dart';
import '../trending/widgets/trending_preview_section.dart';

class AdminHomeTab extends ConsumerStatefulWidget {
  final ValueChanged<int>? onNavigateTab;

  const AdminHomeTab({super.key, this.onNavigateTab});

  @override
  ConsumerState<AdminHomeTab> createState() => _AdminHomeTabState();
}

class _AdminHomeTabState extends ConsumerState<AdminHomeTab> {
  String _selectedAttendanceFilter = 'ALL';

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionManagerProvider);
    final state = ref.watch(companyAdminProvider);

    final todayWorkList = state.workList
        .where((w) => w.status == WorkStatus.inProgress)
        .toList();
    final upcomingWorkList = state.workList
        .where((w) => w.status == WorkStatus.scheduled)
        .toList();
    final todayVisits = state.visits
        .where((v) => v.status == VisitStatus.today)
        .take(4)
        .toList();
    final recentActivities = state.auditLogs.take(5).toList();

    // Filter live attendance
    final filteredAttendance = state.liveAttendanceList.where((a) {
      if (_selectedAttendanceFilter == 'WORKING') {
        return a.status == LiveAttendanceStatus.working;
      }
      if (_selectedAttendanceFilter == 'BREAK') {
        return a.status == LiveAttendanceStatus.onBreak;
      }
      if (_selectedAttendanceFilter == 'LEAVE') {
        return a.status == LiveAttendanceStatus.onLeave;
      }
      if (_selectedAttendanceFilter == 'ABSENT') {
        return a.status == LiveAttendanceStatus.absent;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            // Trigger refresh
            await Future.delayed(const Duration(milliseconds: 600));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Executive Top Hero Header with Pulse & Actions
                _buildExecutiveHeader(context, state),
                const SizedBox(height: 16),

                // 2. LIVE Workforce, Attendance, Breaks & Leave Command Center (Permission-gated)
                if (perms.canView(AppModule.attendance)) ...[
                  _buildLiveWorkforceCard(context, state, filteredAttendance),
                  const SizedBox(height: 20),
                ],

                // 3. Business KPIs Grid (Permission-gated cards)
                _buildKpiGrid(context, state),
                const SizedBox(height: 20),



                // 5. Live Field Movement & Today's Visits (Permission-gated)
                if (perms.canView(AppModule.visits)) ...[
                  _buildTodayVisitsSection(context, todayVisits),
                  const SizedBox(height: 20),
                ],

                // 6. Active SSM Production Tasks & Campaigns
                _buildWorkInProgressSection(
                  context,
                  todayWorkList,
                  upcomingWorkList,
                ),
                const SizedBox(height: 20),

                // 7. Interactive Customer Calendar & Schedule
                
                const SizedBox(height: 20),

                // 8. Trending Velocity Preview
                TrendingPreviewSection(
                  onViewAll: () => widget.onNavigateTab?.call(2),
                ),
                const SizedBox(height: 20),

                // 9. Real-time Activity Timeline / Audit Feed
                _buildActivityStreamSection(context, recentActivities),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Executive Top Header ───────────────────────────────────────────────
  Widget _buildExecutiveHeader(BuildContext context, CompanyAdminState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, const Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Remix.shield_user_fill,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF22C55E,
                                ).withValues(alpha: 0.6),
                                blurRadius: 6,
                                spreadRadius: 1.5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'LIVE WORKSPACE',
                            style: AppTypography.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF86EFAC),
                              letterSpacing: 0.8,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.profile.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => AdminQuickActionSheet.show(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(
                    Remix.add_line,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Live Workforce, Attendance, Breaks & Leave Command Center ─────────
  Widget _buildLiveWorkforceCard(
    BuildContext context,
    CompanyAdminState state,
    List<AdminLiveAttendance> attendanceList,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Remix.user_location_fill,
                        color: Color(0xFF0284C7),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Staff Attendance',
                            style: AppTypography.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Real-time workforce & break monitoring',
                            style: AppTypography.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminEmployeesView()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Roster',
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Remix.arrow_right_s_line,
                        size: 14,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4 Status Counters
          Row(
            children: [
              Expanded(
                child: _buildLiveStatusChip(
                  label: 'Working',
                  count: state.presentStaffCount,
                  color: const Color(0xFF16A34A),
                  bgColor: const Color(0xFFDCFCE7),
                  icon: Remix.checkbox_circle_fill,
                  isSelected: _selectedAttendanceFilter == 'WORKING',
                  onTap: () {
                    setState(() {
                      _selectedAttendanceFilter =
                          _selectedAttendanceFilter == 'WORKING'
                          ? 'ALL'
                          : 'WORKING';
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildLiveStatusChip(
                  label: 'On Break',
                  count: state.onBreakStaffCount,
                  color: const Color(0xFFD97706),
                  bgColor: const Color(0xFFFEF3C7),
                  icon: Remix.cup_fill,
                  isSelected: _selectedAttendanceFilter == 'BREAK',
                  onTap: () {
                    setState(() {
                      _selectedAttendanceFilter =
                          _selectedAttendanceFilter == 'BREAK'
                          ? 'ALL'
                          : 'BREAK';
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildLiveStatusChip(
                  label: 'On Leave',
                  count: state.onLeaveStaffCount,
                  color: const Color(0xFF9333EA),
                  bgColor: const Color(0xFFF3E8FF),
                  icon: Remix.calendar_close_fill,
                  isSelected: _selectedAttendanceFilter == 'LEAVE',
                  onTap: () {
                    setState(() {
                      _selectedAttendanceFilter =
                          _selectedAttendanceFilter == 'LEAVE'
                          ? 'ALL'
                          : 'LEAVE';
                    });
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildLiveStatusChip(
                  label: 'Absent',
                  count: state.absentStaffCount,
                  color: const Color(0xFFDC2626),
                  bgColor: const Color(0xFFFEE2E2),
                  icon: Remix.close_circle_fill,
                  isSelected: _selectedAttendanceFilter == 'ABSENT',
                  onTap: () {
                    setState(() {
                      _selectedAttendanceFilter =
                          _selectedAttendanceFilter == 'ABSENT'
                          ? 'ALL'
                          : 'ABSENT';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Live Employee List
          if (attendanceList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'No staff members in this filter',
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: attendanceList.length > 5 ? 5 : attendanceList.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final att = attendanceList[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: att.status.bgColor,
                        child: Icon(
                          att.status.icon,
                          size: 16,
                          color: att.status.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    att.employeeName,
                                    style: AppTypography.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: att.status.bgColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    att.status.label.toUpperCase(),
                                    style: AppTypography.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: att.status.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              att.status == LiveAttendanceStatus.onBreak
                                  ? 'Break: ${AppDateFormatter.formatAttendanceTime(att.breakStartTime, fallback: "Active")} (${att.breakDuration}) • ${att.location}'
                                  : (att.status == LiveAttendanceStatus.onLeave
                                        ? 'Leave: ${att.leaveType ?? "Approved"} (${att.leaveReason ?? "Rest"})'
                                        : 'In: ${AppDateFormatter.formatAttendanceTime(att.punchInTime, fallback: "—")} • ${att.location}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.inter(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (att.status == LiveAttendanceStatus.working)
                        Text(
                          att.totalWorkingHours,
                          style: AppTypography.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildLiveStatusChip({
    required String label,
    required int count,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(height: 2),
            Text(
              '$count',
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.inter(
                fontSize: 8.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. KPI Grid (Dynamically filtered by UI permissions) ────────────────────
  Widget _buildKpiGrid(BuildContext context, CompanyAdminState state) {
    final perms = ref.watch(permissionManagerProvider);
    final cards = <Widget>[
      if (perms.canViewCard("VISITS") || perms.canView(AppModule.visits))
        AdminStatCard(
          title: "Today's Visits",
          value: "${state.todayVisitsCount}",
          icon: Remix.map_pin_time_line,
          iconColor: const Color(0xFF9333EA),
          iconBgColor: const Color(0xFFF3E8FF),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminVisitsView()),
          ),
        ),
      if (perms.canViewCard("WORK") || perms.canView(AppModule.tasks))
        AdminStatCard(
          title: "Active SSM Work",
          value: "${state.activeSSMWorkCount}",
          icon: Remix.clapperboard_line,
          iconColor: const Color(0xFF0D9488),
          iconBgColor: const Color(0xFFCCFBF1),
          onTap: () => widget.onNavigateTab?.call(1),
        ),
      if (perms.canViewCard("PROPOSALS") || perms.canView(AppModule.proposals))
        AdminStatCard(
          title: "Pending Proposals",
          value: "${state.pendingProposalsCount}",
          icon: Remix.file_paper_2_line,
          iconColor: const Color(0xFFEA580C),
          iconBgColor: const Color(0xFFFFEDD5),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminProposalsView()),
          ),
        ),
      if (perms.canViewCard("EMPLOYEES") ||
          perms.canView("EMPLOYEES") ||
          perms.canView(AppModule.settings))
        AdminStatCard(
          title: "Total Employees",
          value: "${state.totalEmployees}",
          icon: Remix.user_star_line,
          iconColor: const Color(0xFF0284C7),
          iconBgColor: const Color(0xFFE0F2FE),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminEmployeesView()),
          ),
        ),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Operational KPIs",
          style: AppTypography.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.18,
          children: cards,
        ),
      ],
    );
  }



  // ── 5. Field Movement & Today's Visits ────────────────────────────────────
  Widget _buildTodayVisitsSection(
    BuildContext context,
    List<AdminVisit> visits,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Today's Field Visits",
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminVisitsView()),
          ),
        ),
        const SizedBox(height: 10),
        if (visits.isEmpty)
          _buildEmptyRow('No field visits scheduled for today')
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visits.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
              itemBuilder: (context, index) {
                final v = visits[index];
                return InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminVisitsView()),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Remix.map_pin_2_fill,
                            size: 17,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                v.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${v.employeeName} • ${v.time} • ${v.location}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.inter(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: v.status.bgColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            v.status.label,
                            style: AppTypography.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: v.status.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── 6. Work in Progress Section ───────────────────────────────────────────
  Widget _buildWorkInProgressSection(
    BuildContext context,
    List<AdminSSMWork> todayWorkList,
    List<AdminSSMWork> upcomingWorkList,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          "Today's Work Execution",
          () => widget.onNavigateTab?.call(2),
        ),
        const SizedBox(height: 10),
        if (todayWorkList.isNotEmpty)
          _buildFeaturedWorkCard(context, todayWorkList.first)
        else
          _buildEmptyRow('No active production tasks scheduled for today'),
        const SizedBox(height: 16),
        _buildSectionHeader(
          'Upcoming Scheduled Work',
          () => widget.onNavigateTab?.call(2),
        ),
        const SizedBox(height: 10),
        if (upcomingWorkList.isNotEmpty)
          _buildFeaturedWorkCard(context, upcomingWorkList.first)
        else
          _buildEmptyRow('No upcoming work scheduled'),
      ],
    );
  }

  // ── 7. Activity Stream ───────────────────────────────────────────────────
  Widget _buildActivityStreamSection(
    BuildContext context,
    List<AdminAuditLog> activities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Live Activity Stream',
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAuditLogsView()),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: activities.map((log) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 5),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  log.action,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${log.date}, ${log.time}',
                                style: AppTypography.inter(
                                  fontSize: 10.5,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.description,
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
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: onSeeAll,
          child: Text(
            'See All >',
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedWorkCard(BuildContext context, AdminSSMWork work) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminWorkDetailView(work: work),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        work.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: work.status.bgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        work.status.label,
                        style: AppTypography.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: work.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${work.workType.label} • ${work.platform} • ${work.team}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: work.durationDays > 0
                              ? work.currentDay / work.durationDays
                              : 0.5,
                          backgroundColor: const Color(0xFFF1F5F9),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Day ${work.currentDay}/${work.durationDays}',
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyRow(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          message,
          style: AppTypography.inter(
            fontSize: 12.5,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
