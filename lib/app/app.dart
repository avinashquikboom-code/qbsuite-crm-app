import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/models/user_role.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/auth_provider.dart';
import '../core/constants/app_config.dart';
import '../core/services/notification_service.dart';
import '../core/utils/app_toast.dart';
import '../shared/services/onboarding_service.dart';
import '../shared/views/splash_view.dart';
import '../shared/views/onboarding_view.dart';
import '../shared/views/auth/login_view.dart';
import '../roles/employee/views/dashboard_view.dart';
import '../roles/company_admin/views/company_admin_main_view.dart';
import '../roles/customer/views/customer_dashboard_view.dart';
import '../routes/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key, this.preferences});

  final SharedPreferences? preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.uiOnlyMode) {
      final loginState = ref.watch(loginStateProvider);
      final Widget targetHome;
      if (loginState.isInitializing) {
        targetHome = const SplashView();
      } else if (loginState.isLoggedIn && loginState.role != null) {
        switch (loginState.role!) {
          case UserRole.customer:
            targetHome = const CustomerDashboardView();
          case UserRole.employee:
            targetHome = const DashboardView();
          case UserRole.companyAdmin:
            targetHome = const CompanyAdminMainView();
        }
      } else {
        targetHome = const LoginView();
      }

      return MaterialApp(
        title: AppConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: targetHome,
        routes: AppRouter.routes,
      );
    }

    AppToast.navigatorKey = NotificationService.instance.navigatorKey;

    // Listen for authentication transitions to register/unregister FCM token safely
    ref.listen<LoginState>(loginStateProvider, (previous, next) {
      if (next.isLoggedIn && !(previous?.isLoggedIn ?? false)) {
        NotificationService.instance.registerTokenForAuthenticatedUser();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.instance.requestAndroidNotificationPermission();
        });
      } else if (!next.isLoggedIn && (previous?.isLoggedIn ?? false)) {
        NotificationService.instance.unregisterToken();
        NotificationService.instance.navigatorKey.currentState
            ?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginView()),
              (route) => false,
            );
      }
    });

    final loginState = ref.watch(loginStateProvider);
    if (loginState.isLoggedIn &&
        NotificationService.instance.cachedFcmToken != null) {
      // Idempotent: registers only if not yet registered for this session
      NotificationService.instance.registerTokenForAuthenticatedUser();
    }

    // Ensure system notification permission prompt is presented on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.requestAndroidNotificationPermission();
    });
    final bool onboardingDone =
        preferences?.getBool(OnboardingService.onboardingCompletedKey) ?? true;

    final Widget targetHome;
    if (loginState.isInitializing) {
      targetHome = const SplashView();
    } else if (loginState.hasStartupError && !loginState.isLoggedIn) {
      targetHome = SplashView(error: loginState.startupError);
    } else if (loginState.isLoggedIn && loginState.role != null) {
      final userRole = loginState.role!;

      debugPrint('SESSION RESTORE');
      debugPrint('Stored Role: ${loginState.userRole}');
      debugPrint('[NAVIGATION]');
      debugPrint('Resolved role: ${userRole.name}');

      switch (userRole) {
        case UserRole.customer:
          targetHome = const CustomerDashboardView();
          break;
        case UserRole.employee:
          debugPrint('Destination: EmployeeHome');
          targetHome = const DashboardView();
          break;
        case UserRole.companyAdmin:
          debugPrint('Destination: CompanyAdminHome');
          targetHome = const CompanyAdminMainView();
          break;
      }
      debugPrint('[STARTUP] Router initialization completed');
      debugPrint('[STARTUP] navigating to Login/Home');
      debugPrint('[STARTUP] Navigating to Home');
    } else {
      targetHome = !onboardingDone ? const OnboardingView() : const LoginView();
      debugPrint('[STARTUP] Router initialization completed');
      debugPrint('[STARTUP] navigating to Login');
      debugPrint('[STARTUP] Navigating to Login');
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        navigatorKey: NotificationService.instance.navigatorKey,
        scaffoldMessengerKey: NotificationService.instance.messengerKey,
        title: 'QB Suite',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: targetHome,
        routes: AppRouter.routes,
      ),
    );
  }
}
