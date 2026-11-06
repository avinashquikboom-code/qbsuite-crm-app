import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';
import 'package:quickboom_app/roles/company_admin/widgets/admin_filter_sheet.dart';
import '../work/admin_work_detail_view.dart';

class AdminCalendarTab extends ConsumerStatefulWidget {
  const AdminCalendarTab({super.key});

  @override
  ConsumerState<AdminCalendarTab> createState() => _AdminCalendarTabState();
}

class _AdminCalendarTabState extends ConsumerState<AdminCalendarTab> {
  DateTime _selectedDate = DateTime.now();

  String _teamFilter = 'All Teams';
  String _employeeFilter = 'All Employees';
  String _workTypeFilter = 'All Types';

  final List<String> _teamOptions = ['All Teams', 'SSM Team A', 'SSM Team B'];
  final List<String> _employeeOptions = [
    'All Employees',
    'Demo User',
    'Amit',
    'Rahul',
    'Sneha',
    'Priya',
    'Neha',
  ];
  final List<String> _workTypeOptions = ['All Types', 'Reel', 'Shoot', 'Post'];

  void _openFilter(
    String title,
    List<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminFilterSheet(
        title: title,
        options: options,
        selectedOption: selected,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyAdminProvider);

    // Filter work items for calendar
    final scheduledItems = state.workList.where((w) {
      if (_teamFilter != 'All Teams' && w.team != _teamFilter) return false;
      if (_employeeFilter != 'All Employees' &&
          w.assignedEmployee != _employeeFilter) {
        return false;
      }
      if (_workTypeFilter != 'All Types' &&
          w.workType.label != _workTypeFilter) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Calendar Header & Compact Date Strip
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Month Navigator Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Team Calendar',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${_getMonthName(_selectedDate.month)} ${_selectedDate.year}',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Remix.arrow_left_s_line, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.subtract(
                                  const Duration(days: 7),
                                );
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              setState(() => _selectedDate = DateTime.now());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Today',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Remix.arrow_right_s_line,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedDate = _selectedDate.add(
                                  const Duration(days: 7),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Compact 7-Day Week Strip
                  _buildWeekStrip(),
                  const SizedBox(height: 12),

                  // Multi-Filter Horizontal Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterButton('Team: $_teamFilter', () {
                          _openFilter(
                            'Filter by Team',
                            _teamOptions,
                            _teamFilter,
                            (val) {
                              setState(() => _teamFilter = val);
                            },
                          );
                        }, _teamFilter != 'All Teams'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Staff: $_employeeFilter', () {
                          _openFilter(
                            'Filter by Staff',
                            _employeeOptions,
                            _employeeFilter,
                            (val) {
                              setState(() => _employeeFilter = val);
                            },
                          );
                        }, _employeeFilter != 'All Employees'),
                        const SizedBox(width: 8),
                        _buildFilterButton('Type: $_workTypeFilter', () {
                          _openFilter(
                            'Filter by Work Type',
                            _workTypeOptions,
                            _workTypeFilter,
                            (val) {
                              setState(() => _workTypeFilter = val);
                            },
                          );
                        }, _workTypeFilter != 'All Types'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Schedule Items for Selected Date
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Schedule for ${_selectedDate.day} ${_getMonthName(_selectedDate.month)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${scheduledItems.length} active',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: scheduledItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Remix.calendar_todo_line,
                            size: 44,
                            color: Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No scheduled tasks on this day',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Select another date or reset filters',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: scheduledItems.length,
                      itemBuilder: (context, index) {
                        final item = scheduledItems[index];
                        return _buildCalendarWorkCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekStrip() {
    // Generate 7 days around selected date
    final startOfWeek = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        final isSelected =
            d.year == _selectedDate.year &&
            d.month == _selectedDate.month &&
            d.day == _selectedDate.day;
        final isToday =
            d.year == DateTime.now().year &&
            d.month == DateTime.now().month &&
            d.day == DateTime.now().day;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => setState(() => _selectedDate = d),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isToday
                            ? AppColors.primaryLight
                            : const Color(0xFFF8FAFC)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isToday
                              ? AppColors.primary
                              : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      weekDays[d.weekday - 1],
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${d.day}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : (isToday
                                  ? AppColors.primary
                                  : AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFilterButton(String label, VoidCallback onTap, bool isActive) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Remix.arrow_down_s_line,
              size: 14,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarWorkCard(AdminSSMWork w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminWorkDetailView(work: w)),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _getWorkTypeColor(
                          w.workType,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        w.workType.label.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getWorkTypeColor(w.workType),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        w.customerName,
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
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
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: w.status.color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Task: ${w.todayTask}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildMetaRow(Remix.team_line, w.team)),
                    Expanded(
                      child: _buildMetaRow(
                        Remix.user_3_line,
                        w.assignedEmployee,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
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

  String _getMonthName(int month) {
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
}
