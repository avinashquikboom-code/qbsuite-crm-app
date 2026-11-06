import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';
import 'admin_create_work_sheet.dart';
import 'admin_work_detail_view.dart';

class AdminWorkTab extends ConsumerStatefulWidget {
  const AdminWorkTab({super.key});

  @override
  ConsumerState<AdminWorkTab> createState() => _AdminWorkTabState();
}

class _AdminWorkTabState extends ConsumerState<AdminWorkTab> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Reels',
    'Shoots',
    'Posts',
    'In Progress',
    'Scheduled',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateWorkSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminCreateWorkSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyAdminProvider);
    final query = _searchController.text.trim().toLowerCase();

    final filteredWork = state.workList.where((w) {
      if (_selectedFilter == 'Reels' && w.workType != WorkType.reel) {
        return false;
      }
      if (_selectedFilter == 'Shoots' && w.workType != WorkType.shoot) {
        return false;
      }
      if (_selectedFilter == 'Posts' && w.workType != WorkType.post) {
        return false;
      }
      if (_selectedFilter == 'In Progress' &&
          w.status != WorkStatus.inProgress) {
        return false;
      }
      if (_selectedFilter == 'Scheduled' && w.status != WorkStatus.scheduled) {
        return false;
      }

      if (query.isNotEmpty) {
        final matchCust = w.customerName.toLowerCase().contains(query);
        final matchSocial = w.socialAccount.toLowerCase().contains(query);
        final matchEmp = w.assignedEmployee.toLowerCase().contains(query);
        final matchTeam = w.team.toLowerCase().contains(query);
        if (!matchCust && !matchSocial && !matchEmp && !matchTeam) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Search & Work Category Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() {}),
                            style: AppTypography.inter(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Search SSM Work, customer, staff...',
                              hintStyle: AppTypography.inter(
                                fontSize: 13,
                                color: const Color(0xFF94A3B8),
                              ),
                              prefixIcon: const Icon(
                                Remix.search_2_line,
                                size: 18,
                                color: Color(0xFF94A3B8),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(
                                        Remix.close_circle_fill,
                                        size: 16,
                                        color: Color(0xFF94A3B8),
                                      ),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _openCreateWorkSheet,
                        icon: const Icon(Remix.add_line, size: 16),
                        label: Text(
                          'New Work',
                          style: AppTypography.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          minimumSize: const Size(60, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: _filters.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (val) =>
                                setState(() => _selectedFilter = filter),
                            backgroundColor: const Color(0xFFF1F5F9),
                            selectedColor: AppColors.primaryLight,
                            labelStyle: AppTypography.inter(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFE2E8F0),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Work List
            Expanded(
              child: filteredWork.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Remix.clapperboard_line,
                            size: 48,
                            color: const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No SSM Work found',
                            style: AppTypography.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Schedule work using the "New Work" button above',
                            style: AppTypography.inter(
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
                      itemCount: filteredWork.length,
                      itemBuilder: (context, index) {
                        final work = filteredWork[index];
                        return _buildWorkCard(work);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkCard(AdminSSMWork w) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _getWorkTypeColor(
                          w.workType,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getWorkTypeIcon(w.workType),
                        color: _getWorkTypeColor(w.workType),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  w.customerName,
                                  style: AppTypography.inter(
                                    fontSize: 15,
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
                                  style: AppTypography.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: w.status.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${w.socialAccount} • ${w.platform}',
                            style: AppTypography.inter(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 10),

                // Details Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaItem(
                        'Type',
                        w.workType.label,
                        Remix.clapperboard_line,
                      ),
                    ),
                    Expanded(
                      child: _buildMetaItem('Team', w.team, Remix.team_line),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaItem(
                        'Staff',
                        w.assignedEmployee,
                        Remix.user_3_line,
                      ),
                    ),
                    Expanded(
                      child: _buildMetaItem(
                        'Duration',
                        '${w.durationDays} Day${w.durationDays > 1 ? 's' : ''} (Day ${w.currentDay})',
                        Remix.time_line,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaItem(
                        'Timeline',
                        '${w.startDate.day}/${w.startDate.month} - ${w.endDate.day}/${w.endDate.month}',
                        Remix.calendar_event_line,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFFCBD5E1),
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

  Widget _buildMetaItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: AppTypography.inter(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
              children: [
                TextSpan(text: '$label: '),
                TextSpan(
                  text: value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
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

  IconData _getWorkTypeIcon(WorkType type) {
    switch (type) {
      case WorkType.reel:
        return Remix.film_line;
      case WorkType.shoot:
        return Remix.camera_3_line;
      case WorkType.post:
        return Remix.image_2_line;
    }
  }
}
