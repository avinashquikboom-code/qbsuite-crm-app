import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/widgets/qb_bottom_navigation.dart';
import 'package:quickboom_app/roles/employee/views/qb_home_view.dart';
import 'package:quickboom_app/shared/views/data_capture/qb_data_capture_view.dart';
import 'package:quickboom_app/shared/views/leads/qb_leads_view.dart';
import 'package:quickboom_app/roles/employee/views/sidebar_views/qb_customers_view.dart';
import 'package:quickboom_app/roles/employee/views/qb_profile_view.dart';

class QBDashboardView extends ConsumerStatefulWidget {
  const QBDashboardView({super.key});

  @override
  ConsumerState<QBDashboardView> createState() => _QBDashboardViewState();
}

class _QBDashboardViewState extends ConsumerState<QBDashboardView> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const QBHomeView(),
    const QBDataCaptureView(),
    const QBLeadsView(),
    const QBCustomersView(),
    const QBProfileView(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: QBBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
