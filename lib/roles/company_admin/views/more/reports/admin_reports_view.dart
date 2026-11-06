import 'package:flutter/material.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/shared/widgets/permission_guarded_view.dart';

class AdminReportsView extends ConsumerWidget {
  const AdminReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(permissionManagerProvider);
    if (!perms.canView(AppModule.reports)) {
      return const PermissionGuardedView(
        moduleKey: AppModule.reports,
        moduleTitle: "Analytics & Reports",
        child: SizedBox(),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Analytics & Reports',
          style: AppTypography.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Filter Header
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reporting Cycle: August 2026',
                          style: AppTypography.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Real-time agency operational metrics',
                          style: AppTypography.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Monthly',
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. Customer Growth & Retention
              _buildReportCard(
                title: 'Customer Growth & Retention',
                icon: Remix.building_2_line,
                color: const Color(0xFF16A34A),
                bgColor: const Color(0xFFDCFCE7),
                metrics: [
                  _Metric('Total Clients', '48', '+12% MoM'),
                  _Metric('Active Retainers', '44', '91.6% rate'),
                  _Metric('Churn Rate', '1.8%', '-0.4% MoM'),
                ],
                progressLabel: 'Active Retainer Health',
                progressValue: 0.92,
              ),
              const SizedBox(height: 14),

              // 2. Team Performance (Team A vs Team B)
              _buildReportCard(
                title: 'SSM Team Performance',
                icon: Remix.team_line,
                color: const Color(0xFF9333EA),
                bgColor: const Color(0xFFF3E8FF),
                metrics: [
                  _Metric('Team A On-Time', '96%', '7 Active'),
                  _Metric('Team B On-Time', '94%', '5 Active'),
                  _Metric('Avg Turnaround', '2.4 Days', 'Shoot to edit'),
                ],
                progressLabel: 'Overall Production Velocity',
                progressValue: 0.95,
              ),
              const SizedBox(height: 14),

              // 3. Employee Performance
              _buildReportCard(
                title: 'Employee Performance & Output',
                icon: Remix.user_star_line,
                color: const Color(0xFF0284C7),
                bgColor: const Color(0xFFE0F2FE),
                metrics: [
                  _Metric('Top Performer', 'Demo User', '28 Done'),
                  _Metric('Active Staff', '24', '100% Present'),
                  _Metric('Tasks Completed', '142', 'This month'),
                ],
                progressLabel: 'Task Completion Rate',
                progressValue: 0.88,
              ),
              const SizedBox(height: 14),

              // 4. Lead Conversion Performance
              _buildReportCard(
                title: 'Lead Pipeline & Conversion',
                icon: Remix.funds_line,
                color: const Color(0xFFD97706),
                bgColor: const Color(0xFFFEF3C7),
                metrics: [
                  _Metric('Total Leads', '18', 'This month'),
                  _Metric('Converted', '8', '44.4% Conv.'),
                  _Metric('Follow-up Due', '6', 'High priority'),
                ],
                progressLabel: 'Inbound Conversion Benchmark',
                progressValue: 0.44,
              ),
              const SizedBox(height: 14),

              // 5. Proposals & Revenue Pipeline
              _buildReportCard(
                title: 'Proposals & Pipeline Value',
                icon: Remix.file_paper_2_line,
                color: const Color(0xFF0D9488),
                bgColor: const Color(0xFFCCFBF1),
                metrics: [
                  _Metric('Total Quoted', '₹1,75,000', '4 Proposals'),
                  _Metric('Accepted', '₹60,000', '1 Active'),
                  _Metric('Pending', '₹95,000', 'In review'),
                ],
                progressLabel: 'Proposal Close Rate',
                progressValue: 0.65,
              ),
              const SizedBox(height: 14),

              // 6. Field Visits & Data Capture
              _buildReportCard(
                title: 'Field Visits & Data Capture',
                icon: Remix.map_pin_time_line,
                color: const Color(0xFFE11D48),
                bgColor: const Color(0xFFFFE4E6),
                metrics: [
                  _Metric("Today's Visits", '6', 'All assigned'),
                  _Metric('Verified Data', '18', '100% Accuracy'),
                  _Metric('Geo-Checkins', '24', 'Verified logs'),
                ],
                progressLabel: 'Visit SLA Compliance',
                progressValue: 0.98,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard({
    required String title,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required List<_Metric> metrics,
    required String progressLabel,
    required double progressValue,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: AppTypography.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: metrics.map((m) {
              return Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.value,
                      style: AppTypography.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      m.title,
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      m.sub,
                      style: AppTypography.inter(
                        fontSize: 10.5,
                        color: const Color(0xFF16A34A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    progressLabel,
                    style: AppTypography.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${(progressValue * 100).toInt()}%',
                    style: AppTypography.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric {
  final String title;
  final String value;
  final String sub;
  _Metric(this.title, this.value, this.sub);
}
