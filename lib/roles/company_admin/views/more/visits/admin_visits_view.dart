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
import 'admin_schedule_visit_sheet.dart';

class AdminVisitsView extends ConsumerStatefulWidget {
  const AdminVisitsView({super.key});

  @override
  ConsumerState<AdminVisitsView> createState() => _AdminVisitsViewState();
}

class _AdminVisitsViewState extends ConsumerState<AdminVisitsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Today (6)',
    'Upcoming',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openScheduleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AdminScheduleVisitSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionManagerProvider);
    if (!perms.canView(AppModule.visits)) {
      return const PermissionGuardedView(
        moduleKey: AppModule.visits,
        moduleTitle: "Client Visits",
        child: SizedBox(),
      );
    }
    final state = ref.watch(companyAdminProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Client Field Visits',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        leading: const BackButton(color: AppColors.textPrimary),

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
            _buildVisitList(
              state.visits.where((v) => v.status == VisitStatus.today).toList(),
            ),
            _buildVisitList(
              state.visits
                  .where((v) => v.status == VisitStatus.upcoming)
                  .toList(),
            ),
            _buildVisitList(
              state.visits
                  .where((v) => v.status == VisitStatus.completed)
                  .toList(),
            ),
            _buildVisitList(
              state.visits
                  .where((v) => v.status == VisitStatus.cancelled)
                  .toList(),
            ),
          ],
        ),
      ),
      floatingActionButton: perms.canCreate(AppModule.visits)
          ? FloatingActionButton(
              onPressed: _openScheduleSheet,
              backgroundColor: AppColors.primary,
              child: const Icon(Remix.add_line, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildVisitList(List<AdminVisit> visits) {
    if (visits.isEmpty) {
      return Center(
        child: Text(
          'No visits in this category',
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
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final v = visits[index];
        return _buildVisitCard(v);
      },
    );
  }

  Widget _buildVisitCard(AdminVisit v) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  v.customerName,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: v.status.bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  v.status.label,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: v.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildMetaRow(Remix.user_3_line, 'Field Staff: ${v.employeeName}'),
          const SizedBox(height: 4),
          _buildMetaRow(Remix.time_line, 'Date & Time: ${v.date}, ${v.time}'),
          const SizedBox(height: 4),
          _buildMetaRow(Remix.map_pin_2_line, 'Location: ${v.location}'),
          if (v.notes != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Notes: ${v.notes}',
                style: GoogleFonts.outfit(
                  fontSize: 11.5,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
