import 'package:remixicon/remixicon.dart';
import 'data_capture_history_screen.dart';
import '../../services/data_capture_records_service.dart';
import 'data_capture_records_screen.dart';
import 'package:flutter/material.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/constants/app_bar_titles.dart';
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
            tooltip: 'Saved records',
            icon: const Icon(Remix.file_list_3_line),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DataCaptureRecordsScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Remix.refresh_line,
              color: AppColors.textPrimary,
            ),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Google Places Lead Capture',
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find Businesses & Prospects',
                      style: AppTypography.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find verified businesses and extract prospect leads directly into your CRM pipeline.',
                      style: AppTypography.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NewDataCaptureScreen(),
                            ),
                          );
                          if (result == true) {
                            _loadData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Start New Capture',
                          style: AppTypography.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _DataCaptureOption(
                icon: Remix.file_list_3_line,
                title: 'View Saved Data Capture Records',
                subtitle: 'Access your previously captured leads',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DataCaptureRecordsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _DataCaptureOption(
                icon: Remix.history_line,
                title: 'Capture History',
                subtitle: 'View all your capture activities',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DataCaptureHistoryScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (_usageError != null)
                Text(_usageError!, style: const TextStyle(color: Colors.red))
              else if (!_isLoading)
                CaptureUsageCard(usage: _usage),
              const SizedBox(height: 16),

              // Key Metrics (Total Captured, Extractions, Searches)
              if (_usageError == null) _buildMetricsSection(),
              const SizedBox(height: 14),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // On very compact screens (< 310px available width, e.g. 320px device width), use tighter padding and gap
        final isCompact = availableWidth < 310;
        final horizontalPadding = isCompact ? 8.0 : 10.0;
        final verticalPadding = isCompact ? 7.0 : 8.0;
        final gap = isCompact ? 6.0 : 8.0;
        final titleFontSize = isCompact ? 10.0 : 11.0;
        final valueFontSize = isCompact ? 15.0 : 16.0;

        if (_isLoading) {
          return Row(
            children: [
              Expanded(
                child: _buildMetricTileSkeleton(
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _buildMetricTileSkeleton(
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: _buildMetricTileSkeleton(
                  horizontalPadding: horizontalPadding,
                  verticalPadding: verticalPadding,
                ),
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                key: const ValueKey('metric_tile_total_captured'),
                title: 'Total Captured',
                value: '${_usage.totalLeadsCaptured}',
                icon: Remix.database_2_line,
                color: AppColors.primary,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                titleFontSize: titleFontSize,
                valueFontSize: valueFontSize,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _buildMetricTile(
                key: const ValueKey('metric_tile_extractions'),
                title: 'Successful',
                value: '${_usage.totalExtractions}',
                icon: Remix.check_double_line,
                color: AppColors.secondary,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                titleFontSize: titleFontSize,
                valueFontSize: valueFontSize,
              ),
            ),
            SizedBox(width: gap),
            Expanded(
              child: _buildMetricTile(
                key: const ValueKey('metric_tile_searches'),
                title: 'Total Searches',
                value: '${_usage.searches}',
                icon: Remix.search_line,
                color: AppColors.primary,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                titleFontSize: titleFontSize,
                valueFontSize: valueFontSize,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTileSkeleton({
    double horizontalPadding = 10,
    double verticalPadding = 8,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: const [
          SkeletonBox(width: 28, height: 28, borderRadius: 8),
          SizedBox(height: 5),
          SizedBox(
            height: 24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SkeletonBox(width: 48, height: 10, borderRadius: 4),
            ),
          ),
          SizedBox(height: 2),
          SkeletonBox(width: 30, height: 16, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    Key? key,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    double horizontalPadding = 10,
    double verticalPadding = 8,
    double titleFontSize = 11,
    double valueFontSize = 16,
  }) {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: Icon(icon, color: color, size: 16)),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 24,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.inter(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataCaptureOption extends StatelessWidget {
  const _DataCaptureOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Remix.arrow_right_s_line,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
