import 'package:dio/dio.dart';
import 'package:quickboom_app/core/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';

import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/roles/customer/widgets/schedule_visit_bottom_sheet.dart';
import 'package:quickboom_app/roles/customer/models/lead_model.dart'
    as customer_model;
import 'package:quickboom_app/shared/models/lead_model.dart';
import 'package:quickboom_app/shared/models/lead_stage_model.dart';
import 'package:quickboom_app/shared/viewmodels/lead_stages_viewmodel.dart';
import 'package:quickboom_app/shared/viewmodels/leads_viewmodel.dart';
import 'package:quickboom_app/shared/widgets/app_app_bar.dart';
import 'package:quickboom_app/shared/widgets/contact_information_card.dart';
import 'package:quickboom_app/shared/widgets/social_media_profiles_card.dart';

class LeadDetailsView extends ConsumerStatefulWidget {
  final String leadId;
  final LeadModel? initialLead;

  const LeadDetailsView({super.key, required this.leadId, this.initialLead});

  @override
  ConsumerState<LeadDetailsView> createState() => _LeadDetailsViewState();
}

class _LeadDetailsViewState extends ConsumerState<LeadDetailsView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  LeadModel? _lead;
  bool _isLoading = false;
  String? _loadError;
  bool _isUpdatingStage = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 4, vsync: this);
    _lead = widget.initialLead;
    _fetchLead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isUpdatingStage) {
      _fetchLead();
      ref.read(leadStagesProvider.notifier).refresh();
    }
  }

  String _message(Object error) => error is DioException
      ? ApiException.fromDioException(error).message
      : error.toString().replaceFirst('Exception: ', '');

  Future<void> _fetchLead() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final lead = await ref
          .read(leadsProvider.notifier)
          .getLeadDetails(widget.leadId);
      if (mounted && lead != null) {
        setState(() => _lead = lead);
      }
    } catch (e) {
      if (mounted) setState(() => _loadError = _message(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool get _isVisitor {
    final rbac = ref.read(permissionManagerProvider);
    final rawRole = (rbac.role ?? '').trim().toUpperCase();
    return !(rawRole.contains('ADMIN') || rawRole.contains('CUSTOMER') || rawRole.contains('BPO')) && (rawRole.contains('VISITOR') || rawRole.contains('FIELD') || rbac.canCompleteVisit);
  }

  bool get _canScheduleVisits {
    final rbac = ref.read(permissionManagerProvider);
    final rawRole = (rbac.role ?? '').trim().toUpperCase();
    final isCustomerOrAdmin =
        rawRole.contains('CUSTOMER') ||
        rawRole.contains('ADMIN') ||
        rawRole == 'SUPER_ADMIN';
    final isBpo = rawRole.contains('BPO') || rbac.isCrmEligible;
    return isCustomerOrAdmin ||
        isBpo ||
        rbac.canScheduleVisits ||
        PermissionManager.instance.canScheduleVisits;
  }

  void _showScheduleVisitSheet() {
    final lead = _lead;
    if (lead == null) return;
    if (!_canScheduleVisits) {
      AppToast.error(
        context,
        'Access denied: Missing required permission [VISITS:CREATE]',
      );
      return;
    }

    final customerLead = customer_model.LeadModel.fromJson(lead.toJson());
    showScheduleVisitBottomSheet(
      context,
      lead: customerLead,
      ref: ref,
      onVisitScheduled: (updatedCustomerLead) async {
        await _fetchLead();
        await ref.read(leadsProvider.notifier).refreshLeads();
      },
    );
  }

  Future<void> _handleStageChange(LeadStageModel targetStage) async {
    if (_isUpdatingStage || !targetStage.isActive) return;
    final lead = _lead;
    if (lead == null) return;

    if (_isVisitor) {
      final currentStatus = (lead.status).toUpperCase();
      final currentStageKey = (lead.stage?.key ?? '').toUpperCase();
      final currentStageName = (lead.stage?.name ?? '').toUpperCase();
      final isCurrentScheduled = currentStatus == 'VISIT_SCHEDULED' ||
          currentStatus == 'VISIT' ||
          currentStageKey == 'VISIT_SCHEDULED' ||
          currentStageKey == 'VISIT' ||
          currentStageName == 'VISIT SCHEDULED' ||
          currentStageName.contains('VISIT SCHEDULED');

      if (!isCurrentScheduled) {
        AppToast.error(
          context,
          'Visitors can only update leads that are currently in Visit Scheduled stage',
        );
        return;
      }

      final targetKey = targetStage.key.toUpperCase();
      final targetName = targetStage.name.toUpperCase();
      final isTargetVisitDone = targetKey == 'VISIT_DONE' ||
          targetName == 'VISIT DONE' ||
          targetName == 'VISIT DONE';

      if (!isTargetVisitDone) {
        AppToast.error(
          context,
          'Visitor employee can only update leads to Visit Done stage.',
        );
        return;
      }
    }

    final currentResolved = ref
        .read(leadStagesProvider.notifier)
        .resolveLeadStage(lead.stageId, lead.status);

    if (currentResolved != null && currentResolved.id == targetStage.id) {
      AppToast.info(context, 'Lead is already in "${targetStage.name}" stage');
      return;
    }

    final isTargetScheduled =
        targetStage.key.toUpperCase() == 'VISIT_SCHEDULED' ||
        targetStage.name.toUpperCase().contains('VISIT SCHEDULED');

    if (isTargetScheduled && !_isVisitor && _canScheduleVisits) {
      _showScheduleVisitSheet();
      return;
    }

    setState(() => _isUpdatingStage = true);

    try {
      final updated = await ref
          .read(leadsProvider.notifier)
          .updateStatus(
            lead.id,
            status: targetStage.key,
            stageId: targetStage.id,
          );

      if (updated != null && mounted) {
        setState(() => _lead = updated);
        await ref.read(leadsProvider.notifier).refreshLeads();
        if (!mounted) return;
        AppToast.success(context, 'Stage updated to ${targetStage.name}');
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = _message(e);
        AppToast.error(context, 'Failed to update stage: $cleanMsg');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStage = false);
      }
    }
  }

  void _showStagePickerSheet(
    List<LeadStageModel> stages,
    LeadStageModel? currentStage,
  ) {
    if (_isUpdatingStage) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSheetHandle(),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Remix.git_commit_line,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Pipeline Stage',
                            style: AppTypography.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Move this lead to any configured CRM stage',
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: stages.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final stage = stages[idx];
                    final isCurrent = currentStage != null
                        ? stage.id == currentStage.id ||
                              stage.key.toUpperCase() ==
                                  currentStage.key.toUpperCase()
                        : (_lead?.stageId == stage.id ||
                              _lead?.status.toUpperCase() ==
                                  stage.key.toUpperCase());

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_isVisitor &&
                              stage.key.toUpperCase() != 'VISIT_DONE' &&
                              !stage.name.toUpperCase().contains('VISIT DONE')) {
                            AppToast.error(
                              context,
                              'Visitors can only advance leads to Visit Done stage.',
                            );
                            return;
                          }
                          Navigator.pop(modalCtx);
                          if (!isCurrent) {
                            _handleStageChange(stage);
                          } else {
                            AppToast.info(
                              context,
                              'Lead is already in "${stage.name}" stage',
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? stage.stageBgColor
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrent
                                  ? stage.stageColor
                                  : const Color(0xFFE2E8F0),
                              width: isCurrent ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: stage.stageColor,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${idx + 1}',
                                  style: AppTypography.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stage.name,
                                      style: AppTypography.inter(
                                        fontSize: 14,
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        color: isCurrent
                                            ? stage.stageColor
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      'KEY: ${stage.key}',
                                      style: AppTypography.inter(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: stage.stageColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Current',
                                    style: AppTypography.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              else
                                const Icon(
                                  Remix.arrow_right_s_line,
                                  size: 18,
                                  color: AppColors.textSecondary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFCBD5E1),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lead = _lead;
    final stagesAsync = ref.watch(leadStagesProvider);
    final stages = ref.watch(activeLeadStagesProvider);

    final currentStage = lead != null
        ? lead.stage ??
              ref
                  .read(leadStagesProvider.notifier)
                  .resolveLeadStage(lead.stageId, lead.status)
        : null;

    final nextStage = lead != null
        ? ref
              .read(leadStagesProvider.notifier)
              .nextStage(lead.stageId, lead.status)
        : null;

    final currentOrder = currentStage != null ? currentStage.sortOrder : 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppAppBar(
        title: 'Lead Details',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Remix.refresh_line),
            onPressed: _fetchLead,
          ),
        ],
      ),
      body: _isLoading && lead == null
          ? const Center(child: CircularProgressIndicator())
          : lead == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Remix.error_warning_line,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(_loadError ?? 'Lead not found'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _fetchLead,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchLead,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (stagesAsync.isLoading) const LinearProgressIndicator(),
                    if (stagesAsync.hasError)
                      ListTile(
                        title: const Text('Unable to load pipeline stages'),
                        trailing: TextButton(
                          onPressed: () =>
                              ref.read(leadStagesProvider.notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ),
                    // 1. LEAD HEADER CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lead.displayName,
                                      style: AppTypography.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (lead.fullName.isNotEmpty &&
                                        lead.fullName != lead.companyName) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        lead.fullName,
                                        style: AppTypography.inter(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Stage badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (currentStage?.stageBgColor ??
                                      lead.stageBgColor),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        (currentStage?.stageBorderColor ??
                                        lead.stageBorderColor),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color:
                                            (currentStage?.stageColor ??
                                            lead.stageColor),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '$currentOrder',
                                        style: AppTypography.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      currentStage?.name ?? lead.stageName,
                                      style: AppTypography.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            (currentStage?.stageColor ??
                                            lead.stageColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'SOURCE: ${lead.source}',
                                  style: AppTypography.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'FROM: ${lead.createdFrom}',
                                  style: AppTypography.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 2. PIPELINE PROGRESSION / STAGE CARD
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
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
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(
                                      Remix.git_commit_line,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Pipeline Stage',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Stage $currentOrder of ${stages.length}',
                                style: AppTypography.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Stage Selector Button
                          InkWell(
                            onTap: _isUpdatingStage || stages.isEmpty
                                ? null
                                : () => _showStagePickerSheet(
                                    stages,
                                    currentStage,
                                  ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color:
                                    (currentStage?.stageBgColor ??
                                    lead.stageBgColor),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color:
                                      (currentStage?.stageBorderColor ??
                                      lead.stageBorderColor),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color:
                                          (currentStage?.stageColor ??
                                          lead.stageColor),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$currentOrder',
                                      style: AppTypography.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          currentStage?.name ?? lead.stageName,
                                          style: AppTypography.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                (currentStage?.stageColor ??
                                                lead.stageColor),
                                          ),
                                        ),
                                        Text(
                                          'Tap to change pipeline stage',
                                          style: AppTypography.inter(
                                            fontSize: 12,
                                            color:
                                                (currentStage?.stageColor ??
                                                        lead.stageColor)
                                                    .withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_isUpdatingStage)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Remix.arrow_down_s_line,
                                      color:
                                          (currentStage?.stageColor ??
                                          lead.stageColor),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          if (nextStage != null) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: nextStage.stageColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: _isUpdatingStage
                                    ? null
                                    : () => _handleStageChange(nextStage),
                                icon: const Icon(
                                  Remix.arrow_right_line,
                                  size: 16,
                                ),
                                label: Text(
                                  'Advance to ${nextStage.name}',
                                  style: AppTypography.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 3. CONTACT INFORMATION CARD
                    ContactInformationCard(
                      businessName: lead.companyName,
                      contactPerson: lead.contactPerson,
                      phone: lead.phone,
                      email: lead.email,
                      website: lead.website,
                      address: lead.address,
                      city: lead.city,
                      state: lead.state,
                      pincode: lead.pincode,
                      country: lead.country,
                      category: lead.category,
                      googlePlaceId: lead.googlePlaceId,
                    ),

                    // 4. SOCIAL MEDIA & ONLINE PRESENCE CARD
                    if (lead.socialMedia != null) ...[
                      const SizedBox(height: 16),
                      SocialMediaProfilesCard(socialMedia: lead.socialMedia),
                    ],

                    const SizedBox(height: 16),

                    // 5. OPERATIONAL TABS: Notes | Visits | Timeline | History
                    Container(
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
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: AppColors.primary,
                        indicatorWeight: 3.0,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: AppColors.primary,
                        unselectedLabelColor: const Color(0xFF64748B),
                        labelStyle: AppTypography.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        unselectedLabelStyle: AppTypography.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        tabs: const [
                          Tab(
                            icon: Icon(Remix.file_text_line, size: 18),
                            text: 'Notes',
                            iconMargin: EdgeInsets.only(bottom: 4),
                          ),
                          Tab(
                            icon: Icon(Remix.calendar_check_line, size: 18),
                            text: 'Visits',
                            iconMargin: EdgeInsets.only(bottom: 4),
                          ),
                          Tab(
                            icon: Icon(Remix.time_line, size: 18),
                            text: 'Timeline',
                            iconMargin: EdgeInsets.only(bottom: 4),
                          ),
                          Tab(
                            icon: Icon(Remix.history_line, size: 18),
                            text: 'History',
                            iconMargin: EdgeInsets.only(bottom: 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, _) {
                        switch (_tabController.index) {
                          case 0:
                            return _buildNotesTab(lead);
                          case 1:
                            return _buildVisitsTab(lead);
                          case 2:
                            return _buildTimelineTab(lead);
                          case 3:
                            return _buildHistoryTab(lead);
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  static String _formatDateTime(String rawDate) {
    if (rawDate.isEmpty) return 'Recent';
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final now = DateTime.now();
      final isToday =
          dt.year == now.year && dt.month == now.month && dt.day == now.day;
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute $amPm';

      if (isToday) return 'Today at $timeStr';

      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $timeStr';
    } catch (_) {
      return rawDate;
    }
  }

  void _showAddNoteBottomSheet(BuildContext context) {
    final textController = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: bottomInset > 0 ? bottomInset + 16 : 28,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderLight,
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
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Remix.file_text_line,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Note',
                            style: AppTypography.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Record an internal note or meeting summary',
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
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 5,
                  minLines: 3,
                  autofocus: true,
                  style: AppTypography.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        'Enter note details, discussion summary, or next steps...',
                    hintStyle: AppTypography.inter(
                      fontSize: 13,
                      color: AppColors.textPlaceholder,
                    ),
                    filled: true,
                    fillColor: AppColors.scaffoldBg,
                    contentPadding: const EdgeInsets.all(14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.borderLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.borderLight,
                      ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isSaving
                          ? null
                          : () => Navigator.pop(sheetContext),
                      child: Text(
                        'Cancel',
                        style: AppTypography.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: isSaving
                          ? null
                          : () async {
                              final text = textController.text.trim();
                              if (text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter note content'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isSaving = true);
                              try {
                                final success = await ref
                                    .read(leadsProvider.notifier)
                                    .addNote(widget.leadId, text);

                                if (context.mounted) {
                                  Navigator.pop(sheetContext);
                                  ref.invalidate(sharedLeadNotesProvider(widget.leadId));
                                  _fetchLead();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        success
                                            ? 'Note added successfully'
                                            : 'Failed to add note',
                                      ),
                                      backgroundColor: success
                                          ? AppColors.success
                                          : AppColors.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  setSheetState(() => isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to add note: $e'),
                                      backgroundColor: AppColors.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Save Note',
                              style: AppTypography.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotesTab(LeadModel lead) {
    final notesAsync = ref.watch(sharedLeadNotesProvider(lead.id));

    return notesAsync.when(
      data: (notes) {
        final hasApiNotes = notes.isNotEmpty;
        final hasLegacyNote = lead.notes != null && lead.notes!.trim().isNotEmpty;

        if (!hasApiNotes && !hasLegacyNote) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Remix.file_text_line,
                    size: 36,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'No Notes Yet',
                  style: AppTypography.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add a note to keep track of important information about this lead.',
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Remix.add_line, size: 16),
                  label: Text(
                    'Add Note',
                    style: AppTypography.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () => _showAddNoteBottomSheet(context),
                ),
              ],
            ),
          );
        }

        final allNotes = <Map<String, dynamic>>[...notes];
        if (allNotes.isEmpty && hasLegacyNote) {
          allNotes.add({
            'id': 'legacy',
            'content': lead.notes!,
            'authorName': 'Team Member',
            'createdAt': lead.createdAt ?? '',
          });
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Lead Notes (${allNotes.length})',
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => _showAddNoteBottomSheet(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Remix.add_line,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Add Note',
                            style: AppTypography.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: allNotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final note = allNotes[index];
                final content = note['content']?.toString() ?? '';
                final author = (note['authorName']?.toString() ??
                        (note['user'] is Map
                            ? '${note['user']['firstName'] ?? ''} ${note['user']['lastName'] ?? ''}'
                            : null) ??
                        'Team Member')
                    .trim();
                final dateStr =
                    _formatDateTime(note['createdAt']?.toString() ?? '');

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        content,
                        style: AppTypography.inter(
                          fontSize: 13.5,
                          height: 1.45,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Remix.user_line,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '$author • $dateStr',
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
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Remix.error_warning_line,
              size: 36,
              color: AppColors.error,
            ),
            const SizedBox(height: 10),
            Text(
              'Unable to load notes.',
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => ref.invalidate(sharedLeadNotesProvider(lead.id)),
              child: Text(
                'Retry',
                style: AppTypography.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitsTab(LeadModel lead) {
    final visits = lead.visits;
    if (visits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Remix.calendar_check_line,
                size: 36,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Visits Scheduled',
              style: AppTypography.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Visits scheduled for this lead will appear here.',
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (_canScheduleVisits && !_isVisitor) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Remix.add_line, size: 16),
                label: Text(
                  'Schedule Visit',
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _showScheduleVisitSheet,
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Field Visits (${visits.length})',
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_canScheduleVisits && !_isVisitor)
                InkWell(
                  onTap: _showScheduleVisitSheet,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Remix.add_line,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Schedule Visit',
                          style: AppTypography.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: visits.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final v = visits[index];
            final statusStr = v.status.toUpperCase();
            final isDone =
                statusStr == 'COMPLETED' || statusStr == 'VISIT_DONE';
            final statusColor = isDone
                ? const Color(0xFF10B981)
                : (statusStr == 'IN_PROGRESS'
                    ? const Color(0xFFF59E0B)
                    : AppColors.primary);
            final statusBg = statusColor.withValues(alpha: 0.1);
            final dateLabel =
                v.date.isNotEmpty ? _formatDateTime(v.date) : 'Scheduled';
            final timeLabel = v.time ?? '';

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isDone
                              ? 'Visit Done'
                              : (statusStr == 'IN_PROGRESS'
                                  ? 'In Progress'
                                  : 'Scheduled'),
                          style: AppTypography.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ),
                      if (v.assignedEmployee != null &&
                          v.assignedEmployee!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Remix.user_star_line,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              v.assignedEmployee!,
                              style: AppTypography.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    v.purpose,
                    style: AppTypography.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Remix.map_pin_2_line,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          v.location,
                          style: AppTypography.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Remix.time_line,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$dateLabel${timeLabel.isNotEmpty ? ' • $timeLabel' : ''}',
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (v.notes != null && v.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        v.notes!.trim(),
                        style: AppTypography.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineTab(LeadModel lead) {
    final createdStr = _formatDateTime(lead.createdAt ?? '');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Remix.checkbox_circle_line,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lead Created (${lead.source.replaceAll('_', ' ')})',
                      style: AppTypography.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      createdStr,
                      style: AppTypography.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lead.stage != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Remix.git_commit_line,
                    size: 16,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Stage: ${lead.stageName}',
                        style: AppTypography.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Active in pipeline',
                        style: AppTypography.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryTab(LeadModel lead) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stage History',
            style: AppTypography.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${lead.stageName} (Current)',
                  style: AppTypography.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created from: ${lead.createdFrom.replaceAll('_', ' ')}',
            style: AppTypography.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (lead.assignedToName != null &&
              lead.assignedToName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Assigned to: ${lead.assignedToName}',
              style: AppTypography.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
