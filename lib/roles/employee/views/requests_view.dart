import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/constants/app_bar_titles.dart';
import 'package:quickboom_app/core/models/permission_model.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/shared/widgets/app_app_bar.dart';
import 'package:quickboom_app/shared/widgets/status_badge.dart';
import '../models/employee_leave_model.dart';
import '../viewmodels/employee_leave_viewmodel.dart';
import '../viewmodels/employee_claim_viewmodel.dart';
import '../viewmodels/employee_loan_viewmodel.dart';
import '../viewmodels/employee_remote_work_viewmodel.dart';
import 'package:quickboom_app/shared/widgets/skeleton_loader.dart';

class RequestsView extends ConsumerStatefulWidget {
  final int initialTabIndex;
  final String? initialTabType;

  const RequestsView({
    super.key,
    this.initialTabIndex = 0,
    this.initialTabType,
  });

  @override
  ConsumerState<RequestsView> createState() => _RequestsViewState();
}

class _RequestsViewState extends ConsumerState<RequestsView> {
  String _leaveFilter = 'Active';
  String _claimFilter = 'Active';
  String _loanFilter = 'Active';
  String _remoteFilter = 'Active';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rbac = ref.read(permissionManagerProvider);
      if (rbac.canView(AppModule.leave)) {
        ref.read(employeeLeaveProvider.notifier).loadAll();
      }
      if (rbac.canViewExpenses) {
        ref.read(employeeClaimProvider.notifier).loadClaims();
      }
      if (rbac.canView(AppModule.loan)) {
        ref.read(employeeLoanProvider.notifier).loadLoans();
      }
      if (rbac.canViewRemoteWork) {
        ref.read(employeeRemoteWorkProvider.notifier).loadRemoteRequests();
      }
    });
  }

  bool _isUpcomingOrToday(String dateStr) {
    if (dateStr.isEmpty) return true;
    try {
      final dt = DateTime.tryParse(dateStr);
      if (dt == null) return true;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(dt.year, dt.month, dt.day);
      return !target.isBefore(today);
    } catch (_) {
      return true;
    }
  }

  // ── LEAVE MODAL ─────────────────────────────────────────────────────────────
  void _showApplyLeaveModal(List<LeaveBalanceItem> balances) {
    int selectedTypeId = balances.isNotEmpty && balances[0].id != null
        ? balances[0].id!
        : 1;
    String selectedTypeName = balances.isNotEmpty
        ? balances[0].leaveType
        : 'Casual Leave';
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final fromOnly = DateTime(
              fromDate.year,
              fromDate.month,
              fromDate.day,
            );
            final toOnly = DateTime(toDate.year, toDate.month, toDate.day);
            final durationDays = toOnly.difference(fromOnly).inDays + 1;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply for Leave',
                      style: AppTypography.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Leave Type Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedTypeName,
                      items:
                          (balances.isNotEmpty
                                  ? balances.map((b) => b.leaveType).toList()
                                  : [
                                      'Casual Leave',
                                      'Sick Leave',
                                      'Earned Leave',
                                      'Unpaid Leave',
                                    ])
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() {
                            selectedTypeName = val;
                            final matched = balances
                                .where((b) => b.leaveType == val)
                                .firstOrNull;
                            if (matched?.id != null) {
                              selectedTypeId = matched!.id!;
                            }
                          });
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Leave Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Date Selection Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: fromDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 7),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  fromDate = picked;
                                  if (toDate.isBefore(fromDate)) {
                                    toDate = fromDate;
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Date',
                                    style: AppTypography.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fromDate.toIso8601String().split('T')[0],
                                    style: AppTypography.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: toDate,
                                firstDate: fromDate,
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() => toDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Date',
                                    style: AppTypography.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    toDate.toIso8601String().split('T')[0],
                                    style: AppTypography.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Calculated Leave Duration:',
                            style: AppTypography.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$durationDays ${durationDays == 1 ? "Day" : "Days"}',
                            style: AppTypography.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Reason for Leave *',
                        hintText:
                            'Family function, unwell, personal errands...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (reasonController.text.trim().isEmpty) {
                            AppToast.error(
                              context,
                              'Please specify the reason for leave.',
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          final success = await ref
                              .read(employeeLeaveProvider.notifier)
                              .applyLeave(
                                leaveTypeId: selectedTypeId,
                                fromDate: fromDate.toIso8601String().split(
                                  'T',
                                )[0],
                                toDate: toDate.toIso8601String().split('T')[0],
                                reason: reasonController.text.trim(),
                              );
                          if (mounted) {
                            if (success) {
                              AppToast.success(
                                context,
                                'Leave application submitted (Status: PENDING). Balance will only be deducted upon approval.',
                              );
                            } else {
                              final err = ref
                                  .read(employeeLeaveProvider)
                                  .errorMessage;
                              if (err != null) AppToast.error(context, err);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Submit Application',
                          style: AppTypography.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── EXPENSE CLAIM MODAL ─────────────────────────────────────────────────────
  void _showApplyClaimModal() {
    String selectedCategory = 'TRAVEL';
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final receiptController = TextEditingController();
    DateTime claimDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Submit Expense Claim',
                      style: AppTypography.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      items:
                          [
                                'TRAVEL',
                                'FOOD',
                                'FUEL',
                                'ACCOMMODATION',
                                'OFFICE_SUPPLIES',
                                'MEDICAL',
                                'CLIENT_ENTERTAINMENT',
                                'OTHER',
                              ]
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedCategory = val);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Expense Category *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Claim Amount (₹) *',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: claimDate,
                          firstDate: DateTime.now().subtract(
                            const Duration(days: 90),
                          ),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setModalState(() => claimDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expense Date',
                                  style: AppTypography.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  claimDate.toIso8601String().split('T')[0],
                                  style: AppTypography.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Remix.calendar_line,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description / Purpose *',
                        hintText:
                            'e.g. Taxi fare for client meeting in Mumbai...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: receiptController,
                      decoration: InputDecoration(
                        labelText: 'Receipt Attachment URL (Optional)',
                        hintText: 'https://...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final amt = double.tryParse(
                            amountController.text.trim(),
                          );
                          if (amt == null || amt <= 0) {
                            AppToast.error(
                              context,
                              'Please enter a valid expense amount.',
                            );
                            return;
                          }
                          if (descriptionController.text.trim().isEmpty) {
                            AppToast.error(
                              context,
                              'Please specify the description.',
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          final success = await ref
                              .read(employeeClaimProvider.notifier)
                              .applyClaim(
                                category: selectedCategory,
                                amount: amt,
                                description: descriptionController.text.trim(),
                                claimDate: claimDate.toIso8601String().split(
                                  'T',
                                )[0],
                                receiptUrl:
                                    receiptController.text.trim().isNotEmpty
                                    ? receiptController.text.trim()
                                    : null,
                              );
                          if (mounted) {
                            if (success) {
                              AppToast.success(
                                context,
                                'Expense claim submitted for approval (Status: PENDING).',
                              );
                            } else {
                              final err = ref
                                  .read(employeeClaimProvider)
                                  .errorMessage;
                              if (err != null) AppToast.error(context, err);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Submit Expense Claim',
                          style: AppTypography.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── LOAN MODAL ──────────────────────────────────────────────────────────────
  void _showApplyLoanModal() {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    int termMonths = 12;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
            final estimatedEmi = amt > 0 ? (amt / termMonths).round() : 0;

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request Employee Loan',
                      style: AppTypography.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Requested Loan Amount (₹) *',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    DropdownButtonFormField<int>(
                      initialValue: termMonths,
                      items: [3, 6, 12, 18, 24, 36]
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m Months ($m EMIs)'),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => termMonths = val);
                      },
                      decoration: InputDecoration(
                        labelText: 'Repayment Tenure *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (amt > 0)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Estimated Monthly Deduction:',
                              style: AppTypography.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹ $estimatedEmi / mo',
                              style: AppTypography.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Purpose / Reason for Loan *',
                        hintText:
                            'Medical emergency, education fee, home repair...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final parsedAmt = double.tryParse(
                            amountController.text.trim(),
                          );
                          if (parsedAmt == null || parsedAmt <= 0) {
                            AppToast.error(
                              context,
                              'Please enter a valid loan amount.',
                            );
                            return;
                          }
                          if (reasonController.text.trim().isEmpty) {
                            AppToast.error(
                              context,
                              'Please provide the loan reason.',
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          final success = await ref
                              .read(employeeLoanProvider.notifier)
                              .applyLoan(
                                loanAmount: parsedAmt,
                                reason: reasonController.text.trim(),
                                termMonths: termMonths,
                              );
                          if (mounted) {
                            if (success) {
                              AppToast.success(
                                context,
                                'Loan request submitted for Admin review (Status: PENDING).',
                              );
                            } else {
                              final err = ref
                                  .read(employeeLoanProvider)
                                  .errorMessage;
                              if (err != null) AppToast.error(context, err);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Submit Loan Request',
                          style: AppTypography.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── REMOTE WORK MODAL ───────────────────────────────────────────────────────
  void _showApplyRemoteModal() {
    DateTime fromDate = DateTime.now();
    DateTime toDate = DateTime.now();
    TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 18, minute: 0);
    final reasonController = TextEditingController();

    String formatTimeOfDay(TimeOfDay tod) {
      final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
      final minute = tod.minute.toString().padLeft(2, '0');
      final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
      return '${hour.toString().padLeft(2, '0')}:$minute $period';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply Remote / WFH',
                      style: AppTypography.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: fromDate,
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 7),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  fromDate = picked;
                                  if (toDate.isBefore(fromDate)) {
                                    toDate = fromDate;
                                  }
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Date',
                                    style: AppTypography.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    fromDate.toIso8601String().split('T')[0],
                                    style: AppTypography.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: toDate,
                                firstDate: fromDate,
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (picked != null) {
                                setModalState(() => toDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Date',
                                    style: AppTypography.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    toDate.toIso8601String().split('T')[0],
                                    style: AppTypography.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                              );
                              if (picked != null) {
                                setModalState(() => startTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Time',
                                    style: AppTypography.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTimeOfDay(startTime),
                                    style: AppTypography.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                              );
                              if (picked != null) {
                                setModalState(() => endTime = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'End Time',
                                    style: AppTypography.inter(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTimeOfDay(endTime),
                                    style: AppTypography.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Reason & Deliverable Commitment *',
                        hintText:
                            'Sprint focus, remote shoot post-production...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (reasonController.text.trim().isEmpty) {
                            AppToast.error(
                              context,
                              'Please specify the reason for remote work.',
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          final success = await ref
                              .read(employeeRemoteWorkProvider.notifier)
                              .applyRemoteWork(
                                fromDate: fromDate.toIso8601String().split(
                                  'T',
                                )[0],
                                toDate: toDate.toIso8601String().split('T')[0],
                                startTime: formatTimeOfDay(startTime),
                                endTime: formatTimeOfDay(endTime),
                                reason: reasonController.text.trim(),
                              );
                          if (mounted) {
                            if (success) {
                              AppToast.success(
                                context,
                                'WFH request submitted for approval.',
                              );
                            } else {
                              final err = ref
                                  .read(employeeRemoteWorkProvider)
                                  .errorMessage;
                              if (err != null) AppToast.error(context, err);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Submit WFH Request',
                          style: AppTypography.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(employeeLeaveProvider);
    final claimState = ref.watch(employeeClaimProvider);
    final loanState = ref.watch(employeeLoanProvider);
    final remoteState = ref.watch(employeeRemoteWorkProvider);

    final rbac = ref.watch(permissionManagerProvider);
    final canViewLeaves = rbac.canView(AppModule.leave);
    final canViewExpenses = rbac.canViewExpenses;
    final canViewLoans = rbac.canView(AppModule.loan);
    final canViewRemote = rbac.canViewRemoteWork;

    final canCreateLeave = rbac.canCreate(AppModule.leave);
    final canCreateExpense = rbac.canCreate(AppModule.expenses);
    final canCreateLoan = rbac.canCreate(AppModule.loan);
    final canCreateRemote = rbac.canCreate(AppModule.remoteWork);

    final tabs = <Widget>[];
    final views = <Widget>[];

    if (canViewLeaves) {
      tabs.add(const Tab(text: 'Leaves'));
      views.add(_buildLeaveTab(leaveState, canCreateLeave: canCreateLeave));
    }

    if (canViewExpenses) {
      tabs.add(const Tab(text: 'Expenses'));
      views.add(
        _buildClaimsTab(claimState, canCreateExpense: canCreateExpense),
      );
    }

    if (canViewLoans) {
      tabs.add(const Tab(text: 'Loans'));
      views.add(_buildLoansTab(loanState, canCreateLoan: canCreateLoan));
    }

    if (canViewRemote) {
      tabs.add(const Tab(text: 'Remote Work'));
      views.add(_buildRemoteTab(remoteState, canCreateRemote: canCreateRemote));
    }

    if (tabs.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppAppBar(
          title: AppBarTitles.requests,
          showBackButton: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Remix.lock_2_line,
                size: 48,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 12),
              Text(
                'You do not have permission to view any requests.',
                style: AppTypography.inter(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    int resolvedIndex = widget.initialTabIndex;
    if (widget.initialTabType != null) {
      final target = widget.initialTabType!.toLowerCase();
      if (target == 'leaves' || target == 'leave') {
        final idx = tabs.indexWhere(
          (t) => t is Tab && (t.text?.toLowerCase().contains('leave') ?? false),
        );
        if (idx != -1) resolvedIndex = idx;
      } else if (target == 'expenses' ||
          target == 'claims' ||
          target == 'expense') {
        final idx = tabs.indexWhere(
          (t) =>
              t is Tab && (t.text?.toLowerCase().contains('expense') ?? false),
        );
        if (idx != -1) resolvedIndex = idx;
      } else if (target == 'loans' || target == 'loan') {
        final idx = tabs.indexWhere(
          (t) => t is Tab && (t.text?.toLowerCase().contains('loan') ?? false),
        );
        if (idx != -1) resolvedIndex = idx;
      } else if (target == 'remote' || target == 'remotework') {
        final idx = tabs.indexWhere(
          (t) =>
              t is Tab && (t.text?.toLowerCase().contains('remote') ?? false),
        );
        if (idx != -1) resolvedIndex = idx;
      }
    }
    if (resolvedIndex < 0 || resolvedIndex >= tabs.length) {
      resolvedIndex = 0;
    }

    return DefaultTabController(
      length: tabs.length,
      initialIndex: resolvedIndex,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppAppBar(
          title: AppBarTitles.requests,
          showBackButton: true,
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            labelStyle: AppTypography.inter(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            tabs: tabs,
          ),
        ),
        body: TabBarView(children: views),
      ),
    );
  }

  BadgeType _getBadgeType(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'PAID':
      case 'ACTIVE':
        return BadgeType.approved;
      case 'REJECTED':
      case 'CANCELLED':
        return BadgeType.rejected;
      case 'PENDING':
      default:
        return BadgeType.pending;
    }
  }

  // ── 1. LEAVE TAB ────────────────────────────────────────────────────────────
  Widget _buildLeaveTab(LeaveState leaveState, {required bool canCreateLeave}) {
    if (leaveState.isLoading &&
        leaveState.leaveRequests.isEmpty &&
        leaveState.balances.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            Row(
              children: const [
                Expanded(child: SkeletonStatCard()),
                SizedBox(width: 12),
                Expanded(child: SkeletonStatCard()),
              ],
            ),
            const SizedBox(height: 16),
            const SkeletonCard(),
            const SkeletonCard(),
            const SkeletonCard(),
          ],
        ),
      );
    }

    if (leaveState.errorMessage != null && leaveState.leaveRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Remix.error_warning_line,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                leaveState.errorMessage!,
                style: AppTypography.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(employeeLeaveProvider.notifier).loadAll(),
                icon: const Icon(Remix.refresh_line, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredLeaves = leaveState.leaveRequests.where((req) {
      final isUpcoming = _isUpcomingOrToday(req.toDate);
      final isActiveOrPending = req.isPending || (req.isApproved && isUpcoming);
      if (_leaveFilter == 'Active') {
        return isActiveOrPending;
      } else {
        return !isActiveOrPending;
      }
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(employeeLeaveProvider.notifier).loadAll(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leaveState.balances.isNotEmpty) ...[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: leaveState.balances.map((b) {
                  final idx = leaveState.balances.indexOf(b);
                  final color = idx == 0
                      ? AppColors.primary
                      : (idx == 1
                            ? AppColors.warning
                            : (idx == 2
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF6366F1)));
                  final totalStr = b.isUnlimited
                      ? 'Unlimited'
                      : '${b.totalAllowed.toInt()} Total';
                  final remainStr = b.isUnlimited
                      ? '∞'
                      : '${b.remaining.toInt()}';
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 50) / 2,
                    child: _buildBalanceCard(
                      b.leaveType,
                      remainStr,
                      totalStr,
                      color,
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Leave Applications',
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canCreateLeave)
                  ElevatedButton.icon(
                    onPressed: () => _showApplyLeaveModal(leaveState.balances),
                    icon: const Icon(Remix.add_line, size: 16),
                    label: const Text('Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildFilterSegment(
              selected: _leaveFilter,
              onSelect: (v) => setState(() => _leaveFilter = v),
            ),
            const SizedBox(height: 16),

            if (filteredLeaves.isEmpty)
              _buildEmptyState('No $_leaveFilter leave applications')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLeaves.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final req = filteredLeaves[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                req.leaveType,
                                style: AppTypography.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: req.status,
                              type: _getBadgeType(req.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Remix.calendar_event_line,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${req.fromDate} to ${req.toDate} • ${req.isHalfDay ? 'Half Day' : 'Full Day'} (${req.days} ${req.days == 1 ? 'day' : 'days'})',
                                style: AppTypography.inter(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (req.appliedOn != null &&
                            req.appliedOn!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Remix.time_line,
                                size: 13,
                                color: AppColors.textPlaceholder,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Applied: ${req.appliedOn}',
                                style: AppTypography.inter(
                                  color: AppColors.textPlaceholder,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (req.reason.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            req.reason,
                            style: AppTypography.inter(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                        if (req.isRejected &&
                            req.rejectionReason != null &&
                            req.rejectionReason!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Remix.close_circle_line,
                                  size: 14,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Reason: ${req.rejectionReason}',
                                    style: AppTypography.inter(
                                      fontSize: 12,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── 2. EXPENSE CLAIMS TAB ───────────────────────────────────────────────────
  Widget _buildClaimsTab(
    EmployeeClaimState claimState, {
    required bool canCreateExpense,
  }) {
    final filteredClaims = claimState.claims.where((c) {
      if (_claimFilter == 'Active') return c.isPending;
      return !c.isPending;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(employeeClaimProvider.notifier).loadClaims(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Expense Claims',
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canCreateExpense)
                  ElevatedButton.icon(
                    onPressed: _showApplyClaimModal,
                    icon: const Icon(Remix.add_line, size: 16),
                    label: const Text('New Claim'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildFilterSegment(
              selected: _claimFilter,
              onSelect: (v) => setState(() => _claimFilter = v),
            ),
            const SizedBox(height: 16),

            if (filteredClaims.isEmpty)
              _buildEmptyState('No $_claimFilter expense claims')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredClaims.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = filteredClaims[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              c.category,
                              style: AppTypography.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            StatusBadge(
                              label: c.status,
                              type: _getBadgeType(c.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Claimed: ₹ ${c.amount.toStringAsFixed(0)}',
                              style: AppTypography.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            if (c.approvedAmount != null && c.isApproved)
                              Text(
                                'Approved: ₹ ${c.approvedAmount!.toStringAsFixed(0)}',
                                style: AppTypography.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          c.description,
                          style: AppTypography.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (c.rejectionReason != null && c.isRejected) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${c.rejectionReason}',
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── 3. LOANS TAB ────────────────────────────────────────────────────────────
  Widget _buildLoansTab(
    EmployeeLoanState loanState, {
    required bool canCreateLoan,
  }) {
    final filteredLoans = loanState.loans.where((l) {
      if (_loanFilter == 'Active') return l.isPending || l.isActive;
      return !l.isPending && !l.isActive;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(employeeLoanProvider.notifier).loadLoans(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Loan Requests',
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canCreateLoan)
                  ElevatedButton.icon(
                    onPressed: _showApplyLoanModal,
                    icon: const Icon(Remix.add_line, size: 16),
                    label: const Text('Request Loan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildFilterSegment(
              selected: _loanFilter,
              onSelect: (v) => setState(() => _loanFilter = v),
            ),
            const SizedBox(height: 16),

            if (filteredLoans.isEmpty)
              _buildEmptyState('No $_loanFilter loan records')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLoans.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final l = filteredLoans[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹ ${l.loanAmount.toStringAsFixed(0)} (${l.termMonths} Mo)',
                              style: AppTypography.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            StatusBadge(
                              label: l.status,
                              type: _getBadgeType(l.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Monthly EMI: ₹ ${l.monthlyEmi.toStringAsFixed(0)}',
                              style: AppTypography.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (l.remainingBalance != null && l.isActive)
                              Text(
                                'Remaining: ₹ ${l.remainingBalance!.toStringAsFixed(0)}',
                                style: AppTypography.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warning,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l.reason,
                          style: AppTypography.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (l.rejectionReason != null && l.isRejected) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Reason: ${l.rejectionReason}',
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── 4. REMOTE WORK TAB ──────────────────────────────────────────────────────
  Widget _buildRemoteTab(
    RemoteWorkState remoteState, {
    required bool canCreateRemote,
  }) {
    if (remoteState.isLoading && remoteState.requests.isEmpty) {
      return const SkeletonList(count: 4);
    }

    if (remoteState.errorMessage != null && remoteState.requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Remix.error_warning_line,
                size: 48,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              Text(
                remoteState.errorMessage!,
                style: AppTypography.inter(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref
                    .read(employeeRemoteWorkProvider.notifier)
                    .loadRemoteRequests(),
                icon: const Icon(Remix.refresh_line, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filteredRemote = remoteState.requests.where((r) {
      final isUpcoming = _isUpcomingOrToday(r.toDate);
      final isActiveOrPending = r.isPending || (r.isApproved && isUpcoming);
      if (_remoteFilter == 'Active') {
        return isActiveOrPending;
      } else {
        return !isActiveOrPending;
      }
    }).toList();

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(employeeRemoteWorkProvider.notifier).loadRemoteRequests(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Remote Work (WFH)',
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canCreateRemote)
                  ElevatedButton.icon(
                    onPressed: _showApplyRemoteModal,
                    icon: const Icon(Remix.add_line, size: 16),
                    label: const Text('Apply WFH'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            _buildFilterSegment(
              selected: _remoteFilter,
              onSelect: (v) => setState(() => _remoteFilter = v),
            ),
            const SizedBox(height: 16),

            if (filteredRemote.isEmpty)
              _buildEmptyState('No $_remoteFilter remote work requests')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredRemote.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final r = filteredRemote[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${r.fromDate} to ${r.toDate}',
                                style: AppTypography.inter(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge(
                              label: r.status,
                              type: _getBadgeType(r.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Remix.time_line,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${r.startTime} – ${r.endTime} • ${r.duration ?? '${r.days} Days'}',
                                style: AppTypography.inter(
                                  fontSize: 11.5,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        if (r.appliedOn != null && r.appliedOn!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Remix.calendar_check_line,
                                size: 12,
                                color: AppColors.textPlaceholder,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Applied: ${r.appliedOn}',
                                style: AppTypography.inter(
                                  fontSize: 11.5,
                                  color: AppColors.textPlaceholder,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          r.reason,
                          style: AppTypography.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (r.isRejected &&
                            r.rejectionReason != null &&
                            r.rejectionReason!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.error.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Remix.close_circle_line,
                                  size: 14,
                                  color: AppColors.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Reason: ${r.rejectionReason}',
                                    style: AppTypography.inter(
                                      fontSize: 12,
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── HELPER WIDGETS ──────────────────────────────────────────────────────────
  Widget _buildFilterSegment({
    required String selected,
    required Function(String) onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton(
              title: 'Active / Pending',
              isSelected: selected == 'Active',
              onTap: () => onSelect('Active'),
            ),
          ),
          Expanded(
            child: _buildSegmentButton(
              title: 'History',
              isSelected: selected == 'History',
              onTap: () => onSelect('History'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTypography.inter(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(
    String title,
    String count,
    String subtext,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: AppTypography.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: AppTypography.inter(
              fontSize: 11,
              color: AppColors.textPlaceholder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            const Icon(
              Remix.inbox_line,
              size: 36,
              color: AppColors.textPlaceholder,
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: AppTypography.inter(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
