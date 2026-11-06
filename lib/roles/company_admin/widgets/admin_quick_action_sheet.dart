import 'package:quickboom_app/core/icons/remix_icon.dart';
import 'package:flutter/material.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';


class AdminQuickActionSheet extends StatelessWidget {
  final VoidCallback onScheduleVisit;
  final VoidCallback onCreateProposal;
  final VoidCallback onCreateSSMWork;
  final VoidCallback onAssignTask;

  const AdminQuickActionSheet({
    super.key,
    required this.onScheduleVisit,
    required this.onCreateProposal,
    required this.onCreateSSMWork,
    required this.onAssignTask,
  });

  static void show(BuildContext context) {
    
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Remix.flashlight_fill,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Company Quick Actions',
                    style: AppTypography.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Quickly execute actions across your agency',
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          _buildActionItem(
            context,
            icon: Remix.clapperboard_line,
            color: const Color(0xFF9333EA),
            bgColor: const Color(0xFFF3E8FF),
            title: 'Create SSM Work',
            subtitle: 'Schedule Reel, Shoot, or Post workflow',
            onTap: () {
              Navigator.pop(context);
              onCreateSSMWork();
            },
          ),
          _buildActionItem(
            context,
            icon: Remix.file_paper_2_line,
            color: const Color(0xFFD97706),
            bgColor: const Color(0xFFFEF3C7),
            title: 'Create Proposal',
            subtitle: 'Generate pricing quote with auto client details',
            onTap: () {
              Navigator.pop(context);
              onCreateProposal();
            },
          ),
          _buildActionItem(
            context,
            icon: Remix.map_pin_time_line,
            color: const Color(0xFF0D9488),
            bgColor: const Color(0xFFCCFBF1),
            title: 'Schedule Visit',
            subtitle: 'Book field client visit or location shoot',
            onTap: () {
              Navigator.pop(context);
              onScheduleVisit();
            },
          ),
          _buildActionItem(
            context,
            icon: Remix.task_line,
            color: const Color(0xFF4F46E5),
            bgColor: const Color(0xFFEEF2FF),
            title: 'Assign Task',
            subtitle: 'Assign task directly to employee or team',
            onTap: () {
              Navigator.pop(context);
              onAssignTask();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
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
                          fontWeight: FontWeight.w700,
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
                  LegacyRemixIcons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
