import 'package:quickboom_app/core/icons/remix_icon.dart';
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
            icon: const Icon(LegacyRemixIcons.listAlt),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DataCaptureRecordsScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              LegacyRemixIcons.refreshRounded,
              color: AppColors.textSecondary,
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
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF0F3822),
                      Color(0xFF14532D),
                      Color(0xFF0F172A),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryDark.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            'GOOGLE PLACES LEAD CAPTURE',
                            style: AppTypography.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryLight,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Icon(
                          LegacyRemixIcons.travelExploreRounded,
                          color: AppColors.primaryLight,
                          size: 26,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Find Businesses & Prospects',
                      style: AppTypography.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find verified businesses and extract prospective leads directly from Google Places into your CRM pipeline.',
                      style: AppTypography.inter(
                        fontSize: 13,
                        color: Colors.white70,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
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
                        icon: const Icon(
                          LegacyRemixIcons.searchRounded,
                          size: 20,
                        ),
                        label: Text(
                          'Start New Capture',
                          style: AppTypography.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
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
              ),
              const SizedBox(height: 20),

              // Subscription Usage Card
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DataCaptureRecordsScreen(),
                  ),
                ),
                icon: const Icon(LegacyRemixIcons.listAlt),
                label: const Text('View saved Data Capture records'),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: const Icon(
                    LegacyRemixIcons.historyRounded,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    'Capture History',
                    style: AppTypography.inter(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'View your previous business searches and captures',
                  ),
                  trailing: const Icon(
                    LegacyRemixIcons.chevronRight,
                    color: AppColors.primary,
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DataCaptureHistoryScreen(),
                    ),
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
                icon: LegacyRemixIcons.groupsRounded,
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
                title: 'Extractions',
                value: '${_usage.totalExtractions}',
                icon: LegacyRemixIcons.historyEduRounded,
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
                title: 'Searches',
                value: '${_usage.searches}',
                icon: LegacyRemixIcons.searchRounded,
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
