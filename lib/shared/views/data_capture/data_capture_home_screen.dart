import 'package:remixicon/remixicon.dart';
import 'data_capture_history_screen.dart';
import '../../services/data_capture_records_service.dart';
import 'data_capture_records_screen.dart';
import 'package:flutter/material.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/constants/app_bar_titles.dart';
import 'package:quickboom_app/core/widgets/responsive/responsive.dart';
import 'package:quickboom_app/shared/models/data_capture_model.dart';
import 'package:quickboom_app/shared/services/data_capture_service.dart';
import 'package:quickboom_app/shared/widgets/app_app_bar.dart';
import 'package:quickboom_app/shared/widgets/data_capture/capture_usage_card.dart';
import 'package:quickboom_app/shared/widgets/skeleton_loader.dart';
import 'new_data_capture_screen.dart';

class DataCaptureHomeScreen extends StatefulWidget {
  const DataCaptureHomeScreen({super.key});

  @override
  State<DataCaptureHomeScreen> createState() => _DataCaptureHomeScreenState();
}

class _DataCaptureHomeScreenState extends State<DataCaptureHomeScreen> {
  final DataCaptureService _service = DataCaptureService();
  DataCaptureUsage _usage = DataCaptureUsage.initial();
  bool _isLoading = true;
  String? _usageError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _usageError = null;
    });
    try {
      final usage = await _service.getUsageSummary();
      if (mounted) {
        setState(() {
          _usage = usage;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _usageError = dataCaptureError(error);
        });
      }
    }
  }

  Future<void> _openNewCapture() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewDataCaptureScreen()),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _openSavedRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DataCaptureRecordsScreen()),
    );
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DataCaptureHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: AppBarTitles.dataCapture,
        showBackButton: false,
        showDrawerButton: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(
              Remix.refresh_line,
              color: AppColors.textPrimary,
            ),
            onPressed: _loadData,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: ResponsiveContainer(
              maxWidth: 640,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CaptureHeroCard(onStartCapture: _openNewCapture),
                    const SizedBox(height: 16),
                    _SavedRecordsPill(onTap: _openSavedRecords),
                    const SizedBox(height: 18),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppColors.border,
                    ),
                    const SizedBox(height: 4),
                    _CaptureHistoryRow(onTap: _openHistory),
                    const SizedBox(height: 16),
                    if (_usageError != null)
                      _UsageErrorCard(
                        message: _usageError!,
                        onRetry: _loadData,
                      )
                    else
                      _isLoading
                          ? const _UsageCardSkeleton()
                          : CaptureUsageCard(usage: _usage),
                    const SizedBox(height: 16),
                    if (_usageError == null)
                      _buildMetricsSection(isLoading: _isLoading),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsSection({required bool isLoading}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final isCompact = availableWidth < 320;
        final gap = isCompact ? 6.0 : 8.0;
        final horizontalPadding = isCompact ? 8.0 : 10.0;
        final verticalPadding = isCompact ? 12.0 : 14.0;
        final labelFontSize = isCompact ? 10.0 : 11.0;
        final valueFontSize = isCompact ? 17.0 : 19.0;

        Widget tile({
          Key? key,
          required String title,
          required String value,
        }) {
          return Expanded(
            child: Container(
              key: key,
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: AppTypography.inter(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTypography.inter(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        Widget skeletonTile() {
          return Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeletonBox(width: 42, height: 18, borderRadius: 4),
                  SizedBox(height: 5),
                  SkeletonBox(width: 56, height: 10, borderRadius: 4),
                ],
              ),
            ),
          );
        }

        if (isLoading) {
          return Row(
            children: [
              skeletonTile(),
              SizedBox(width: gap),
              skeletonTile(),
              SizedBox(width: gap),
              skeletonTile(),
            ],
          );
        }

        return Row(
          children: [
            tile(
              key: const ValueKey('metric_tile_total_captured'),
              title: 'Total Captured',
              value: '${_usage.totalLeadsCaptured}',
            ),
            SizedBox(width: gap),
            tile(
              key: const ValueKey('metric_tile_extractions'),
              title: 'Extractions',
              value: '${_usage.totalExtractions}',
            ),
            SizedBox(width: gap),
            tile(
              key: const ValueKey('metric_tile_searches'),
              title: 'Searches',
              value: '${_usage.searches}',
            ),
          ],
        );
      },
    );
  }
}

/// Dark green hero banner with the Google Places lead capture call to action.
class _CaptureHeroCard extends StatelessWidget {
  const _CaptureHeroCard({required this.onStartCapture});

  final VoidCallback onStartCapture;

  @override
  Widget build(BuildContext context) {
    final isCompact = AppBreakpoints.isCompact(context);
    final radius = BorderRadius.circular(22);
    final buttonHeight = isCompact ? 46.0 : 50.0;

    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A3324), Color(0xFF125C3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.22),
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Google Places Lead Capture',
                        maxLines: 1,
                        style: AppTypography.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD8FBE0),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Remix.search_line,
                  size: 18,
                  color: Color(0xFFD8FBE0),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 14 : 16),
          Text(
            'Find Businesses & Prospects',
            style: AppTypography.inter(
              fontSize: isCompact ? 19 : 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Find verified businesses and extract prospective leads directly from Google Places into your CRM pipeline.',
            style: AppTypography.inter(
              fontSize: isCompact ? 12 : 13,
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.4,
            ),
          ),
          SizedBox(height: isCompact ? 16 : 20),
          SizedBox(
            width: double.infinity,
            height: buttonHeight,
            child: ElevatedButton.icon(
              onPressed: onStartCapture,
              icon: const Icon(Remix.search_line, size: 18),
              label: Text(
                'Start New Capture',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: isCompact ? 14 : 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact shortcut to the saved Data Capture records list.
class _SavedRecordsPill extends StatelessWidget {
  const _SavedRecordsPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.white,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Remix.file_list_3_line,
                  size: 17,
                  color: AppColors.primaryDark,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'View saved Data Capture records',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
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

/// Row that links to the capture history screen.
class _CaptureHistoryRow extends StatelessWidget {
  const _CaptureHistoryRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Remix.history_line,
                  size: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Capture History',
                      style: AppTypography.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View your previous business searches and captures',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Remix.arrow_right_s_line,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsageCardSkeleton extends StatelessWidget {
  const _UsageCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 36, height: 36, borderRadius: 18),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 120, height: 9, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 150, height: 14, borderRadius: 4),
                  ],
                ),
              ),
              SkeletonBox(width: 78, height: 22, borderRadius: 8),
            ],
          ),
          SizedBox(height: 18),
          SkeletonBox(width: double.infinity, height: 8, borderRadius: 4),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 100, height: 10, borderRadius: 4),
              SkeletonBox(width: 90, height: 10, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

class _UsageErrorCard extends StatelessWidget {
  const _UsageErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Remix.error_warning_line, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.inter(
                fontSize: 12.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 40),
            ),
            child: Text(
              'Retry',
              style: AppTypography.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
