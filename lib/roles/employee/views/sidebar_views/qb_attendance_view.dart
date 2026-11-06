import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_attendance_viewmodel.dart';
import 'package:quickboom_app/roles/employee/views/sidebar_views/attendance_view.dart';

class QBAttendanceView extends ConsumerStatefulWidget {
  final bool showBackButton;

  const QBAttendanceView({super.key, this.showBackButton = true});

  @override
  ConsumerState<QBAttendanceView> createState() => _QBAttendanceViewState();
}

class _QBAttendanceViewState extends ConsumerState<QBAttendanceView> {
  Timer? _liveClockTimer;

  @override
  void initState() {
    super.initState();
    _liveClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _liveClockTimer?.cancel();
    super.dispose();
  }

  String _dateStr() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const weekDays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return '${weekDays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}';
  }

  Future<void> _checkOut() async {
    final success = await ref.read(employeeAttendanceProvider.notifier).punchOut();
    if (!mounted) return;
    if (success) {
      AppToast.success(context, 'Checked out successfully.');
      Navigator.pop(context);
    } else {
      final err = ref.read(employeeAttendanceProvider).actionError ??
          ref.read(employeeAttendanceProvider).errorMessage;
      if (err != null && err.isNotEmpty) {
        AppToast.error(context, err);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(employeeAttendanceProvider);
    final isCheckedIn = attendanceState.isPunchedIn && !attendanceState.isCompleted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: widget.showBackButton,
        title: Text(
          'Attendance Details',
          style: AppTypography.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isCheckedIn
                      ? AppColors.primaryLight
                      : AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCheckedIn
                      ? Remix.checkbox_circle_fill
                      : Remix.time_line,
                  size: 50,
                  color: isCheckedIn ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isCheckedIn ? 'You Are Checked In' : 'You Are Not Checked In',
                style: AppTypography.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _dateStr(),
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _AttendanceDetailRow(
                      label: 'Punch In Time',
                      value: attendanceState.punchInTimeFormatted,
                      icon: Remix.login_box_line,
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 20),
                    _AttendanceDetailRow(
                      label: 'Working Hours',
                      value: attendanceState.workingHoursFormatted,
                      icon: Remix.timer_line,
                    ),
                    const SizedBox(height: 20),
                    Container(height: 1, color: AppColors.border),
                    const SizedBox(height: 20),
                    _AttendanceDetailRow(
                      label: 'Check Out',
                      value: attendanceState.punchOutTimeFormatted,
                      icon: Remix.logout_box_r_line,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const AttendanceView(showBackButton: true),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'View Details',
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isCheckedIn ? _checkOut : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Check Out',
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class _AttendanceDetailRow extends StatelessWidget {
  const _AttendanceDetailRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: AppTypography.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
