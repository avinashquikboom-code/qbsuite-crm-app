import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/shared/models/social_media_model.dart';

/// Reusable Social Media Profiles Card for Lead Details and Data Capture Details screens.
///
/// Displays connected social profiles (Instagram, Facebook, LinkedIn, X, YouTube, TikTok, etc.)
/// with corresponding brand icons, handles, clickable external links, and copy-to-clipboard.
/// Hides gracefully when no social profiles are present.
class SocialMediaProfilesCard extends StatelessWidget {
  final dynamic socialMedia;
  final String title;

  const SocialMediaProfilesCard({
    super.key,
    required this.socialMedia,
    this.title = 'Social Media Profiles',
  });

  Future<void> _openSocialLink(
    BuildContext context,
    SocialPlatformEntry entry,
  ) async {
    try {
      final uri = Uri.tryParse(entry.url);
      if (uri == null || !['http', 'https'].contains(uri.scheme)) {
        _showError(context, 'Invalid link for ${entry.platform}');
        return;
      }
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showError(context, 'Could not open ${entry.platform} profile');
      }
    } catch (_) {
      if (context.mounted) {
        _showError(context, 'Could not open ${entry.platform} link');
      }
    }
  }

  void _copyToClipboard(BuildContext context, SocialPlatformEntry entry) {
    Clipboard.setData(ClipboardData(text: entry.url));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${entry.platform} link to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showError(BuildContext context, String message) {
    try {
      AppToast.error(context, message);
    } catch (_) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = socialMedia is SocialMediaModel
        ? socialMedia as SocialMediaModel
        : SocialMediaModel.from(socialMedia);

    if (model == null || model.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = model.entries;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Remix.share_circle_line,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entries.length} ${entries.length == 1 ? 'profile' : 'profiles'}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...entries.asMap().entries.map((item) {
            final index = item.key;
            final entry = item.value;
            final isLast = index == entries.length - 1;

            return Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openSocialLink(context, entry),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: entry.brandColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              entry.icon,
                              size: 19,
                              color: entry.brandColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.platform,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  entry.handle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Remix.file_copy_line,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                            tooltip: 'Copy ${entry.platform} link',
                            onPressed: () => _copyToClipboard(context, entry),
                          ),
                          Icon(
                            Remix.external_link_line,
                            size: 18,
                            color: entry.brandColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  const Divider(height: 14, color: Color(0xFFF1F5F9)),
              ],
            );
          }),
        ],
      ),
    );
  }
}
