import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';

class AdminCreateWorkSheet extends ConsumerStatefulWidget {
  final String? initialCustomerName;

  const AdminCreateWorkSheet({super.key, this.initialCustomerName});

  @override
  ConsumerState<AdminCreateWorkSheet> createState() =>
      _AdminCreateWorkSheetState();
}

class _AdminCreateWorkSheetState extends ConsumerState<AdminCreateWorkSheet> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomer;
  final _socialAccountController = TextEditingController(
    text: '@carefitness_official',
  );
  String _selectedPlatform = 'Instagram';
  WorkType _selectedWorkType = WorkType.reel;
  DateTime _startDate = DateTime.now();
  int _durationDays = 3;
  late DateTime _endDate;

  String _selectedTeam = 'SSM Team A';
  String _selectedEmployee = 'Demo User';
  String _selectedPriority = 'High';
  final _notesController = TextEditingController();

  final List<String> _platforms = [
    'Instagram',
    'Facebook',
    'YouTube',
    'LinkedIn',
    'Multi-Platform',
  ];
  final List<String> _priorities = ['High', 'Medium', 'Low'];

  @override
  void initState() {
    super.initState();
    _durationDays = _selectedWorkType.defaultDurationDays;
    _endDate = _startDate.add(Duration(days: _durationDays - 1));
  }

  @override
  void dispose() {
    _socialAccountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onWorkTypeChanged(WorkType type) {
    setState(() {
      _selectedWorkType = type;
      _durationDays = type.defaultDurationDays;
      _endDate = _startDate.add(Duration(days: _durationDays - 1));
    });
  }

  void _onStartDatePicked() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _endDate = _startDate.add(Duration(days: _durationDays - 1));
      });
    }
  }

  List<String> _getTeamMembers(String team) {
    if (team == 'SSM Team A') {
      return ['Demo User', 'Rahul', 'Sneha'];
    } else {
      return ['Amit', 'Priya', 'Neha'];
    }
  }

  List<DayTask> _generateDefaultTasks(WorkType type) {
    switch (type) {
      case WorkType.reel:
        return [
          DayTask(
            day: 1,
            title: 'Shoot / Content Capture',
            description:
                'Capture video footage, hooks, b-roll and testimonials',
            isCompleted: false,
            isCurrent: true,
          ),
          DayTask(
            day: 2,
            title: 'Editing / Production',
            description:
                'Cut footage, music sync, motion captions & color grading',
            isCompleted: false,
          ),
          DayTask(
            day: 3,
            title: 'Final Review / Submission',
            description: 'Client review, revisions and scheduling upload',
            isCompleted: false,
          ),
        ];
      case WorkType.shoot:
        return [
          DayTask(
            day: 1,
            title: 'Location / Preparation',
            description: 'Equipment prep, lighting inspection, script review',
            isCompleted: false,
            isCurrent: true,
          ),
          DayTask(
            day: 2,
            title: 'Shooting',
            description: 'Full day shoot for menu, products & staff',
            isCompleted: false,
          ),
          DayTask(
            day: 3,
            title: 'Remaining Shots / Backup',
            description: 'Drone footage, B-roll fill-in & raw asset backup',
            isCompleted: false,
          ),
        ];
      case WorkType.post:
        return [
          DayTask(
            day: 1,
            title: 'Post Creation / Publishing',
            description:
                'Graphic design carousel, caption copy & peak hour publishing',
            isCompleted: false,
            isCurrent: true,
          ),
        ];
    }
  }

  void _handleScheduleWork() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final custName = _selectedCustomer ?? 'Care Fitness Gym';
    final teamMembers = _getTeamMembers(_selectedTeam);
    final tasks = _generateDefaultTasks(_selectedWorkType);

    final newWork = AdminSSMWork(
      id: 'WRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      customerName: custName,
      socialAccount: _socialAccountController.text.trim().isNotEmpty
          ? _socialAccountController.text.trim()
          : '@$custName',
      platform: _selectedPlatform,
      workType: _selectedWorkType,
      team: _selectedTeam,
      teamMembers: teamMembers,
      assignedEmployee: _selectedEmployee,
      startDate: _startDate,
      endDate: _endDate,
      durationDays: _durationDays,
      currentDay: 1,
      todayTask: tasks.first.title,
      allTasks: tasks,
      status: WorkStatus.scheduled,
      priority: _selectedPriority,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    // Save to local reactive state (NO API CALL)
    ref.read(companyAdminProvider.notifier).addWork(newWork);

    AppToast.success(
      context,
      'Work scheduled successfully for "$custName" (${_selectedWorkType.label}).',
      title: 'SSM Work Created',
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyAdminProvider);
    final customerNames = state.customers.map((c) => c.name).toSet().toList();

    if (_selectedCustomer == null && customerNames.isNotEmpty) {
      _selectedCustomer = widget.initialCustomerName ?? customerNames.first;
    }

    final teamMembers = _getTeamMembers(_selectedTeam);
    if (!teamMembers.contains(_selectedEmployee)) {
      _selectedEmployee = teamMembers.first;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3E8FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Remix.clapperboard_fill,
                        color: Color(0xFF9333EA),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create SSM Work',
                            style: AppTypography.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Schedule Reel, Shoot, or Post workflow',
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Remix.close_line,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Scrollable Form Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Selector
                    _buildLabel('Select Customer *'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedCustomer,
                      style: AppTypography.inter(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _inputDecoration(
                        'Select Client',
                        Remix.building_2_line,
                      ),
                      items: customerNames.map((name) {
                        return DropdownMenuItem(
                          value: name,
                          child: Text(name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCustomer = val;
                            _socialAccountController.text =
                                '@${val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '')}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Social Account & Platform
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Social Media Account *'),
                              TextFormField(
                                controller: _socialAccountController,
                                style: AppTypography.inter(fontSize: 14),
                                decoration: _inputDecoration(
                                  '@handle',
                                  Remix.at_line,
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'Account handle is required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Platform *'),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedPlatform,
                                style: AppTypography.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _inputDecoration(
                                  'Platform',
                                  Remix.instagram_line,
                                ),
                                items: _platforms
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          p,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedPlatform = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Work Type Selector (Reel, Post, Shoot)
                    _buildLabel('Work Type * (Auto Defaults Duration)'),
                    Row(
                      children: WorkType.values.map((type) {
                        final isSelected = _selectedWorkType == type;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: InkWell(
                              onTap: () => _onWorkTypeChanged(type),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryLight
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primary
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      type == WorkType.reel
                                          ? Remix.film_line
                                          : (type == WorkType.shoot
                                                ? Remix.camera_3_line
                                                : Remix.image_2_line),
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      type.label,
                                      style: AppTypography.inter(
                                        fontSize: 13,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '${type.defaultDurationDays} Day${type.defaultDurationDays > 1 ? 's' : ''}',
                                      style: AppTypography.inter(
                                        fontSize: 10.5,
                                        color: isSelected
                                            ? AppColors.primary
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Dates & Duration Display
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Date',
                                    style: AppTypography.inter(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  InkWell(
                                    onTap: _onStartDatePicked,
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Remix.calendar_2_line,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${_startDate.day} ${_getMonthName(_startDate.month)} ${_startDate.year}',
                                          style: AppTypography.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_durationDays Days Plan',
                                  style: AppTypography.inter(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Calculated End Date',
                                    style: AppTypography.inter(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_endDate.day} ${_getMonthName(_endDate.month)} ${_endDate.year}',
                                    style: AppTypography.inter(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Team Selection & Dynamic Employee Assignment
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('SSM Team *'),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedTeam,
                                style: AppTypography.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _inputDecoration(
                                  'Team',
                                  Remix.team_line,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'SSM Team A',
                                    child: Text(
                                      'SSM Team A',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'SSM Team B',
                                    child: Text(
                                      'SSM Team B',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedTeam = val;
                                      final newMembers = _getTeamMembers(val);
                                      _selectedEmployee = newMembers.first;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Lead Staff *'),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                key: ValueKey(
                                  '$_selectedTeam-$_selectedEmployee',
                                ),
                                initialValue: _selectedEmployee,
                                style: AppTypography.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _inputDecoration(
                                  'Staff',
                                  Remix.user_3_line,
                                ),
                                items: teamMembers
                                    .map(
                                      (m) => DropdownMenuItem(
                                        value: m,
                                        child: Text(
                                          m,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedEmployee = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Team Members Preview Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Remix.group_line,
                            size: 14,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_selectedTeam Members: ${teamMembers.join(', ')}',
                            style: AppTypography.inter(
                              fontSize: 11.5,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Priority & Notes
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Priority'),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedPriority,
                                style: AppTypography.inter(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _inputDecoration(
                                  'Priority',
                                  Remix.flag_2_line,
                                ),
                                items: _priorities
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedPriority = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Notes / Creative Brief'),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: AppTypography.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'Add campaign goal, hashtags, reference reel link...',
                        hintStyle: AppTypography.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleScheduleWork,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Schedule Work',
                          style: AppTypography.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: AppTypography.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.inter(
        fontSize: 13,
        color: const Color(0xFF94A3B8),
      ),
      prefixIcon: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  String _getMonthName(int month) {
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
    return months[month - 1];
  }
}
