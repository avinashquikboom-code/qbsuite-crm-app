import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/shared/widgets/permission_guarded_view.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/customer/viewmodels/current_customer_viewmodel.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';
import '../clients/admin_client_detail_view.dart';
import 'package:quickboom_app/roles/company_admin/widgets/admin_quick_action_sheet.dart';
import 'widgets/admin_activity_detail_sheet.dart';
import 'package:quickboom_app/roles/customer/widgets/calendar_activity_legend.dart';
import 'package:quickboom_app/roles/customer/viewmodels/customer_subscription_viewmodel.dart';

class AdminCustomerCalendarView extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final bool isCustomerScope;
  final String? customerName;
  final String? customerId;

  const AdminCustomerCalendarView({
    super.key,
    this.initialDate,
    this.isCustomerScope = false,
    this.customerName,
    this.customerId,
  });

  @override
  ConsumerState<AdminCustomerCalendarView> createState() =>
      _AdminCustomerCalendarViewState();
}

class _AdminCustomerCalendarViewState
    extends ConsumerState<AdminCustomerCalendarView> {
  late DateTime _selectedDate;
  late DateTime _displayedMonth;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selectedDate = widget.initialDate ?? today;
    _displayedMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  static String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCustomerScope) {
      final perms = ref.watch(permissionManagerProvider);
      if (!perms.customerCan('CUSTOMER_CALENDAR', 'VIEW')) {
        return const PermissionGuardedView(
          moduleKey: 'CUSTOMER_CALENDAR',
          moduleTitle: 'Customer Calendar',
          child: SizedBox.shrink(),
        );
      }
    }

    final fullState = ref.watch(companyAdminProvider);
    final customerIdAsync = ref.watch(currentCustomerIdProvider);
    final activeCustomerId = widget.customerId ?? customerIdAsync.value;

    // In customer scope, state is strictly scoped to the active customer.
    // If activeCustomerId is null/empty, forCustomer returns empty state (never global fallback).
    final state = widget.isCustomerScope
        ? fullState.forCustomer(activeCustomerId)
        : fullState;

    final List<CustomerCalendarActivity> allScopedActivities =
        widget.isCustomerScope
        ? state.allCustomerActivities
        : fullState.allCustomerActivities;

    final search = _searchCtrl.text.trim().toLowerCase();

    final selectedDateStr = normalizeDate(_selectedDate);
    final liveDateActivitiesAsync = widget.isCustomerScope
        ? ref.watch(customerCalendarActivitiesForDateProvider(selectedDateStr))
        : null;

    final displayedMonthStr =
        '${_displayedMonth.year.toString().padLeft(4, '0')}-${_displayedMonth.month.toString().padLeft(2, '0')}';
    final liveMonthActivitiesAsync = widget.isCustomerScope
        ? ref.watch(
            customerCalendarActivitiesForMonthProvider(displayedMonthStr),
          )
        : null;

    final customerScheduledDates = widget.isCustomerScope
        ? ref.watch(
            customerCalendarScheduledDatesForMonthProvider(displayedMonthStr),
          )
        : null;

    final liveActivities = liveDateActivitiesAsync?.asData?.value;
    final liveMonthActivities =
        liveMonthActivitiesAsync?.asData?.value ??
        const <CustomerCalendarActivity>[];

    final Map<String, CustomerCalendarActivity> allActivitiesMap = {};

    if (widget.isCustomerScope) {
      // In customer scope, activities come EXCLUSIVELY from live backend API responses
      for (final a in liveMonthActivities) {
        if (a.isValidCustomerFacingSchedule) {
          final key = a.id.isNotEmpty
              ? a.id
              : '${getScheduledDateString(a)}_${a.title}_${a.time}';
          allActivitiesMap[key] = a;
        }
      }
      if (liveActivities != null) {
        for (final a in liveActivities) {
          if (a.isValidCustomerFacingSchedule) {
            final key = a.id.isNotEmpty
                ? a.id
                : '${getScheduledDateString(a)}_${a.title}_${a.time}';
            allActivitiesMap[key] = a;
          }
        }
      }
    } else {
      // Admin global scope
      for (final a in allScopedActivities) {
        final key = a.id.isNotEmpty
            ? a.id
            : '${getScheduledDateString(a)}_${a.title}_${a.time}';
        allActivitiesMap[key] = a;
      }
    }

    final currentSubAsync = ref.watch(currentSubscriptionProvider);
    final currentSub = currentSubAsync.asData?.value;
    final hasActiveSub = currentSub != null && currentSub.isActive;
    final hasLiveActivities = allActivitiesMap.isNotEmpty;

    final isExplicitlyInactive = currentSub != null && !currentSub.isActive;
    final hasActivePlan =
        !isExplicitlyInactive && (hasActiveSub || hasLiveActivities);

    // Strict Active Plan Rule:
    // If customer has NO active plan, calendar must have 0 schedules and no dots.
    if (widget.isCustomerScope && !hasActivePlan) {
      allActivitiesMap.clear();
    }

    final Map<String, List<CustomerCalendarActivity>> dateActivityMap = {};
    for (final a in allActivitiesMap.values) {
      final key = getScheduledDateString(a);
      dateActivityMap.putIfAbsent(key, () => []).add(a);
    }

    // Exact selected-date matching:
    final List<CustomerCalendarActivity> rawDateActivities;
    if (widget.isCustomerScope && liveActivities != null) {
      rawDateActivities = liveActivities
          .where((a) => a.isValidCustomerFacingSchedule)
          .toList();
    } else {
      rawDateActivities =
          (dateActivityMap[selectedDateStr] ??
                  const <CustomerCalendarActivity>[])
              .where(
                (a) =>
                    !widget.isCustomerScope || a.isValidCustomerFacingSchedule,
              )
              .toList();
    }

    // Frontend Deduplication Safety Layer
    final dateActivities = deduplicateCustomerActivities(rawDateActivities);

    final filteredActivities = dateActivities.where((a) {
      if (search.isNotEmpty) {
        final matchesSearch =
            a.customerName.toLowerCase().contains(search) ||
            a.businessName.toLowerCase().contains(search) ||
            a.activityType.label.toLowerCase().contains(search) ||
            a.assignedEmployee.toLowerCase().contains(search);
        if (!matchesSearch) return false;
      }

      return true;
    }).toList();

    debugPrint('Selected Date: $selectedDateStr');
    for (final a in allActivitiesMap.values) {
      debugPrint(
        'Activity Date: ${getScheduledDateString(a)} | Title: ${a.title ?? a.notes}',
      );
    }
    debugPrint('Matched Activities: ${dateActivities.length}');

    final selectedNormalized = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    for (final a in allActivitiesMap.values) {
      final aNorm = DateTime(a.date.year, a.date.month, a.date.day);
      final normActDateStr =
          '${aNorm.year.toString().padLeft(4, '0')}-${aNorm.month.toString().padLeft(2, '0')}-${aNorm.day.toString().padLeft(2, '0')}';
      final isMatch = aNorm.isAtSameMomentAs(selectedNormalized);
      final taskCategory = resolveTaskCategory(a);
      final taskColor = resolveTaskColor(a);

      debugPrint('[ CUSTOMER_CALENDAR_DEBUG ]');
      debugPrint('id: ${a.id}');
      debugPrint('title: ${a.title ?? a.notes}');
      debugPrint('type: ${a.type}');
      debugPrint('serviceName: ${a.serviceName ?? "null"}');
      debugPrint('productName: ${a.productName ?? "null"}');
      debugPrint('apiDate: ${a.date.toIso8601String()}');
      debugPrint('normalizedDate: $normActDateStr');
      debugPrint('selectedDate: $selectedDateStr');
      debugPrint('matched: $isMatch');
      debugPrint('taskCategory: ${taskCategory.key}');
      debugPrint('taskColor: $taskColor');

      debugPrint('[CALENDAR_DATE_MATCH]');
      debugPrint('activityId: ${a.id}');
      debugPrint('activityDate: ${a.date.toIso8601String()}');
      debugPrint('normalizedActivityDate: $normActDateStr');
      debugPrint('selectedDate: $selectedDateStr');
      debugPrint('isMatch: $isMatch');
    }

    if (widget.isCustomerScope) {
      debugPrint('[DATA SCOPE]');
      debugPrint('Current Customer ID: ${activeCustomerId ?? "NONE"}');
      debugPrint('[CALENDAR]');
      debugPrint('Total Events: ${fullState.allCustomerActivities.length}');
      debugPrint('Customer Events: ${allScopedActivities.length}');
      debugPrint('Selected Date Events: ${filteredActivities.length}');
    }

    final daysInMonth = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final firstDayOffset =
        DateTime(_displayedMonth.year, _displayedMonth.month, 1).weekday - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          widget.isCustomerScope ? 'Customer Calendar' : 'Customer Calendar',
          style: AppTypography.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: const BackButton(color: AppColors.textPrimary),
        actions: [
          if (!widget.isCustomerScope)
            IconButton(
              icon: const Icon(Remix.add_circle_line, color: AppColors.primary),
              tooltip: 'Schedule Activity',
              onPressed: () => AdminQuickActionSheet.show(context),
            )
          else
            IconButton(
              icon: const Icon(Remix.add_circle_line, color: AppColors.primary),
              tooltip: 'Create Schedule',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Scheduling is active',
                      style: AppTypography.inter(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Scope Plan Quota Card
              if (widget.isCustomerScope) ...[
                Builder(
                  builder: (context) {
                    final totalWork = state.workList.length;
                    final completedWork = state.workList
                        .where((w) => w.status == WorkStatus.completed)
                        .length;
                    final remainingWork = totalWork > completedWork
                        ? totalWork - completedWork
                        : 0;
                    final planName = state.packages.isNotEmpty
                        ? state.packages.first.name
                        : 'Standard Package';

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryDark.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Remix.vip_crown_fill,
                                          size: 13,
                                          color: AppColors.primaryDark,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          planName,
                                          style: AppTypography.inter(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$remainingWork Remaining',
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: remainingWork > 0
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$completedWork / $totalWork Schedules Used',
                            style: AppTypography.inter(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: totalWork > 0
                                  ? (completedWork / totalWork).clamp(0.0, 1.0)
                                  : 0.0,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                remainingWork > 0
                                    ? AppColors.primary
                                    : const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
              // Search & Filter Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search customer, activity, staff…',
                    hintStyle: AppTypography.inter(
                      color: const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Remix.search_2_line,
                      color: Color(0xFF94A3B8),
                      size: 18,
                    ),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Remix.close_circle_line,
                              size: 18,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Month Calendar Card
              Container(
                padding: const EdgeInsets.all(12),
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
                  children: [
                    // Month Navigator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              _displayedMonth = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month - 1,
                                1,
                              );
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Remix.arrow_left_s_line,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${_getMonthName(_displayedMonth.month)} ${_displayedMonth.year}',
                          style: AppTypography.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _displayedMonth = DateTime(
                                _displayedMonth.year,
                                _displayedMonth.month + 1,
                                1,
                              );
                            });
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Remix.arrow_right_s_line,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 10),

                    // Weekday Header
                    Row(
                      children:
                          ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map(
                            (day) {
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: AppTypography.inter(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                    ),

                    const SizedBox(height: 8),

                    // Month Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: daysInMonth + firstDayOffset,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            childAspectRatio: 0.95,
                          ),
                      itemBuilder: (context, index) {
                        if (index < firstDayOffset) {
                          return const SizedBox();
                        }
                        final dayNum = index - firstDayOffset + 1;
                        final date = DateTime(
                          _displayedMonth.year,
                          _displayedMonth.month,
                          dayNum,
                        );

                        final isSelected =
                            date.year == _selectedDate.year &&
                            date.month == _selectedDate.month &&
                            date.day == _selectedDate.day;

                        final now = DateTime.now();
                        final isToday =
                            date.year == now.year &&
                            date.month == now.month &&
                            date.day == now.day;
                        final normalizedDate = DateTime(
                          date.year,
                          date.month,
                          date.day,
                        );
                        final dateKey = normalizeDate(date);
                        final matchingActivities =
                            dateActivityMap[dateKey] ??
                            const <CustomerCalendarActivity>[];

                        // Extract unique activity category colors for this date (up to 3 + overflow indicator)
                        final uniqueColors = <Color>[];
                        final seenCategories = <TaskCategory>{};
                        for (final act in matchingActivities) {
                          final cat = resolveTaskCategory(act);
                          if (seenCategories.add(cat)) {
                            uniqueColors.add(resolveTaskColor(act));
                          }
                        }
                        final int extraCount = uniqueColors.length > 3
                            ? uniqueColors.length - 3
                            : 0;
                        final displayedColors = uniqueColors.take(3).toList();

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedDate = date;
                            });
                            if (widget.isCustomerScope) {
                              ref
                                  .read(
                                    customerCalendarSelectedDateProvider
                                        .notifier,
                                  )
                                  .setDate(date);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isToday
                                          ? AppColors.primary.withValues(
                                              alpha: 0.5,
                                            )
                                          : Colors.transparent),
                                width: isToday && !isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$dayNum',
                                  style: AppTypography.inter(
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : (isToday
                                              ? FontWeight.w600
                                              : FontWeight.w500),
                                    color: isSelected
                                        ? Colors.white
                                        : (isToday
                                              ? AppColors.primaryDark
                                              : AppColors.textPrimary),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                if (displayedColors.isNotEmpty)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ...displayedColors.map((color) {
                                        return Container(
                                          width: 4,
                                          height: 4,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color,
                                            shape: BoxShape.circle,
                                            border: isSelected
                                                ? Border.all(
                                                    color: Colors.white,
                                                    width: 0.5,
                                                  )
                                                : null,
                                          ),
                                        );
                                      }),
                                      if (extraCount > 0)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 1,
                                          ),
                                          child: Text(
                                            '+$extraCount',
                                            style: TextStyle(
                                              fontSize: 7,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                else if (widget.isCustomerScope &&
                                    (customerScheduledDates?.contains(
                                          normalizedDate,
                                        ) ??
                                        false))
                                  Container(
                                    width: 4.5,
                                    height: 4.5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                      border: isSelected
                                          ? Border.all(
                                              color: Colors.white,
                                              width: 0.5,
                                            )
                                          : null,
                                    ),
                                  )
                                else
                                  const SizedBox(height: 5),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Activity Color Legend
              CalendarActivityLegend(
                activities: widget.isCustomerScope
                    ? allActivitiesMap.values.toList()
                    : allScopedActivities,
              ),

              const SizedBox(height: 14),

              // Selected Date Title & Banner
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedDate.day} ${_getMonthName(_selectedDate.month).toUpperCase()} ${_selectedDate.year}',
                      style: AppTypography.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if ((_selectedDate.year == DateTime.now().year &&
                          _selectedDate.month == DateTime.now().month &&
                          _selectedDate.day == DateTime.now().day) ||
                      (_selectedDate.year == 2026 &&
                          _selectedDate.month == 8 &&
                          _selectedDate.day == 20))
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'TODAY',
                        style: AppTypography.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Activity Cards List
              if (widget.isCustomerScope &&
                  (liveDateActivitiesAsync?.isLoading ?? false) &&
                  filteredActivities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Loading activities...',
                        style: AppTypography.inter(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else if (widget.isCustomerScope &&
                  (liveDateActivitiesAsync?.hasError ?? false) &&
                  filteredActivities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Remix.error_warning_line,
                        size: 32,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Unable to load customer activities. Please try again.',
                        style: AppTypography.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextButton(
                        onPressed: () => ref.refresh(
                          customerCalendarActivitiesForDateProvider(
                            selectedDateStr,
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: AppTypography.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (filteredActivities.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Remix.calendar_check_line,
                        size: 40,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No customer activities scheduled for this date.',
                        style: AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can enjoy a clear schedule today.',
                        style: AppTypography.inter(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredActivities.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final activity = filteredActivities[index];
                    return _buildActivityCard(context, activity, state);
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(
    BuildContext context,
    CustomerCalendarActivity activity,
    CompanyAdminState state,
  ) {
    final actCustId = activity.customerId.trim();
    final matchingCustomers = actCustId.isNotEmpty
        ? state.customers
            .where((c) => c.customerId == actCustId || c.id == actCustId)
            .toList()
        : <AdminCustomer>[];
    final matchingCustomer = matchingCustomers.isNotEmpty
        ? matchingCustomers.first
        : (actCustId.isNotEmpty
            ? AdminCustomer(
                id: actCustId,
                customerId: actCustId,
                name: activity.customerName,
                businessName: activity.businessName,
                mobile: '',
                email: '',
                city: '',
                assignedEmployee: activity.assignedEmployee,
                assignedTeam: activity.team ?? '',
                activeWork: resolveTaskCategory(activity).label,
                status: ClientStatus.active,
                customerSince: '',
                nextFollowUp: '',
              )
            : null);

    final category = resolveTaskCategory(activity);
    final taskColor = resolveTaskColor(activity);
    final selectedDateStr =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final actDateNormalized =
        '${activity.date.year.toString().padLeft(4, '0')}-${activity.date.month.toString().padLeft(2, '0')}-${activity.date.day.toString().padLeft(2, '0')}';

    debugPrint(
      '[CalendarActivity] Activity: ${resolveActivityDisplayName(activity)} | Purchase: ${activity.purchaseId ?? "N/A"}',
    );
    debugPrint('[CUSTOMER_TASK_RENDER]');
    debugPrint('id: ${activity.id}');
    debugPrint('title: ${activity.title ?? activity.notes}');
    debugPrint('type: ${activity.type}');
    debugPrint('date: $actDateNormalized');
    debugPrint('selectedDate: $selectedDateStr');
    debugPrint('matched: true');
    debugPrint('category: ${category.key}');
    debugPrint('color: $taskColor');

    return Material(
      key: ValueKey(
        'admin_cal_act_${activity.id.isNotEmpty ? activity.id : "${actDateNormalized}_${activity.title}"}',
      ),
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => AdminActivityDetailSheet.show(context, activity),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Activity Type Badge + Status
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: resolveTaskBgColor(activity),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              resolveTaskCategory(activity).icon,
                              size: 12,
                              color: resolveTaskColor(activity),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                resolveTaskCategory(activity).label,
                                style: AppTypography.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: resolveTaskColor(activity),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: activity.statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      activity.status,
                      style: AppTypography.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: activity.statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Customer Name or Activity Title (Tappable) & Business / Purchase details
              InkWell(
                onTap: () {
                  if (!widget.isCustomerScope && matchingCustomer != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminClientDetailView(customer: matchingCustomer),
                      ),
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.isCustomerScope
                          ? resolveActivityDisplayName(activity)
                          : activity.customerName,
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!widget.isCustomerScope &&
                        activity.businessName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        activity.businessName,
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 10),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Bottom Row: Time + Staff & Team
              Row(
                children: [
                  const Icon(
                    Remix.time_line,
                    size: 12,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activity.time.isEmpty ? 'Time not set' : activity.time,
                    style: AppTypography.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Remix.user_3_line,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            calendarAssigneeLabel(activity),
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
