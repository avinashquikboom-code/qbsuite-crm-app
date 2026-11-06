import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/shared/widgets/status_badge.dart';
import 'package:quickboom_app/roles/employee/views/visitor/visitor_visit_details_view.dart';
import 'package:quickboom_app/shared/widgets/skeleton_loader.dart';

class VisitorHomeSection extends ConsumerStatefulWidget {
  final Function(String tabName)? onNavigateToTab;
  final Function(int tabIndex)? onNavigateToVisitSubTab;

  const VisitorHomeSection({
    super.key,
    this.onNavigateToTab,
    this.onNavigateToVisitSubTab,
  });

  @override
  ConsumerState<VisitorHomeSection> createState() => _VisitorHomeSectionState();
}

class _VisitorHomeSectionState extends ConsumerState<VisitorHomeSection> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _upcoming = [];
  List<Map<String, dynamic>> _ongoing = [];
  List<Map<String, dynamic>> _completed = [];
  List<Map<String, dynamic>> _todayVisits = [];

  @override
  void initState() {
    super.initState();
    _fetchVisitorData();
  }

  Future<void> _fetchVisitorData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ref
            .read(apiClientProvider)
            .get('/mobile/visits', queryParameters: {'tab': 'upcoming'}),
        ref
            .read(apiClientProvider)
            .get('/mobile/visits', queryParameters: {'tab': 'ongoing'}),
        ref
            .read(apiClientProvider)
            .get('/mobile/visits', queryParameters: {'tab': 'completed'}),
      ]);

      List<Map<String, dynamic>> parseList(dynamic res) {
        dynamic raw = res is Map ? res : res.data;
        if (raw is Map &&
            raw.containsKey('data') &&
            (raw['data'] is List || raw['data'] is Map)) {
          raw = raw['data'];
        }
        if (raw is Map && raw.containsKey('items') && raw['items'] is List) {
          raw = raw['items'];
        } else if (raw is Map &&
            raw.containsKey('data') &&
            raw['data'] is List) {
          raw = raw['data'];
        }
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        return [];
      }

      final upcoming = parseList(results[0]);
      final ongoing = parseList(results[1]);
      final completed = parseList(results[2]);

      // Filter today's visits
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayDay = now.day.toString();

      bool isDateToday(Map<String, dynamic> v) {
        final schedDate =
            v['scheduledDate']?.toString() ?? v['date']?.toString() ?? '';
        return schedDate.contains(todayStr) ||
            schedDate.toLowerCase().contains('today') ||
            schedDate.contains(todayDay);
      }

      final todayList = [...ongoing, ...upcoming.where(isDateToday)];

      // If no visits strictly today, show all active visits
      final effectiveToday = todayList.isNotEmpty
          ? todayList
          : [...ongoing, ...upcoming.take(3)];

      if (mounted) {
        setState(() {
          _upcoming = upcoming;
          _ongoing = ongoing;
          _completed = completed;
          _todayVisits = effectiveToday;
        });
      }
    } catch (e) {
      debugPrint('[VisitorHomeSection] fetch error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading &&
        _upcoming.isEmpty &&
        _ongoing.isEmpty &&
        _completed.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(child: SkeletonStatCard()),
              SizedBox(width: 10),
              Expanded(child: SkeletonStatCard()),
              SizedBox(width: 10),
              Expanded(child: SkeletonStatCard()),
            ],
          ),
          const SizedBox(height: 16),
          const SkeletonCard(),
          const SkeletonCard(),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. SUMMARY CARDS: Scheduled, Ongoing, Completed ──────────────────
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                title: 'Scheduled',
                count: _upcoming.length,
                icon: Remix.calendar_event_line,
                color: const Color(0xFF2563EB), // Blue 600
                bgColor: const Color(0xFFEFF6FF), // Blue 50
                borderColor: const Color(0xFFDBEAFE),
                onTap: () {
                  widget.onNavigateToTab?.call('Visit');
                  widget.onNavigateToVisitSubTab?.call(0);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                title: 'Ongoing',
                count: _ongoing.length,
                icon: Remix.play_circle_line,
                color: const Color(0xFFD97706), // Amber 600
                bgColor: const Color(0xFFFFFBEB), // Amber 50
                borderColor: const Color(0xFFFEF3C7),
                onTap: () {
                  widget.onNavigateToTab?.call('Visit');
                  widget.onNavigateToVisitSubTab?.call(1);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildSummaryCard(
                title: 'Completed',
                count: _completed.length,
                icon: Remix.checkbox_circle_line,
                color: AppColors.primaryDark,
                bgColor: AppColors.primaryLight,
                borderColor: const Color(0xFFBBF7D0),
                onTap: () {
                  widget.onNavigateToTab?.call('History');
                  widget.onNavigateToVisitSubTab?.call(2);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // ── 2. TODAY'S VISITS HEADER ─────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  "Today's Visits",
                  style: AppTypography.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_todayVisits.length}',
                    style: AppTypography.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => widget.onNavigateToTab?.call('Visit'),
              icon: const Icon(Remix.arrow_right_s_line, size: 16),
              label: Text(
                'View All',
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ── 3. TODAY'S VISITS LIST ───────────────────────────────────────────
        if (_todayVisits.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Remix.calendar_check_line,
                      color: AppColors.primaryDark,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'No visits scheduled for today',
                  style: AppTypography.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'New assigned field visits will appear here automatically.',
                  textAlign: TextAlign.center,
                  style: AppTypography.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todayVisits.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final visit = _todayVisits[index];
              return _buildVisitCard(visit);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 18),
                Text(
                  '$count',
                  style: AppTypography.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTypography.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    final statusStr = (visit['status']?.toString() ?? 'SCHEDULED')
        .toUpperCase();
    final isOngoing = statusStr == 'IN_PROGRESS';
    final isCompleted = statusStr == 'COMPLETED';

    final customerName =
        visit['customer']?.toString() ??
        visit['customerName']?.toString() ??
        'Client Meeting';
    final purpose = visit['purpose']?.toString() ?? 'Field Visit';
    final timeStr = visit['time']?.toString() ?? '10:00 AM';
    final location = visit['location']?.toString() ?? 'Client Office';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOngoing ? const Color(0xFFFCD34D) : AppColors.borderLight,
          width: isOngoing ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VisitorVisitDetailsView(
                  visit: visit,
                  onVisitUpdated: _fetchVisitorData,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Remix.building_line,
                      color: Color(0xFF2563EB),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              customerName,
                              style: AppTypography.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StatusBadge(
                            label: isCompleted
                                ? 'Completed'
                                : (isOngoing ? 'Ongoing' : 'Scheduled'),
                            type: isCompleted
                                ? BadgeType.completed
                                : (isOngoing
                                      ? BadgeType.inProgress
                                      : BadgeType.scheduled),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        purpose,
                        style: AppTypography.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            timeStr,
                            style: AppTypography.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '|',
                            style: AppTypography.inter(
                              color: AppColors.borderLight,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              location,
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
