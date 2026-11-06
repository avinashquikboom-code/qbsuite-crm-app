import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/core/widgets/app_widgets.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_leave_viewmodel.dart';

class QBLeaveRequestView extends ConsumerStatefulWidget {
  const QBLeaveRequestView({super.key});

  @override
  ConsumerState<QBLeaveRequestView> createState() => _QBLeaveRequestViewState();
}

class _QBLeaveRequestViewState extends ConsumerState<QBLeaveRequestView> {
  final _reasonController = TextEditingController();
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  String? _selectedTypeName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(employeeLeaveProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  int get _durationDays {
    final from = DateTime(_fromDate.year, _fromDate.month, _fromDate.day);
    final to = DateTime(_toDate.year, _toDate.month, _toDate.day);
    return to.difference(from).inDays + 1;
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _fromDate : _toDate;
    final firstDate = isFrom ? DateTime.now() : _fromDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(firstDate) ? firstDate : initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = picked;
        if (_toDate.isBefore(_fromDate)) {
          _toDate = _fromDate;
        }
      } else {
        _toDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    final balances = ref.read(employeeLeaveProvider).balances;
    final selected = balances.where((b) => b.leaveType == _selectedTypeName).firstOrNull ??
        (balances.isNotEmpty ? balances.first : null);
    if (selected?.id == null) {
      AppToast.warning(context, 'Please select a leave type.');
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      AppToast.warning(context, 'Please enter a reason for leave.');
      return;
    }

    final success = await ref.read(employeeLeaveProvider.notifier).applyLeave(
      leaveTypeId: selected!.id!,
      fromDate: _fromDate.toIso8601String().split('T').first,
      toDate: _toDate.toIso8601String().split('T').first,
      reason: _reasonController.text.trim(),
    );
    if (!mounted) return;
    if (success) {
      AppToast.success(context, 'Leave request submitted for approval.');
      Navigator.pop(context, true);
    } else {
      final err = ref.read(employeeLeaveProvider).errorMessage;
      AppToast.error(context, err ?? 'Unable to submit leave request.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(employeeLeaveProvider);
    final balances = leaveState.balances;
    final selected = balances.where((b) => b.leaveType == _selectedTypeName).firstOrNull ??
        (balances.isNotEmpty ? balances.first : null);
    final remaining = selected?.remaining ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Leave Request',
          style: AppTypography.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: leaveState.isLoading && balances.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Remix.calendar_check_line,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available leave balance',
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                selected?.isUnlimited == true
                                    ? 'Unlimited'
                                    : '${remaining.toStringAsFixed(remaining % 1 == 0 ? 0 : 1)} days',
                                style: AppTypography.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _DateField(
                    label: 'From Date',
                    value: _formatDate(_fromDate),
                    onTap: () => _pickDate(isFrom: true),
                  ),
                  const SizedBox(height: 14),
                  _DateField(
                    label: 'To Date',
                    value: _formatDate(_toDate),
                    onTap: () => _pickDate(isFrom: false),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Leave Type',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (balances.isEmpty)
                    Text(
                      'Leave types are unavailable right now.',
                      style: AppTypography.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    )
                  else
                  DropdownButtonFormField<String>(
                    initialValue: selected?.leaveType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    items: balances
                        .map(
                          (item) => DropdownMenuItem(
                            value: item.leaveType,
                            child: Text(item.leaveType),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedTypeName = value),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Reason',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    maxLines: 4,
                    style: AppTypography.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter the reason for your leave request',
                      hintStyle: AppTypography.inter(
                        fontSize: 14,
                        color: AppColors.textPlaceholder,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Number of days',
                          style: AppTypography.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          '$_durationDays ${_durationDays == 1 ? 'Day' : 'Days'}',
                          style: AppTypography.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    label: 'Submit Request',
                    fullWidth: true,
                    height: 52,
                    loading: leaveState.isSubmitting,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: AppTypography.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Remix.calendar_line,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
