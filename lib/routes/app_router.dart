import 'package:flutter/material.dart';
import '../roles/employee/routes/employee_routes.dart';
import '../shared/views/auth/login_view.dart';
import 'route_names.dart';

/// Preserve notification navigator keys and role-specific native routes.
abstract final class AppRouter {
  static Map<String, WidgetBuilder> get routes => {
    ...EmployeeRoutes.getRoutes(),
    RouteNames.login: (_) => const LoginView(),
  };
}
