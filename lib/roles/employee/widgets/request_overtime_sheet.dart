import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:remixicon/remixicon.dart';
import '../viewmodels/employee_attendance_viewmodel.dart';

Future<void> showRequestOvertimeSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => const RequestOvertimeSheet(),
  );
}

class RequestOvertimeSheet extends ConsumerStatefulWidget {
  const RequestOvertimeSheet({super.key});

  @override
  ConsumerState<RequestOvertimeSheet> createState() =>
      _RequestOvertimeSheetState();
}

class _RequestOvertimeSheetState extends ConsumerState<RequestOvertimeSheet> {
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _otType = 'POST_SHIFT';
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 30);
  TimeOfDay _endTime = const TimeOfDay(hour: 20, minute: 30);
  bool _consent = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
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
    final day = date.day.toString().padLeft(2, '0');
    final month = months[date.month - 1];
    final year = date.year;
    return '$day $month $year';
  }

  Future<void> _submit() async {
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      AppToast.warning(context, 'Please provide a reason for overtime.');
      return;
    }
    if (!_consent) {
      AppToast.warning(context, 'Employee consent is required.');
      return;
    }

    setState(() => _isSubmitting = true);

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, "0")}-${_selectedDate.day.toString().padLeft(2, "0")}';
    final startStr =
        '${_startTime.hourOfPeriod.toString().padLeft(2, "0")}:${_startTime.minute.toString().padLeft(2, "0")} ${_startTime.period == DayPeriod.am ? "AM" : "PM"}';
    final endStr =
        '${_endTime.hourOfPeriod.toString().padLeft(2, "0")}:${_endTime.minute.toString().padLeft(2, "0")} ${_endTime.period == DayPeriod.am ? "AM" : "PM"}';
    final startMins = _startTime.hour * 60 + _startTime.minute;
    final endMins = _endTime.hour * 60 + _endTime.minute;
    final durationMins = endMins >= startMins
        ? endMins - startMins
        : 1440 - startMins + endMins;

    final success = await ref
        .read(employeeAttendanceProvider.notifier)
        .submitOvertimeRequest(
          otDate: dateStr,
          otType: _otType,
          plannedStartTime: startStr,
          plannedEndTime: endStr,
          plannedDurationMinutes: durationMins,
          reason: reason,
          employeeConsent: _consent,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      AppToast.success(context, 'Overtime request submitted for HR approval!');
      Navigator.pop(context);
    } else {
      final err = ref.read(employeeAttendanceProvider).actionError;
      AppToast.error(context, err ?? 'Failed to submit request');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle bar
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title & Subtitle
              Text(
                'Request Overtime',
                style: AppTypography.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Submit at least 1 day in advance for HR approval.',
                style: AppTypography.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),

              // Overtime Date Section
              Text(
                'Overtime Date',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate.isBefore(now)
                        ? now
                        : _selectedDate,
                    firstDate: now,
                    lastDate: now.add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE5EAF0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(_selectedDate),
                        style: AppTypography.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Icon(
                        Remix.calendar_line,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Overtime Type Section
              Text(
                'Overtime Type',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        _otType = 'POST_SHIFT';
                        _startTime = const TimeOfDay(hour: 18, minute: 30);
                        _endTime = const TimeOfDay(hour: 20, minute: 30);
                      }),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 46,
                        decoration: BoxDecoration(
                          color: _otType == 'POST_SHIFT'
                              ? const Color(0xFFF0FDF4)
                              : Colors.white,
                          border: Border.all(
                            color: _otType == 'POST_SHIFT'
                                ? AppColors.primary
                                : const Color(0xFFE5EAF0),
                            width: _otType == 'POST_SHIFT' ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Post-Shift OT',
                            style: AppTypography.inter(
                              fontSize: 14,
                              fontWeight: _otType == 'POST_SHIFT'
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _otType == 'POST_SHIFT'
                                  ? const Color(0xFF078A43)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() {
                        _otType = 'PRE_SHIFT';
                        _startTime = const TimeOfDay(hour: 7, minute: 30);
                        _endTime = const TimeOfDay(hour: 9, minute: 30);
                      }),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 46,
                        decoration: BoxDecoration(
                          color: _otType == 'PRE_SHIFT'
                              ? const Color(0xFFF0FDF4)
                              : Colors.white,
                          border: Border.all(
                            color: _otType == 'PRE_SHIFT'
                                ? AppColors.primary
                                : const Color(0xFFE5EAF0),
                            width: _otType == 'PRE_SHIFT' ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            'Pre-Shift OT',
                            style: AppTypography.inter(
                              fontSize: 14,
                              fontWeight: _otType == 'PRE_SHIFT'
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: _otType == 'PRE_SHIFT'
                                  ? const Color(0xFF078A43)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Start Time & End Time Row
              Row(
                children: [
                  Expanded(
                    child: _timeField(
                      label: 'Start Time',
                      time: _startTime,
                      onPick: (picked) => setState(() => _startTime = picked),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeField(
                      label: 'End Time',
                      time: _endTime,
                      onPick: (picked) => setState(() => _endTime = picked),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Reason for Overtime Section
              Text(
                'Reason for Overtime',
                style: AppTypography.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reasonController,
                minLines: 2,
                maxLines: 3,
                style: AppTypography.inter(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Urgent client release, extra calls',
                  hintStyle: AppTypography.inter(
                    fontSize: 13.5,
                    color: const Color(0xFF94A3B8),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF5EC269),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 14),

              // Consent Checkbox Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: _consent,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: const BorderSide(
                        color: Color(0xFFCBD5E1),
                        width: 1.5,
                      ),
                      onChanged: (val) {
                        setState(() => _consent = val ?? false);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'I consent to perform overtime under company policies.',
                      style: AppTypography.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit OT Request Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFCBD5E1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit OT Request',
                          style: AppTypography.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeField({
    required String label,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onPick,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) onPick(picked);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5EAF0)),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              time.format(context),
              style: AppTypography.inter(
                fontSize: 14.5,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
