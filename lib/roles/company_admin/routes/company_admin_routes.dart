import '../views/customers/admin_customers_view.dart';
import 'package:flutter/material.dart';
import '../views/views.dart';

/// Centralized route definitions for Company Admin workspace.
class CompanyAdminRoutes {
  CompanyAdminRoutes._();

  static const String main = '/admin/main';
  static const String home = '/admin/home';
  static const String clients = '/admin/clients';
  static const String trending = '/admin/trending';
  static const String calendar = '/admin/calendar';
  static const String more = '/admin/more';
  static const String workTypes = '/admin/work-types';
  static const String teamMembers = '/admin/team-members';
  static const String work = '/admin/work';
  static const String influencerBookings = '/admin/influencer-bookings';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      main: (_) => const CompanyAdminMainView(),
      home: (_) => const AdminHomeTab(),
      clients: (_) => const AdminCustomersView(),

      trending: (_) => const AdminTrendingView(),

      more: (_) => const AdminMoreTab(),
      workTypes: (_) => const AdminWorkTypesView(),
      teamMembers: (_) => const AdminTeamMembersView(),
      work: (_) => const AdminWorkTab(),
      influencerBookings: (_) => const AdminInfluencerBookingManagementView(),
    };
  }
}
