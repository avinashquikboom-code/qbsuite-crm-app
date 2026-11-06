import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';

import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/shared/models/lead_model.dart';
import 'package:quickboom_app/shared/viewmodels/lead_stages_viewmodel.dart';
import 'package:quickboom_app/shared/viewmodels/leads_viewmodel.dart';
import 'package:quickboom_app/shared/widgets/app_app_bar.dart';
import 'lead_details_view.dart';

class LeadsView extends ConsumerStatefulWidget {
  const LeadsView({super.key});

  @override
  ConsumerState<LeadsView> createState() => _LeadsViewState();
}

class _LeadsViewState extends ConsumerState<LeadsView>
    with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = '';
  int? _selectedStageId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Each new route starts with All and an empty search; discard another
    // route's query so the results match the visible controls.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onSearchSubmitted();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(leadsProvider.notifier).refreshLeads();
      ref.read(leadStagesProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchSubmitted() {
    ref
        .read(leadsProvider.notifier)
        .fetchLeads(
          status: _selectedStatus.isEmpty ? null : _selectedStatus,
          stageId: _selectedStageId,
          refreshCounts: true,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
  }

  void _onFilterSelected(String status, int? stageId) {
    if (_selectedStatus == status) return;
    setState(() { _selectedStatus = status; _selectedStageId = stageId; });
    ref
        .read(leadsProvider.notifier)
        .fetchLeads(
          status: status.isEmpty ? null : status,
          stageId: stageId,
          refreshCounts: true,
          search: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
        );
  }

  Widget _buildFilterChipsSkeleton() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          6,
          (i) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              height: 34,
              width: 72 + (i % 3) * 16.0,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeadsLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => Container(
        padding: const EdgeInsets.all(16),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Container(
                  height: 22,
                  width: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 14,
              width: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  height: 12,
                  width: 110,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const Spacer(),
                Container(
                  height: 12,
                  width: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final leadsState = ref.watch(leadsProvider);
    final stagesAsync = ref.watch(leadStagesProvider);
    final stages = ref.watch(activeLeadStagesProvider);
    final stageCounts = ref.watch(leadsStageCountsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppAppBar(title: 'Leads Pipeline'),
      body: Column(
        children: [
          if (stagesAsync.hasError)
            ListTile(
              dense: true,
              tileColor: const Color(0xFFFEF2F2),
              leading: const Icon(Remix.error_warning_line, color: Colors.red),
              title: Text(
                'Unable to load pipeline stages',
                style: AppTypography.inter(
                  fontSize: 13,
                  color: Colors.red.shade900,
                ),
              ),
              trailing: TextButton(
                onPressed: () =>
                    ref.read(leadStagesProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ),
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search leads by company, contact, phone...',
                      hintStyle: AppTypography.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      prefixIcon: const Icon(Remix.search_2_line, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Remix.close_circle_line,
                                size: 18,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                                _onSearchSubmitted();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _onSearchSubmitted(),
                  ),
                ),
                const SizedBox(height: 10),

                // Horizontal Stage Filter Chips
                if (stagesAsync.isLoading && stages.isEmpty)
                  _buildFilterChipsSkeleton()
                else
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildStageChip(
                          name: 'All',
                          key: '',
                          isSelected: _selectedStatus.isEmpty,
                          color: AppColors.primary,
                          count: stageCounts[''] ?? stageCounts['ALL'],
                        ),
                        for (final stage in stages)
                          _buildStageChip(
                            name: stage.name,
                            key: stage.key,
                            stageId: stage.id,
                            isSelected:
                                _selectedStatus.toUpperCase() ==
                                stage.key.toUpperCase(),
                            color: stage.stageColor,
                            bgColor: stage.stageBgColor,
                            count:
                                stageCounts[stage.key.toUpperCase()] ??
                                stageCounts[stage.id.toString()],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          if (leadsState.isLoading && leadsState.hasValue)
            const LinearProgressIndicator(
              minHeight: 2,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            )
          else
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Leads List
          Expanded(
            child: leadsState.when(
              skipLoadingOnReload: true,
              loading: () => _buildLeadsLoading(),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Remix.error_warning_line,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load leads: $err',
                        textAlign: TextAlign.center,
                        style: AppTypography.inter(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _onSearchSubmitted(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (leads) {
                final displayLeads = _selectedStatus.isEmpty ||
                        _selectedStatus.toUpperCase() == 'ALL'
                    ? leads
                    : leads.where((lead) {
                        final resolved = ref
                            .read(leadStagesProvider.notifier)
                            .resolveLeadStage(lead.stageId, lead.status);

                        // If a specific stage ID was selected by tapping a chip,
                        // match strictly against the authoritative stage ID.
                        if (_selectedStageId != null) {
                          final effectiveStageId =
                              lead.stageId ?? resolved?.id;
                          if (effectiveStageId != null) {
                            return effectiveStageId == _selectedStageId;
                          }
                        }

                        // Match against resolved stage key if authoritative stage exists
                        if (resolved != null) {
                          final stageKey = resolved.key.toUpperCase();
                          final selectedUpper = _selectedStatus.toUpperCase();
                          if (stageKey == selectedUpper) return true;
                          if ((selectedUpper == 'VISIT_SCHEDULED' ||
                                  selectedUpper == 'VISIT') &&
                              (stageKey == 'VISIT_SCHEDULED' ||
                                  stageKey == 'VISIT')) {
                            return true;
                          }
                          // Authoritative stage does not match selected filter
                          return false;
                        }

                        // Fallback only for legacy records with no configured stageId / stage
                        if (lead.stageId == null) {
                          final statusUpper = lead.status.toUpperCase();
                          final selectedUpper = _selectedStatus.toUpperCase();
                          if (statusUpper == selectedUpper) return true;
                          if ((selectedUpper == 'VISIT_SCHEDULED' ||
                                  selectedUpper == 'VISIT') &&
                              (statusUpper == 'VISIT_SCHEDULED' ||
                                  statusUpper == 'VISIT')) {
                            return true;
                          }
                        }

                        return false;
                      }).toList();

                if (displayLeads.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Remix.inbox_line,
                            size: 56,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No leads found',
                            style: AppTypography.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedStatus.isNotEmpty
                                ? 'No leads in the "$_selectedStatus" stage.'
                                : 'No leads currently in your CRM pipeline.',
                            textAlign: TextAlign.center,
                            style: AppTypography.inter(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(leadStagesProvider.notifier).refresh();
                    await ref.read(leadsProvider.notifier).refreshLeads();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: displayLeads.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final lead = displayLeads[idx];
                      final resolvedStage = ref
                          .read(leadStagesProvider.notifier)
                          .resolveLeadStage(lead.stageId, lead.status);

                      final stageName = resolvedStage?.name ?? lead.stageName;
                      final stageColor =
                          resolvedStage?.stageColor ?? lead.stageColor;
                      final stageBgColor =
                          resolvedStage?.stageBgColor ?? lead.stageBgColor;
                      final stageBorderColor =
                          resolvedStage?.stageBorderColor ??
                          lead.stageBorderColor;
                      final stageOrder = resolvedStage?.sortOrder ?? 1;

                      return _buildLeadCard(
                        lead: lead,
                        stageName: stageName,
                        stageColor: stageColor,
                        stageBgColor: stageBgColor,
                        stageBorderColor: stageBorderColor,
                        stageOrder: stageOrder,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageChip({
    required String name,
    required String key,
    required bool isSelected,
    required Color color,
    Color? bgColor,
    int? count,
    int? stageId,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => _onFilterSelected(key, stageId),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (bgColor ?? color.withValues(alpha: 0.15))
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : const Color(0xFFE2E8F0),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppTypography.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : const Color(0xFF475569),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isSelected ? color : const Color(0xFF94A3B8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$count',
                    style: AppTypography.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadCard({
    required LeadModel lead,
    required String stageName,
    required Color stageColor,
    required Color stageBgColor,
    required Color stageBorderColor,
    required int stageOrder,
  }) {
    return Container(
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
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    LeadDetailsView(leadId: lead.id, initialLead: lead),
              ),
            ).then((_) {
              ref.read(leadsProvider.notifier).refreshLeads();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        lead.displayName,
                        style: AppTypography.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: stageBgColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: stageBorderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: stageColor,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$stageOrder',
                              style: AppTypography.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            stageName,
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: stageColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (lead.fullName.isNotEmpty &&
                    lead.fullName != lead.companyName) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Remix.user_line,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lead.fullName,
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (lead.phone != null && lead.phone!.isNotEmpty) ...[
                      const Icon(
                        Remix.phone_line,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lead.phone!,
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (lead.city != null && lead.city!.isNotEmpty) ...[
                      const Icon(
                        Remix.map_pin_2_line,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lead.city!,
                        style: AppTypography.inter(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
