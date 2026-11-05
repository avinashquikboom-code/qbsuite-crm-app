import "package:quickboom_app/core/models/permission_model.dart";
import "package:quickboom_app/core/services/permission_manager.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'calendar/admin_calendar_tab.dart';
import 'home/admin_home_tab.dart';
import 'more/admin_more_tab.dart';
import 'more/proposals/admin_create_proposal_sheet.dart';
import 'more/visits/admin_schedule_visit_sheet.dart';
import 'trending/admin_trending_view.dart';
import 'package:quickboom_app/roles/company_admin/widgets/admin_app_drawer.dart';
import 'package:quickboom_app/roles/company_admin/widgets/admin_quick_action_sheet.dart';
import 'package:quickboom_app/shared/widgets/animated_notification_bell.dart';
import 'package:quickboom_app/roles/employee/views/notifications_view.dart';

import 'work/admin_create_work_sheet.dart';

class _AdminTabConfig {
  final String title;
  final Widget page;
  final IconData icon;
  final IconData activeIcon;

  const _AdminTabConfig({
    required this.title,
    required this.page,
    required this.icon,
    required this.activeIcon,
  });
}

class CompanyAdminMainView extends ConsumerStatefulWidget {
  const CompanyAdminMainView({super.key});

  @override
  ConsumerState<CompanyAdminMainView> createState() =>
      _CompanyAdminMainViewState();
}

class _CompanyAdminMainViewState extends ConsumerState<CompanyAdminMainView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openQuickActionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminQuickActionSheet(
        onScheduleVisit: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AdminScheduleVisitSheet(),
          );
        },
        onCreateProposal: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AdminCreateProposalSheet(),
          );
        },
        onCreateSSMWork: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AdminCreateWorkSheet(),
          );
        },
        onAssignTask: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const AdminCreateWorkSheet(),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionManagerProvider);

    final List<_AdminTabConfig> visibleTabs = [
      if (perms.canView(AppModule.dashboard))
        _AdminTabConfig(
          title: "Dashboard",
          page: AdminHomeTab(onNavigateTab: _navigateToTab),
          icon: Remix.home_5_line,
          activeIcon: Remix.home_5_fill,
        ),
      const _AdminTabConfig(
        title: "Trending",
        page: AdminTrendingView(),
        icon: Remix.fire_line,
        activeIcon: Remix.fire_fill,
      ),
      if (perms.canView(AppModule.visits) || perms.canView(AppModule.tasks))
        const _AdminTabConfig(
          title: "Calendar",
          page: AdminCalendarTab(),
          icon: Remix.calendar_2_line,
          activeIcon: Remix.calendar_2_fill,
        ),
      const _AdminTabConfig(
        title: "More",
        page: AdminMoreTab(),
        icon: Remix.more_fill,
        activeIcon: Remix.more_fill,
      ),
    ];

    if (visibleTabs.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final safeIndex = _currentIndex.clamp(0, visibleTabs.length - 1);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
        } else if (safeIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        drawer: AdminAppDrawer(
          onNavigateToTab: _navigateToTab,
          currentTabIndex: safeIndex,
        ),
        drawerEnableOpenDragGesture: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            visibleTabs[safeIndex].title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: false,
          actions: [
            AnimatedNotificationBell(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotificationsView()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Remix.flashlight_line, color: AppColors.primary),
              tooltip: "Quick Actions",
              onPressed: _openQuickActionSheet,
            ),
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Remix.menu_line, color: AppColors.textPrimary),
                tooltip: "Open Menu",
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: IndexedStack(
          index: safeIndex,
          children: visibleTabs.map((t) => t.page).toList(),
        ),
        floatingActionButton: safeIndex == 0
            ? FloatingActionButton(
                onPressed: _openQuickActionSheet,
                backgroundColor: AppColors.primary,
                child: const Icon(Remix.add_line, color: Colors.white),
              )
            : null,
        bottomNavigationBar: Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
            border: const Border(
              top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
            ),
          ),
          child: Row(
            children: visibleTabs.asMap().entries.map((entry) {
              final idx = entry.key;
              final tab = entry.value;
              return _buildNavItem(
                idx,
                tab.title,
                tab.icon,
                tab.activeIcon,
                isSelected: safeIndex == idx,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    String label,
    IconData icon,
    IconData activeIcon, {
    bool isSelected = false,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
