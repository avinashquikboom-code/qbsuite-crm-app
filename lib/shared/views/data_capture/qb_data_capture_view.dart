import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:quickboom_app/core/widgets/qb_widgets.dart';

class QBDataCaptureView extends StatelessWidget {
  const QBDataCaptureView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Data Capture',
          style: AppTypography.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Remix.refresh_line,
              color: AppColors.textPrimary,
              size: 24,
            ),
            onPressed: () {
              // Refresh data
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Premium Dark Green Feature Card
            PremiumFeatureCard(
              icon: Remix.map_pin_user_line,
              title: 'Google Places Lead Capture',
              subtitle: 'Find Businesses & Prospects',
              buttonLabel: 'Start New Capture',
              onButtonPressed: () {
                // Start new capture
              },
            ),
            const SizedBox(height: 24),

            // Data Capture Options
            _buildDataCaptureOption(
              icon: Remix.history_line,
              title: 'View Saved Data Capture Records',
              subtitle: 'Access your previously captured leads',
              onTap: () {},
            ),
            const SizedBox(height: 12),

            _buildDataCaptureOption(
              icon: Remix.file_list_3_line,
              title: 'Capture History',
              subtitle: 'View all your capture activities',
              onTap: () {},
            ),
            const SizedBox(height: 24),

            // Subscription Usage Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Remix.vip_crown_line,
                          size: 20,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Subscription Usage',
                              style: AppTypography.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Pro Plan - Active',
                              style: AppTypography.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Data Capture Quota
                  QuotaInfoCard(
                    label: 'Data Capture Quota',
                    used: 1450,
                    total: 2000,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),

                  // Usage Stats
                  Row(
                    children: [
                      Expanded(
                        child: _UsageStat(
                          label: 'Used Quota',
                          value: '1,450',
                          icon: Remix.checkbox_circle_fill,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: _UsageStat(
                          label: 'Remaining',
                          value: '550',
                          icon: Remix.time_line,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: _UsageStat(
                          label: 'Total Captured',
                          value: '1,847',
                          icon: Remix.database_2_line,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: AppColors.border,
                      ),
                      Expanded(
                        child: _UsageStat(
                          label: 'Successful',
                          value: '1,792',
                          icon: Remix.check_double_line,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),

                  _UsageStat(
                    label: 'Total Searches',
                    value: '2,156',
                    icon: Remix.search_eye_line,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCaptureOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: AppColors.primaryDark,
              ),
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
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Remix.arrow_right_s_line,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageStat extends StatelessWidget {
  const _UsageStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTypography.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
