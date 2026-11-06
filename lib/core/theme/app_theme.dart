import '../icons/remix_icon.dart';
import 'package:flutter/material.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => lightTheme;
  // Legacy color getters forwarding to AppColors
  static Color get primaryColor => AppColors.primary;
  static Color get darkGreen => AppColors.primaryDark;
  static Color get lightGreen => AppColors.primaryLight;
  static Color get accentColor => AppColors.accent;
  static Color get successColor => AppColors.success;
  static Color get successBadge => AppColors.successBadge;
  static Color get successText => AppColors.successText;
  static Color get warningColor => AppColors.warning;
  static Color get errorColor => AppColors.error;
  static Color get sidebarBg => AppColors.sidebarBg;
  static Color get mainBg => AppColors.mainBg;
  static Color get dashboardBg => AppColors.dashboardBg;
  static Color get cardBg => AppColors.cardBg;
  static Color get textPrimary => AppColors.textPrimary;
  static Color get textSecondary => AppColors.textSecondary;
  static Color get borderSide => AppColors.border;

  static const buttonRadius = 8.0;
  static const controlPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  static ThemeData get lightTheme {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.textPrimary,
          primaryContainer: AppColors.lightPrimary,
          onPrimaryContainer: AppColors.textPrimary,
          secondary: AppColors.primary,
          onSecondary: AppColors.textPrimary,
          secondaryContainer: AppColors.lightPrimary,
          onSecondaryContainer: AppColors.textPrimary,
          tertiary: AppColors.darkPrimary,
          onTertiary: AppColors.surface,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
          onSurfaceVariant: AppColors.textSecondary,
          outline: AppColors.border,
          outlineVariant: AppColors.border,
          surfaceTint: Colors.transparent,
          error: AppColors.danger,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    );
    final buttonStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return AppColors.border;
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered)) {
          return AppColors.darkPrimary;
        }
        return AppColors.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? AppColors.textSecondary
            : AppColors.textPrimary,
      ),
      padding: const WidgetStatePropertyAll(controlPadding),
      shape: WidgetStatePropertyAll(shape),
      minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
      textStyle: const WidgetStatePropertyAll(
        TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
    );
    return ThemeData(
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const RemixIcon(AppIcon.back),
        closeButtonIconBuilder: (_) => const RemixIcon(AppIcon.close),
        drawerButtonIconBuilder: (_) => const RemixIcon(AppIcon.menu),
        endDrawerButtonIconBuilder: (_) => const RemixIcon(AppIcon.menu),
      ),
      useMaterial3: true,
      colorScheme: scheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
      filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          side: const BorderSide(color: AppColors.border),
          shape: shape,
          padding: controlPadding,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          shape: shape,
          padding: controlPadding,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: shape,
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: controlPadding,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : Colors.transparent,
        ),
        checkColor: const WidgetStatePropertyAll(AppColors.textPrimary),
        side: const BorderSide(color: AppColors.border),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.textSecondary,
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.border,
        ),
        thumbColor: const WidgetStatePropertyAll(AppColors.surface),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.lightPrimary,
        circularTrackColor: AppColors.lightPrimary,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.darkPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.primary,
        labelStyle: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.lightPrimary,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.lightPrimary,
        selectedIconTheme: IconThemeData(color: AppColors.primary),
        unselectedIconTheme: IconThemeData(color: AppColors.textSecondary),
        selectedLabelTextStyle: TextStyle(
          color: AppColors.darkPrimary,
          fontFamily: 'Inter',
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
      ),
      listTileTheme: const ListTileThemeData(
        selectedColor: AppColors.darkPrimary,
        selectedTileColor: AppColors.lightPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'Inter',
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (_) => const RemixIcon(AppIcon.back),
        closeButtonIconBuilder: (_) => const RemixIcon(AppIcon.close),
        drawerButtonIconBuilder: (_) => const RemixIcon(AppIcon.menu),
        endDrawerButtonIconBuilder: (_) => const RemixIcon(AppIcon.menu),
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primaryDark,
        secondary: AppColors.primary,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        outline: AppColors.borderDark,
        error: AppColors.error,
        brightness: Brightness.dark,
      ),
      textTheme: AppTypography.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
        titleTextStyle: AppTypography.inter(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTypography.inter(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderDark, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryDark,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: AppTypography.inter(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: AppColors.primary,
        disabledActionTextColor: Colors.white.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
