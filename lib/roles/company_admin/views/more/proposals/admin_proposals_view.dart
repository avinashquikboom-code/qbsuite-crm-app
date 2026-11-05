import "package:quickboom_app/core/models/permission_model.dart";
import "package:quickboom_app/core/services/permission_manager.dart";
import "package:quickboom_app/shared/widgets/permission_guarded_view.dart";
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';
import 'admin_create_proposal_sheet.dart';

class AdminProposalsView extends ConsumerStatefulWidget {
  const AdminProposalsView({super.key});

  @override
  ConsumerState<AdminProposalsView> createState() => _AdminProposalsViewState();
}

class _AdminProposalsViewState extends ConsumerState<AdminProposalsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Draft',
    'Sent',
    'Accepted',
    'Rejected',
    'Expired',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 1,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openCreateProposalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminCreateProposalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionManagerProvider);
    if (!perms.canView(AppModule.proposals)) {
      return const PermissionGuardedView(
        moduleKey: AppModule.proposals,
        moduleTitle: "Proposals & Quotes",
        child: SizedBox(),
      );
    }
    final state = ref.watch(companyAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Client Proposals',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: AppColors.textPrimary),
        actions: [
          if (perms.canCreate(AppModule.proposals))
            IconButton(
              icon: const Icon(Remix.add_line, color: AppColors.primary),
              onPressed: _openCreateProposalSheet,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildProposalList(
              state.proposals
                  .where((p) => p.status == ProposalStatus.draft)
                  .toList(),
            ),
            _buildProposalList(
              state.proposals
                  .where((p) => p.status == ProposalStatus.sent)
                  .toList(),
            ),
            _buildProposalList(
              state.proposals
                  .where((p) => p.status == ProposalStatus.accepted)
                  .toList(),
            ),
            _buildProposalList(
              state.proposals
                  .where((p) => p.status == ProposalStatus.rejected)
                  .toList(),
            ),
            _buildProposalList(
              state.proposals
                  .where((p) => p.status == ProposalStatus.expired)
                  .toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: perms.canCreate(AppModule.proposals)
          ? FloatingActionButton(
              onPressed: _openCreateProposalSheet,
              backgroundColor: AppColors.primary,
              child: const Icon(Remix.add_line, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildProposalList(List<AdminProposal> proposals) {
    if (proposals.isEmpty) {
      return Center(
        child: Text(
          'No proposals in this category',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: proposals.length,
      itemBuilder: (context, index) {
        final p = proposals[index];
        return _buildProposalCard(p);
      },
    );
  }

  Widget _buildProposalCard(AdminProposal p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  p.customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${p.amount.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${p.packageName} • ${p.id}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              p.services,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: const Color(0xFF334155),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Validity: ${p.validity} • Date: ${p.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: p.status.bgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  p.status.label,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: p.status.color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
