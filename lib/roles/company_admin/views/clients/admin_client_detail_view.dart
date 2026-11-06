import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/company_admin/views/calendar/widgets/admin_activity_detail_sheet.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/roles/customer/services/customer_service.dart';

const List<String> _kMonths = [
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

String _formatDay(DateTime d) => d.day.toString().padLeft(2, '0');
String _formatMonth(DateTime d) => _kMonths[d.month - 1];
String _formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')} ${_kMonths[d.month - 1]} ${d.year}';

/// Clean model representing customer active plan and quota information
class CustomerPlanInfo {
  final String planName;
  final String planCode;
  final String status;
  final String startDate;
  final String endDate;
  final String billingCycle;
  final int totalLimit;
  final int totalUsed;
  final int totalRemaining;
  final List<CustomerQuotaItem> quotas;

  CustomerPlanInfo({
    required this.planName,
    required this.planCode,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.billingCycle,
    required this.totalLimit,
    required this.totalUsed,
    required this.totalRemaining,
    required this.quotas,
  });

  factory CustomerPlanInfo.fromBackend(
    Map<String, dynamic> json, {
    String? defaultPlanName,
  }) {
    final rawPlanName =
        json['planName']?.toString() ?? defaultPlanName ?? 'No Active Plan';
    final rawPlanCode = json['planCode']?.toString() ?? 'NONE';
    final rawStatus =
        json['status']?.toString() ??
        (rawPlanName == 'No Active Plan' ? 'NO_PLAN' : 'ACTIVE');
    final rawBilling =
        json['billingCycle']?.toString() ??
        (rawPlanName == 'No Active Plan' ? '-' : 'Monthly');
    final rawStart = json['startDate']?.toString();
    final rawEnd = json['endDate']?.toString();

    String parseIsoDate(String? iso, String fallback) {
      if (iso == null || iso.isEmpty) return fallback;
      try {
        final d = DateTime.parse(iso);
        return _formatDate(d);
      } catch (_) {
        return iso;
      }
    }

    final totalLimit = (json['totalLimit'] as num?)?.toInt() ?? 0;
    final totalUsed = (json['totalUsed'] as num?)?.toInt() ?? 0;
    final totalRemaining =
        (json['totalRemaining'] as num?)?.toInt() ?? (totalLimit - totalUsed);

    final List<CustomerQuotaItem> parsedQuotas = [];
    final rawServices = json['services'] as List<dynamic>?;
    if (rawServices != null && rawServices.isNotEmpty) {
      for (final s in rawServices) {
        if (s is Map<String, dynamic>) {
          final sName = s['serviceName']?.toString() ?? 'Deliverable';
          final sTotal = (s['totalQty'] as num?)?.toInt() ?? 1;
          final sUsed = (s['usedQty'] as num?)?.toInt() ?? 0;
          final sRem = (s['remainingQty'] as num?)?.toInt() ?? (sTotal - sUsed);
          parsedQuotas.add(
            CustomerQuotaItem(
              serviceName: sName,
              totalQty: sTotal,
              usedQty: sUsed,
              remainingQty: sRem > 0 ? sRem : 0,
              icon: _getServiceIcon(sName),
            ),
          );
        }
      }
    }

    return CustomerPlanInfo(
      planName: rawPlanName,
      planCode: rawPlanCode,
      status: rawStatus.toUpperCase(),
      startDate: parseIsoDate(rawStart, '-'),
      endDate: parseIsoDate(rawEnd, '-'),
      billingCycle: rawBilling,
      totalLimit: totalLimit,
      totalUsed: totalUsed,
      totalRemaining: totalRemaining,
      quotas: parsedQuotas,
    );
  }

  static IconData _getServiceIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('reel')) return Remix.film_line;
    if (lower.contains('post') || lower.contains('creative')) {
      return Remix.image_line;
    }
    if (lower.contains('story') || lower.contains('stories')) {
      return Remix.history_line;
    }
    if (lower.contains('influencer')) return Remix.vip_crown_line;
    return Remix.magic_line;
  }
}

class CustomerQuotaItem {
  final String serviceName;
  final int totalQty;
  final int usedQty;
  final int remainingQty;
  final IconData icon;

  CustomerQuotaItem({
    required this.serviceName,
    required this.totalQty,
    required this.usedQty,
    required this.remainingQty,
    required this.icon,
  });
}

class AdminClientDetailView extends ConsumerStatefulWidget {
  final AdminCustomer customer;

  const AdminClientDetailView({super.key, required this.customer});

  @override
  ConsumerState<AdminClientDetailView> createState() =>
      _AdminClientDetailViewState();
}

class _AdminClientDetailViewState extends ConsumerState<AdminClientDetailView> {
  CustomerPlanInfo? _planInfo;
  bool _isLoadingPlan = true;
  List<CustomerCalendarActivity> _customerActivities = const [];
  bool _isLoadingSchedules = true;
  String? _scheduleError;

  @override
  void initState() {
    super.initState();
    final activeWork = widget.customer.activeWork;
    if (activeWork.isNotEmpty &&
        activeWork != 'Basic Package' &&
        activeWork != 'No Active Plan' &&
        activeWork != 'NO_PLAN') {
      _planInfo = CustomerPlanInfo.fromBackend({
        'planName': activeWork,
        'planCode': 'ACTIVE',
        'status': widget.customer.status == ClientStatus.active
            ? 'ACTIVE'
            : 'INACTIVE',
        'startDate': null,
        'endDate': null,
        'billingCycle': 'Monthly',
        'totalLimit': 0,
        'totalUsed': 0,
        'totalRemaining': 0,
      });
    } else {
      _planInfo = null;
    }
    _isLoadingPlan = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCustomerData();
    });
  }

  Future<void> _loadCustomerData() async {
    await Future.wait([_loadLiveCustomerPlan(), _loadCustomerSchedules()]);
  }

  Future<void> _loadLiveCustomerPlan() async {
    setState(() {
      _isLoadingPlan = true;
    });

    final numericId = _targetCustomerId;
    if (numericId == null) {
      if (mounted) {
        setState(() {
          _planInfo = null;
          _isLoadingPlan = false;
        });
      }
      return;
    }

    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get('/works/customer/usage/$numericId');
      if (res.statusCode != null &&
          res.statusCode! >= 200 &&
          res.statusCode! < 300 &&
          res.data is Map<String, dynamic>) {
        final response = res.data as Map<String, dynamic>;
        final nested = response['data'];
        final data = nested is Map
            ? Map<String, dynamic>.from(nested)
            : response;
        final hasActivePlan = data['hasActivePlan'] == true;

        if (mounted) {
          setState(() {
            _planInfo = hasActivePlan
                ? CustomerPlanInfo.fromBackend(
                    data,
                    defaultPlanName: 'No Active Plan',
                  )
                : null;
            _isLoadingPlan = false;
          });
        }
        return;
      }
    } catch (_) {
      // Fallback gracefully to derived plan
    }

    if (mounted) {
      setState(() {
        _planInfo = null;
        _isLoadingPlan = false;
      });
    }
  }

  Future<void> _loadCustomerSchedules() async {
    final customerId = _targetCustomerId;
    if (customerId == null) {
      if (mounted) {
        setState(() {
          _customerActivities = const [];
          _scheduleError =
              'Schedules are unavailable because this item is not linked to a customer record.';
          _isLoadingSchedules = false;
        });
      }
      return;
    }

    setState(() {
      _isLoadingSchedules = true;
      _scheduleError = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get(
        '/customers/calendar',
        queryParameters: {'customerId': customerId},
      );
      if (res.statusCode == null ||
          res.statusCode! < 200 ||
          res.statusCode! >= 300) {
        throw StateError('Calendar request failed (${res.statusCode})');
      }

      dynamic rawList = res.data;
      if (rawList is Map) {
        final nested = rawList['data'];
        if (nested is List) {
          rawList = nested;
        } else if (nested is Map && nested['schedules'] is List) {
          rawList = nested['schedules'];
        } else if (nested is Map && nested['items'] is List) {
          rawList = nested['items'];
        }
      }

      final activities = <CustomerCalendarActivity>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is! Map) continue;
          final activity = CustomerCalendarActivity.fromJson(
            Map<String, dynamic>.from(item),
          );
          if (activity.isValidCustomerFacingSchedule) {
            activities.add(activity);
          }
        }
      }
      activities.sort((a, b) => a.date.compareTo(b.date));

      if (mounted) {
        setState(() {
          _customerActivities = activities;
          _isLoadingSchedules = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _customerActivities = const [];
          _scheduleError = 'Failed to load this customer\'s schedules.';
          _isLoadingSchedules = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Customer Details',
          style: AppTypography.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(
              Remix.refresh_line,
              color: AppColors.primaryDark,
              size: 20,
            ),
            tooltip: 'Refresh Plan & Schedules',
            onPressed: _loadCustomerData,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCustomerData,
          color: AppColors.primaryDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Customer Basic Information Card
                _buildCustomerBasicInfoCard(c),
                const SizedBox(height: 14),

                // 2. Assigned Team Card
                if (_targetCustomerId case final customerId?)
                  _buildAssignedTeamCard(customerId)
                else
                  _buildMissingCustomerIdTeamCard(),
                const SizedBox(height: 14),

                // 3. Current Active Plan Card
                _buildCurrentActivePlanCard(),
                const SizedBox(height: 14),

                // 4. Plan Quotas & Deliverables Breakdown
                _buildPlanQuotasCard(),
                const SizedBox(height: 16),

                // 5. Customer Schedule & Deliverables
                _buildCustomerScheduleSection(_customerActivities),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 1. Customer Basic Info Card ─────────────────────────────────────────────
  Widget _buildCustomerBasicInfoCard(AdminCustomer c) {
    final initials = c.name.length >= 2
        ? c.name.substring(0, 2).toUpperCase()
        : (c.name.isNotEmpty ? c.name[0].toUpperCase() : 'C');
    final isActive = c.status == ClientStatus.active;

    return Container(
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
            offset: const Offset(0, 4),
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
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF23C45E), Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: AppTypography.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                        Expanded(
                          child: Text(
                            c.name,
                            style: AppTypography.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isActive ? 'ACTIVE' : 'INACTIVE',
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive
                                  ? const Color(0xFF16A34A)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.businessName,
                      style: AppTypography.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Contact Details
          _buildInfoRow(
            Remix.phone_line,
            c.mobile.isNotEmpty ? c.mobile : '+91 98765 43210',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Remix.mail_line,
            c.email.isNotEmpty ? c.email : 'contact@client.com',
          ),
          const SizedBox(height: 8),
          _buildInfoRow(
            Remix.map_pin_2_line,
            '${c.city.isNotEmpty ? c.city : 'Mumbai'}, ${c.state ?? 'Maharashtra'}',
          ),
        ],
      ),
    );
  }

  // ── 2. Current Active Plan Card ─────────────────────────────────────────────
  Widget _buildCurrentActivePlanCard() {
    if (_isLoadingPlan && _planInfo == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      );
    }

    if (_planInfo == null ||
        _planInfo!.status == 'NO_PLAN' ||
        _planInfo!.planName == 'No Active Plan') {
      return Container(
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
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Remix.shield_line,
                size: 18,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CURRENT ACTIVE PLAN',
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    'No Active Plan',
                    style: AppTypography.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'NO PLAN',
                style: AppTypography.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final plan = _planInfo!;

    return Container(
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Remix.vip_crown_fill,
                  size: 18,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT ACTIVE PLAN',
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    Text(
                      plan.planName,
                      style: AppTypography.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: plan.status == 'ACTIVE'
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.status,
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: plan.status == 'ACTIVE'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Plan Details Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Remix.calendar_line,
                  label: 'Start Date',
                  value: plan.startDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Remix.time_line,
                  label: 'Expiry Date',
                  value: plan.endDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  icon: Remix.repeat_line,
                  label: 'Billing Cycle',
                  value: plan.billingCycle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Plan Quotas Breakdown Card ──────────────────────────────────────────
  Widget _buildPlanQuotasCard() {
    if (_isLoadingPlan && _planInfo == null) {
      return const SizedBox.shrink();
    }

    if (_planInfo == null ||
        _planInfo!.status == 'NO_PLAN' ||
        _planInfo!.planName == 'No Active Plan' ||
        _planInfo!.quotas.isEmpty) {
      return const SizedBox.shrink();
    }

    final plan = _planInfo!;

    final totalDone = plan.totalUsed;
    final totalQuota = plan.totalLimit > 0 ? plan.totalLimit : 11;
    final progress = totalQuota > 0
        ? (totalDone / totalQuota).clamp(0.0, 1.0)
        : 0.0;

    return Container(
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
                child: Text(
                  'PLAN QUOTAS & USAGE',
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$totalDone/$totalQuota Deliverables Done',
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF22C55E),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quotas Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: plan.quotas.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemBuilder: (context, index) {
              final quota = plan.quotas[index];
              return _buildQuotaItemCard(quota);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuotaItemCard(CustomerQuotaItem quota) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(quota.icon, size: 16, color: const Color(0xFF16A34A)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  quota.serviceName,
                  style: AppTypography.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${quota.usedQty}/${quota.totalQty} Done • ${quota.remainingQty} Left',
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Customer Schedule & Deliverables Section ─────────────────────────────
  Widget _buildCustomerScheduleSection(
    List<CustomerCalendarActivity> activities,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(
                    Remix.calendar_event_fill,
                    size: 16,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'CUSTOMER SCHEDULE & DELIVERABLES',
                      style: AppTypography.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (activities.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${activities.length} Scheduled',
                  style: AppTypography.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (_isLoadingSchedules)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else if (_scheduleError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Remix.error_warning_line, color: Color(0xFFEF4444)),
                const SizedBox(height: 8),
                Text(
                  _scheduleError!,
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: _loadCustomerSchedules,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else if (activities.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Remix.calendar_check_line,
                    size: 28,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No scheduled activities found',
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scheduled deliverables will appear here as soon as they are assigned.',
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activities.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final act = activities[idx];
              return _buildScheduleItemTile(act);
            },
          ),
      ],
    );
  }

  Widget _buildScheduleItemTile(CustomerCalendarActivity act) {
    return InkWell(
      onTap: () => AdminActivityDetailSheet.show(context, act),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Text(
                    _formatDay(act.date),
                    style: AppTypography.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _formatMonth(act.date).toUpperCase(),
                    style: AppTypography.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Content Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          act.notes ?? act.activityType.label,
                          style: AppTypography.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: act.statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          act.status,
                          style: AppTypography.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: act.statusColor,
                          ),
                        ),
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
                      Text(
                        act.time,
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Remix.user_3_line,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          act.assignedEmployee,
                          style: AppTypography.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.inter(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String? get _targetCustomerId {
    for (final value in [widget.customer.customerId, widget.customer.id]) {
      final raw = value.trim();
      if (raw.isEmpty) continue;
      final numeric = int.tryParse(raw);
      if (numeric != null && numeric > 0) return numeric.toString();
      final match = RegExp(
        r'^CUST-(\d+)$',
        caseSensitive: false,
      ).firstMatch(raw);
      final prefixedId = int.tryParse(match?.group(1) ?? '');
      if (prefixedId != null && prefixedId > 0) {
        return prefixedId.toString();
      }
    }
    return null;
  }

  Widget _buildMissingCustomerIdTeamCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        'Assigned team is unavailable because this item is not linked to a customer record.',
        style: AppTypography.inter(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildAssignedTeamCard(String customerId) {
    final teamAsync = ref.watch(customerAssignedTeamProvider(customerId));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Remix.team_fill,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Assigned Team',
                    style: AppTypography.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              teamAsync.maybeWhen(
                data: (data) {
                  final team = (data?['team'] as Map<String, dynamic>?) ??
                      (data?['assignedTeam'] as Map<String, dynamic>?);
                  final teamId = (team?['id'] as num?)?.toInt() ??
                      (data?['assignedTeamId'] as num?)?.toInt();
                  return TextButton.icon(
                    onPressed: () =>
                        _showAssignTeamModal(context, customerId, teamId),
                    icon: Icon(
                      team != null ? Remix.pencil_line : Remix.add_line,
                      size: 15,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      team != null ? 'Change' : 'Assign Team',
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                },
                orElse: () => TextButton.icon(
                  onPressed: () =>
                      _showAssignTeamModal(context, customerId, null),
                  icon: const Icon(
                    Remix.add_line,
                    size: 15,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    'Assign Team',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          teamAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            error: (err, _) => Row(
              children: [
                const Icon(
                  Remix.error_warning_line,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load assigned team.',
                    style: AppTypography.inter(
                      fontSize: 13,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(customerAssignedTeamProvider(customerId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
            data: (data) {
              final team = (data?['team'] as Map<String, dynamic>?) ??
                  (data?['assignedTeam'] as Map<String, dynamic>?);
              if (team == null) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Remix.information_line,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No team currently assigned to this customer.',
                          style: AppTypography.inter(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final teamName =
                  team['name']?.toString() ?? 'Team #${team['id']}';
              final teamCode = team['code']?.toString();
              final leader = team['leader'];
              final leaderName = leader is Map
                  ? '${leader['firstName'] ?? ''} ${leader['lastName'] ?? ''}'
                        .trim()
                  : leader?.toString().trim();
              final members = team['members'] as List<dynamic>? ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                teamName,
                                style: AppTypography.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            if (teamCode != null && teamCode.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                '($teamCode)',
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              '${members.length} Member${members.length == 1 ? '' : 's'}',
                              style: AppTypography.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (leaderName != null && leaderName.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Remix.shield_user_line,
                                size: 15,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Team Leader:',
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  leaderName,
                                  style: AppTypography.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (members.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: members.take(6).map((m) {
                        final member = m is Map
                            ? Map<String, dynamic>.from(m)
                            : const <String, dynamic>{};
                        final rawName = member['name']?.toString().trim();
                        final memberName = rawName != null && rawName.isNotEmpty
                            ? rawName
                            : 'Name unavailable';
                        final designation = member['designation']
                            ?.toString()
                            .trim();
                        final label =
                            designation != null && designation.isNotEmpty
                            ? '$memberName · $designation'
                            : memberName;
                        return Chip(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          label: Text(
                            label,
                            style: AppTypography.inter(
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAssignTeamModal(
    BuildContext context,
    String customerId,
    int? currentTeamId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        int? selectedId = currentTeamId;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                          Remix.team_line,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Assign Customer to Team',
                          style: AppTypography.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Select a team to handle services and deliverables for this customer.',
                    style: AppTypography.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ref
                        .watch(availableTeamsProvider)
                        .when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Center(
                            child: Text(
                              'Failed to load teams: $e',
                              style: AppTypography.inter(
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          data: (teams) {
                            return ListView(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: selectedId == null
                                          ? AppColors.primary
                                          : const Color(0xFFE2E8F0),
                                      width: selectedId == null ? 1.5 : 1.0,
                                    ),
                                  ),
                                  tileColor: selectedId == null
                                      ? AppColors.primaryLight.withValues(
                                          alpha: 0.2,
                                        )
                                      : Colors.white,
                                  title: Text(
                                    'Unassigned (Remove Team)',
                                    style: AppTypography.inter(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'No team will be assigned',
                                    style: AppTypography.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  trailing: Icon(
                                    selectedId == null
                                        ? Remix.checkbox_circle_fill
                                        : Remix.checkbox_blank_circle_line,
                                    color: selectedId == null
                                        ? AppColors.primary
                                        : const Color(0xFFCBD5E1),
                                    size: 22,
                                  ),
                                  onTap: () =>
                                      setModalState(() => selectedId = null),
                                ),
                                const SizedBox(height: 8),
                                ...teams.map((t) {
                                  final tid = (t['id'] as num?)?.toInt();
                                  final name =
                                      t['name']?.toString() ?? 'Team #$tid';
                                  final leader =
                                      t['leader'] as Map<String, dynamic>?;
                                  final leaderName = leader != null
                                      ? '${leader['firstName'] ?? ''} ${leader['lastName'] ?? ''}'
                                            .trim()
                                      : null;
                                  final memberCount =
                                      (t['members'] as List<dynamic>?)
                                          ?.length ??
                                      0;
                                  final isSelected = selectedId == tid;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: isSelected
                                              ? AppColors.primary
                                              : const Color(0xFFE2E8F0),
                                          width: isSelected ? 1.5 : 1.0,
                                        ),
                                      ),
                                      tileColor: isSelected
                                          ? AppColors.primaryLight.withValues(
                                              alpha: 0.2,
                                            )
                                          : Colors.white,
                                      title: Text(
                                        name,
                                        style: AppTypography.inter(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Leader: ${leaderName ?? "Not specified"} • $memberCount members',
                                        style: AppTypography.inter(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      trailing: Icon(
                                        isSelected
                                            ? Remix.checkbox_circle_fill
                                            : Remix.checkbox_blank_circle_line,
                                        color: isSelected
                                            ? AppColors.primary
                                            : const Color(0xFFCBD5E1),
                                        size: 22,
                                      ),
                                      onTap: () =>
                                          setModalState(() => selectedId = tid),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);
                              try {
                                await ref
                                    .read(customerServiceProvider)
                                    .assignTeam(customerId, selectedId);
                                ref.invalidate(
                                  customerAssignedTeamProvider(customerId),
                                );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                }
                                if (context.mounted) {
                                  AppToast.success(
                                    context,
                                    selectedId == null
                                        ? 'Team unassigned successfully.'
                                        : 'Customer assigned to team successfully.',
                                    title: 'Team Updated',
                                  );
                                }
                              } catch (err) {
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  AppToast.error(
                                    context,
                                    'Failed to assign team: $err',
                                    title: 'Assignment Failed',
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'CONFIRM ASSIGNMENT',
                              style: AppTypography.inter(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
