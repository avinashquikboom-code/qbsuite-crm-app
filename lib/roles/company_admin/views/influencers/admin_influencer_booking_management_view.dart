import 'package:quickboom_app/core/utils/app_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/influencer_model.dart';
import '../../viewmodels/admin_influencer_viewmodel.dart';

/// Screen 8 — Admin Influencer Booking Management View
/// Visual source of truth: Screen 8 of reference_screens.jpeg
class AdminInfluencerBookingManagementView extends ConsumerStatefulWidget {
  const AdminInfluencerBookingManagementView({super.key});

  @override
  ConsumerState<AdminInfluencerBookingManagementView> createState() =>
      _AdminInfluencerBookingManagementViewState();
}

class _AdminInfluencerBookingManagementViewState
    extends ConsumerState<AdminInfluencerBookingManagementView> {
  int _selectedTabIndex =
      0; // 0: Bookings, 1: Influencers, 2: Payments, 3: Reports
  final List<String> _tabs = ['Bookings', 'Influencers', 'Payments', 'Reports'];

  void _showActionDialog(BuildContext context, InfluencerBookingModel booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          booking.influencerName,
          style: AppTypography.inter(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking ID: ${booking.bookingId}',
              style: AppTypography.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Package: ${booking.packageName}',
              style: AppTypography.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Date: ${booking.campaignDate}',
              style: AppTypography.inter(fontSize: 13),
            ),
            Text(
              'Client: ${booking.brandName} (${booking.contactPerson})',
              style: AppTypography.inter(fontSize: 13),
            ),
            Text(
              'Amount: ${AppCurrency.format(booking.totalAmount)}',
              style: AppTypography.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Status: ${booking.status}',
              style: AppTypography.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref
                  .read(adminInfluencerBookingsProvider.notifier)
                  .rejectBooking(booking.bookingId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Booking ${booking.bookingId} rejected/cancelled.',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            child: Text(
              'Reject',
              style: AppTypography.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              ref
                  .read(adminInfluencerBookingsProvider.notifier)
                  .approveBooking(booking.bookingId);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Booking ${booking.bookingId} approved!'),
                  backgroundColor: AppColors.primaryDark,
                ),
              );
            },
            child: Text(
              'Approve',
              style: AppTypography.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(adminInfluencerBookingsProvider);

    final totalBookingsCount = bookings.length;
    final pendingCount = bookings
        .where((b) => b.status.toLowerCase() == 'pending')
        .length;
    final double revenueTotal = bookings.fold<double>(
      0.0,
      (sum, b) =>
          sum +
          (b.paymentStatus?.toUpperCase() == 'PAID' ? b.totalAmount : 0.0),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          'Admin Panel',
          style: AppTypography.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter Tabs (Bookings, Influencers, Payments, Reports)
          _buildPillTabs(),

          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Cards Row (Total Bookings, Pending Approval, Total Revenue)
                  Row(
                    children: [
                      _buildKpiCard('Total Bookings', '$totalBookingsCount'),
                      const SizedBox(width: 10),
                      _buildKpiCard('Pending Approval', '$pendingCount'),
                      const SizedBox(width: 10),
                      _buildKpiCard(
                        'Total Revenue',
                        AppCurrency.format(revenueTotal),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Recent Bookings Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Bookings',
                        style: AppTypography.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'View All >',
                        style: AppTypography.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (bookings.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Text(
                          'No influencer bookings found',
                          style: AppTypography.inter(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  else
                    ...List.generate(bookings.length, (idx) {
                      final booking = bookings[idx];
                      return _buildAdminBookingItem(context, booking);
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(_tabs.length, (idx) {
          final isSelected = _selectedTabIndex == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = idx),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryDark
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    _tabs[idx],
                    style: AppTypography.inter(
                      fontSize: 11.5,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 10.5,
                color: AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: AppTypography.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminBookingItem(
    BuildContext context,
    InfluencerBookingModel booking,
  ) {
    final bool isConfirmed = booking.status.toLowerCase() == 'confirmed';
    final bool isPending = booking.status.toLowerCase() == 'pending';

    final Color badgeBg = isConfirmed
        ? const Color(0xFFECFDF5)
        : (isPending ? const Color(0xFFFFF7ED) : const Color(0xFFFEF2F2));
    final Color badgeText = isConfirmed
        ? const Color(0xFF059669)
        : (isPending ? const Color(0xFFEA580C) : const Color(0xFFDC2626));

    return InkWell(
      onTap: () => _showActionDialog(context, booking),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: booking.influencerImage.isNotEmpty
                  ? Image.network(
                      booking.influencerImage,
                      width: 46,
                      height: 46,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => Container(
                        width: 46,
                        height: 46,
                        color: const Color(0xFFE2E8F0),
                        child: const Icon(
                          Remix.user_3_line,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    )
                  : Container(
                      width: 46,
                      height: 46,
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(
                        Remix.user_3_line,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Middle info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.influencerName,
                    style: AppTypography.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.packageName,
                    style: AppTypography.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    booking.campaignDate,
                    style: AppTypography.inter(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                booking.status,
                style: AppTypography.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: badgeText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
