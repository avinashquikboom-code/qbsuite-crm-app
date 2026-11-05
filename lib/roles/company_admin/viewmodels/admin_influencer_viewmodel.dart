import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/influencer_model.dart';

/// Admin influencer booking management notifier with live backend API sync
class AdminInfluencerBookingsNotifier
    extends Notifier<List<InfluencerBookingModel>> {
  @override
  List<InfluencerBookingModel> build() {
    _fetchFromBackend();
    return const [];
  }

  Future<void> _fetchFromBackend() async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.ensureAuthLoaded();
    try {
      final response = await apiClient.get('/admin/influencer-bookings');
      if (response.statusCode == 200 && response.data != null) {
        dynamic list = response.data;
        if (list is Map && list.containsKey('data')) {
          list = list['data'];
        }
        if (list is Map && list.containsKey('items')) {
          list = list['items'];
        }
        if (list is List) {
          state = list
              .whereType<Map>()
              .map(
                (m) => InfluencerBookingModel.fromJson(
                  Map<String, dynamic>.from(m),
                ),
              )
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[ADMIN_INFLUENCER_BOOKINGS_ERROR] $e');
    }
  }

  Future<void> refresh() async => _fetchFromBackend();

  Future<void> approveBooking(dynamic bookingId) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.ensureAuthLoaded();
    try {
      await apiClient.post('/admin/influencer-bookings/$bookingId/approve');
      await _fetchFromBackend();
    } catch (e) {
      debugPrint('[ADMIN_APPROVE_ERROR] $e');
      state = state
          .map(
            (b) => b.bookingId == bookingId.toString()
                ? b.copyWith(status: 'Confirmed')
                : b,
          )
          .toList();
    }
  }

  Future<void> rejectBooking(dynamic bookingId) async {
    final apiClient = ref.read(apiClientProvider);
    await apiClient.ensureAuthLoaded();
    try {
      await apiClient.post('/admin/influencer-bookings/$bookingId/reject');
      await _fetchFromBackend();
    } catch (e) {
      debugPrint('[ADMIN_REJECT_ERROR] $e');
      state = state
          .map(
            (b) => b.bookingId == bookingId.toString()
                ? b.copyWith(status: 'Cancelled')
                : b,
          )
          .toList();
    }
  }
}

final adminInfluencerBookingsProvider =
    NotifierProvider<
      AdminInfluencerBookingsNotifier,
      List<InfluencerBookingModel>
    >(AdminInfluencerBookingsNotifier.new);
