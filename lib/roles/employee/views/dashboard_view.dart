import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/services/permission_manager.dart';
import 'package:quickboom_app/core/providers/auth_provider.dart';
import 'package:quickboom_app/roles/employee/viewmodels/work_permissions_viewmodel.dart';
import 'package:quickboom_app/core/constants/constants.dart';
import 'package:quickboom_app/core/providers.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/shared/widgets/app_drawer.dart';

import 'package:quickboom_app/shared/views/data_capture/data_capture_home_screen.dart';
import 'package:quickboom_app/shared/views/leads/leads_view.dart';
import 'package:quickboom_app/roles/employee/views/sidebar_views/customers_view.dart';
import 'home_view.dart';
import 'profile_view.dart';
import 'visits_view.dart';
import 'visitor/visitor_history_view.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_profile_viewmodel.dart';
import 'package:quickboom_app/roles/employee/viewmodels/employee_attendance_viewmodel.dart';
import 'package:quickboom_app/core/services/notification_service.dart';
import 'package:quickboom_app/core/widgets/qb_bottom_navigation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data class for a bottom-nav tab item
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardTabItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget page;

  const _DashboardTabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.page,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// DashboardView — main employee scaffold with 5-slot bottom navigation
// ─────────────────────────────────────────────────────────────────────────────
class DashboardView extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const DashboardView({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentIndex;
  DateTime? _lastPermissionRefresh;
  List<_DashboardTabItem> _currentTabs = [];
  int _lastKnownTabCount = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestAndroidNotificationPermission();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Refresh permissions when app returns from background — with 5-minute cooldown.
  /// This is the fallback for missed WebSocket events while the app was backgrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final lastRefresh = _lastPermissionRefresh;
      final cooldownPassed =
          lastRefresh == null || now.difference(lastRefresh).inMinutes >= 5;
      if (cooldownPassed) {
        _lastPermissionRefresh = now;
        debugPrint(
          '[DASHBOARD] App resumed — refreshing permissions (fallback for missed events).',
        );
        // Silently fetch latest effective permissions from backend.
        // Old permissions remain active until the new set arrives — no UI blank.
        ref.read(loginStateProvider.notifier).refreshPermissions();
      }
    }
  }

  /// Called in build() after the tab list is computed.
  /// When a permission change causes a tab to disappear, `_currentIndex` is
  /// reset to 0 in state (not just clipped visually in safeIndex) so that the
  /// next rebuild does not try to select a stale/invalid index.
  void _syncTabIndex(List<_DashboardTabItem> tabs) {
    if (tabs.length < _lastKnownTabCount && _currentIndex >= tabs.length) {
      // Schedule after the current build frame — cannot call setState during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currentIndex >= tabs.length) {
          setState(() {
            _currentIndex = 0; // Fall back to Home — always safe.
          });
          debugPrint(
            '[DASHBOARD] Active tab removed by permission change. '
            'Navigated to Home (index 0).',
          );
        }
      });
    }
    _lastKnownTabCount = tabs.length;
  }

  void _syncSidebarSelection(String label) {
    final lower = label.toLowerCase();
    if (lower == 'home' || lower == 'dashboard') {
      ref.read(sidebarSelectionProvider.notifier).select(SidebarItem.dashboard);
    } else if (lower.contains('work')) {
      ref.read(sidebarSelectionProvider.notifier).select(SidebarItem.ssmWork);
    } else if (lower.contains('task')) {
      ref.read(sidebarSelectionProvider.notifier).select(SidebarItem.tasks);
    } else if (lower.contains('calendar') || lower.contains('schedule')) {
      ref
          .read(sidebarSelectionProvider.notifier)
          .select(SidebarItem.employeeCalendar);
    } else if (lower.contains('data') || lower.contains('place')) {
      ref
          .read(sidebarSelectionProvider.notifier)
          .select(SidebarItem.dataCapture);
    } else if (lower.contains('lead')) {
      ref.read(sidebarSelectionProvider.notifier).select(SidebarItem.leads);
    } else if (lower.contains('visit') || lower.contains('history')) {
      ref.read(sidebarSelectionProvider.notifier).select(SidebarItem.visits);
    } else if (lower.contains('custom') || lower.contains('client')) {
      ref.read(sidebarSelectionProvider.notifier).select(SidebarItem.customers);
    }
  }

  void _navigateToTab(dynamic target) {
    if (mounted) {
      setState(() {
        if (target is int) {
          _currentIndex = target;
        } else if (target is String) {
          final wanted = target.toLowerCase();
          var idx = _currentTabs.indexWhere(
            (t) => t.label.toLowerCase() == wanted,
          );
          // Production team work tab is "My Work", not "Tasks".
          if (idx == -1 && wanted == 'tasks') {
            idx = _currentTabs.indexWhere(
              (t) => t.label.toLowerCase() == 'my work',
            );
          }
          if (idx != -1) {
            _currentIndex = idx;
          }
        }
      });
      if (_currentIndex >= 0 && _currentIndex < _currentTabs.length) {
        _syncSidebarSelection(_currentTabs[_currentIndex].label);
      }
    }
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final rbacPerms = ref.watch(permissionManagerProvider);
    // workPerms is still watched so the provider stays alive for other widgets
    // that depend on it (e.g. HomeView my-work section checks).
    final permsState = ref.watch(workPermissionsProvider);
    final authState = ref.watch(loginStateProvider);
    final attendanceState = ref.watch(employeeAttendanceProvider);
    final empInfo = attendanceState.status.employee;

    // ── Resolve Visitor identification from existing provider ───────────────
    final profile = ref.watch(employeeProfileProvider).asData?.value;
    final desigName =
        (profile?.designation ??
                empInfo?.designation ??
                authState.designation ??
                '')
            .trim()
            .toUpperCase();
    final roleName = (rbacPerms.role ?? authState.userRole ?? '')
        .trim()
        .toUpperCase();
    final deptName = (profile?.department ?? empInfo?.department ?? '')
        .trim()
        .toUpperCase();
    final isVisitor =
        desigName.contains('VISITOR') ||
        desigName == 'VISIT' ||
        desigName.contains('FIELD VISIT') ||
        roleName.contains('VISITOR') ||
        roleName == 'VISIT';

    final isBpoTeam =
        rbacPerms.isCrmEligible ||
        permsState.permissions.isCrmEligible ||
        deptName.contains('BPO') ||
        deptName.contains('TELESALES') ||
        deptName.contains('TELECALL') ||
        deptName.contains('CALL') ||
        desigName.contains('BPO') ||
        desigName.contains('TELESALES') ||
        desigName.contains('TELECALL') ||
        desigName.contains('CALLER') ||
        roleName.contains('BPO') ||
        roleName.contains('TELESALES') ||
        roleName.contains('TELECALL') ||
        roleName.contains('CALLER');

    final mediaQuery = MediaQuery.maybeOf(context);
    final devWidth = mediaQuery?.size.width ?? 0;
    final devHeight = mediaQuery?.size.height ?? 0;
    final devPixelRatio = mediaQuery?.devicePixelRatio ?? 1.0;
    final devTimezone = DateTime.now().timeZoneName;

    debugPrint(
      '[CALENDAR_VISIBILITY_DEBUG] DashboardView -> '
      'deviceWidth: $devWidth, '
      'deviceHeight: $devHeight, '
      'pixelRatio: $devPixelRatio, '
      'timezone: $devTimezone, '
      'isBpoTeam: $isBpoTeam, '
      'isVisitor: $isVisitor, '
      'role: $roleName, '
      'desig: $desigName, '
      'dept: $deptName',
    );

    // ── Build the fixed tab list ───────────────────────────────────────────
    final tabs = <_DashboardTabItem>[
      // Slot 1: Home
      _DashboardTabItem(
        label: 'Home',
        icon: Remix.home_5_line,
        activeIcon: Remix.home_5_fill,
        page: HomeView(
          onNavigateToTab: _navigateToTab,
          onOpenDrawer: _openDrawer,
        ),
      ),

      // Production employees use the separate production app.
      if (isVisitor) ...[
        const _DashboardTabItem(
          label: 'Visits',
          icon: Remix.map_pin_2_line,
          activeIcon: Remix.map_pin_2_fill,
          page: VisitsView(),
        ),
        const _DashboardTabItem(
          label: 'History',
          icon: Remix.history_line,
          activeIcon: Remix.history_fill,
          page: VisitorHistoryView(),
        ),
      ] else ...[
        const _DashboardTabItem(
          label: 'Data Capture',
          icon: Remix.add_circle_line,
          activeIcon: Remix.add_circle_fill,
          page: DataCaptureHomeScreen(),
        ),
        const _DashboardTabItem(
          label: 'Leads',
          icon: Remix.user_search_line,
          activeIcon: Remix.user_search_fill,
          page: LeadsView(),
        ),
        const _DashboardTabItem(
          label: 'Customers',
          icon: Remix.building_2_line,
          activeIcon: Remix.building_2_fill,
          page: CustomersView(),
        ),
      ],

      // Final Position: Profile
      _DashboardTabItem(
        label: 'Profile',
        icon: Remix.user_3_line,
        activeIcon: Remix.user_3_fill,
        page: ProfileView(onNavigateToTab: (idx) => _navigateToTab(idx)),
      ),
    ];

    _currentTabs = tabs;

    // Ensure _currentIndex stays in bounds when tabs shrink due to permission changes.
    _syncTabIndex(tabs);

    final safeIndex = _currentIndex >= tabs.length ? 0 : _currentIndex;

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
        backgroundColor: AppColors.scaffoldBg,
        drawer: const AppDrawer(),
        drawerEnableOpenDragGesture: true,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: tabs[safeIndex].page,
        ),
        bottomNavigationBar: QBBottomNavigation(
          activeIconBackground: isVisitor,
          currentIndex: safeIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            _syncSidebarSelection(tabs[index].label);
          },
          items: [
            for (final tab in tabs)
              QBNavItem(
                label: tab.label,
                icon: tab.icon,
                activeIcon: tab.activeIcon,
              ),
          ],
        ),
      ),
    );
  }
}
