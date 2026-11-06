import 'package:flutter/material.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';

class AdminWorkDetailView extends StatelessWidget {
  final AdminSSMWork work;

  const AdminWorkDetailView({super.key, required this.work});

  @override
  Widget build(BuildContext context) {
    final w = work;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Work Details',
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
              // Main Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getWorkTypeColor(
                              w.workType,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getWorkTypeIcon(w.workType),
                            color: _getWorkTypeColor(w.workType),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      w.customerName,
                                      style: AppTypography.inter(
                                        fontSize: 17,
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
                                      color: w.status.bgColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      w.status.label,
                                      style: AppTypography.inter(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: w.status.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${w.workType.label} • ${w.socialAccount} (${w.platform})',
                                style: AppTypography.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 14),

                    // Metadata Grid
                    _buildMetaPair('Assigned Team', w.team),
                    _buildMetaPair('Team Members', w.teamMembers.join(', ')),
                    _buildMetaPair('Lead Staff', w.assignedEmployee),
                    _buildMetaPair(
                      'Duration',
                      '${w.durationDays} Day${w.durationDays > 1 ? 's' : ''} (Current: Day ${w.currentDay})',
                    ),
                    _buildMetaPair(
                      'Timeline',
                      '${w.startDate.day}/${w.startDate.month} to ${w.endDate.day}/${w.endDate.month}',
                    ),
                    _buildMetaPair('Priority', w.priority),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Day-Wise Visual Timeline Section
              Text(
                'Day-wise Work Breakdown & Tasks',
                style: AppTypography.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Timeline Container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: List.generate(w.allTasks.length, (index) {
                    final task = w.allTasks[index];
                    final isLast = index == w.allTasks.length - 1;
                    return _buildTimelineItem(task, isLast);
                  }),
                ),
              ),

              if (w.notes != null) ...[
                const SizedBox(height: 18),
                Text(
                  'Creative Brief & Instructions',
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    w.notes!,
                    style: AppTypography.inter(
                      fontSize: 13.5,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(DayTask task, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Indicator with connecting line
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? const Color(0xFF16A34A)
                      : (task.isCurrent
                            ? AppColors.primary
                            : const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: task.isCompleted
                      ? const Icon(
                          Remix.check_line,
                          color: Colors.white,
                          size: 16,
                        )
                      : Text(
                          '${task.day}',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: task.isCurrent
                                ? Colors.white
                                : const Color(0xFF64748B),
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Task Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Day ${task.day}: ${task.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (task.isCurrent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TODAY',
                            style: AppTypography.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.description,
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPair(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getWorkTypeColor(WorkType type) {
    switch (type) {
      case WorkType.reel:
        return const Color(0xFF9333EA);
      case WorkType.shoot:
        return const Color(0xFF0284C7);
      case WorkType.post:
        return const Color(0xFFD97706);
    }
  }

  IconData _getWorkTypeIcon(WorkType type) {
    switch (type) {
      case WorkType.reel:
        return Remix.film_fill;
      case WorkType.shoot:
        return Remix.camera_3_fill;
      case WorkType.post:
        return Remix.image_2_fill;
    }
  }
}
