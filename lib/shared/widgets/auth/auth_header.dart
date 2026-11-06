import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';

class AuthHeader extends StatelessWidget {
  final String portalSubtitle;

  const AuthHeader({
    super.key,
    this.portalSubtitle = 'EMPLOYEE WORKFORCE PORTAL',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App Logo
        SizedBox(
          height: 68,
          child: Image.asset(
            'assets/images/app_logo_brand.png',
            fit: BoxFit.contain,
            semanticLabel: 'QB Suite logo',
            errorBuilder: (context, error, stackTrace) => Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF5EC269),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Remix.flashlight_fill,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 10),

        // Portal Subtitle with Green Lines
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 1.5,
              color: const Color(0xFF5EC269).withValues(alpha: 0.6),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                portalSubtitle,
                style: AppTypography.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF667085),
                  letterSpacing: 1.6,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 1.5,
              color: const Color(0xFF5EC269).withValues(alpha: 0.6),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Title
        Text(
          'Login to Your Account',
          style: AppTypography.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D2939),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose your login type to continue',
          style: AppTypography.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}
