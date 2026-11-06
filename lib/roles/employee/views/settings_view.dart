import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:quickboom_app/core/widgets/qb_widgets.dart';
import 'package:quickboom_app/shared/widgets/app_app_bar.dart';
import 'edit_profile_view.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Account Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Account'),
            const SizedBox(height: 12),
            _card([
              ProfileMenuItem(
                icon: Remix.lock_line,
                label: 'Change Password',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileView()),
                  );
                },
              ),
              _divider(),
              ProfileMenuItem(
                icon: Remix.notification_3_line,
                label: 'Notification Settings',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),
            _sectionTitle('Preferences'),
            const SizedBox(height: 12),
            _card([
              ProfileMenuItem(
                icon: Remix.global_line,
                label: 'App Language',
                onTap: () {},
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'English',
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Remix.arrow_right_s_line,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                showArrow: false,
              ),
            ]),
            const SizedBox(height: 24),
            _sectionTitle('Support'),
            const SizedBox(height: 12),
            _card([
              ProfileMenuItem(
                icon: Remix.information_line,
                label: 'About QB Suite',
                onTap: () {},
              ),
              _divider(),
              ProfileMenuItem(
                icon: Remix.question_line,
                label: 'Help & Support',
                onTap: () {},
              ),
            ]),
            const SizedBox(height: 24),
            _card([
              ProfileMenuItem(
                icon: Remix.logout_box_r_line,
                label: 'Logout',
                onTap: () => _showLogoutDialog(context, ref),
              ),
            ]),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'QB Suite v1.0.2',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.border,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Logout',
          style: AppTypography.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to logout from your account?',
          style: AppTypography.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTypography.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(loginStateProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
