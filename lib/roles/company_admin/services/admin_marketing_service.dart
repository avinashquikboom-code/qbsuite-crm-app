import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/network/app_url.dart';
import 'package:quickboom_app/shared/models/marketing_banner_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN MARKETING SERVICE
// Manages Marketing Banners (promotional sliders + coupon strips) via the
// admin-scoped API. Reuses the existing [MarketingBannerModel] from the
// customer layer — no duplicate model needed.
// ─────────────────────────────────────────────────────────────────────────────

final adminMarketingServiceProvider = Provider<AdminMarketingService>((ref) {
  return AdminMarketingService(ref.watch(apiClientProvider));
});

class AdminMarketingService {
  final ApiClient _api;

  AdminMarketingService(this._api);

  // ── Admin banner endpoints ────────────────────────────────────────────────
  // Uses /admin/marketing/banners as defined in AppUrl
  static const _base = AppUrl.marketingBannersAdmin;

  /// Fetch all banners (active + inactive) for admin management.
  Future<List<MarketingBannerModel>> getAllBanners() async {
    await _api.ensureAuthLoaded();
    try {
      final resp = await _api.get(
        _base,
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      if (resp.statusCode == 200 && resp.data != null) {
        final raw = _extractList(resp.data);
        return raw
            .whereType<Map>()
            .map(
              (m) =>
                  MarketingBannerModel.fromJson(Map<String, dynamic>.from(m)),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[AdminMarketingService.getAllBanners] $e');
    }
    return const [];
  }

  /// Create a new banner.
  Future<bool> createBanner(Map<String, dynamic> payload) async {
    await _api.ensureAuthLoaded();
    try {
      final resp = await _api.post(_base, data: payload);
      return resp.statusCode == 200 || resp.statusCode == 201;
    } catch (e) {
      debugPrint('[AdminMarketingService.createBanner] $e');
      return false;
    }
  }

  /// Update an existing banner by [id].
  Future<bool> updateBanner(int id, Map<String, dynamic> payload) async {
    await _api.ensureAuthLoaded();
    try {
      final resp = await _api.patch('$_base/$id', data: payload);
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      debugPrint('[AdminMarketingService.updateBanner] $e');
      return false;
    }
  }

  /// Toggle active/inactive status.
  Future<bool> toggleActive(int id, {required bool isActive}) =>
      updateBanner(id, {'isActive': isActive});

  /// Delete a banner by [id].
  Future<bool> deleteBanner(int id) async {
    await _api.ensureAuthLoaded();
    try {
      final resp = await _api.delete('$_base/$id');
      return resp.statusCode == 200 || resp.statusCode == 204;
    } catch (e) {
      debugPrint('[AdminMarketingService.deleteBanner] $e');
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in ['data', 'items', 'banners', 'results']) {
        if (data[key] is List) return data[key] as List;
      }
    }
    return const [];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN MARKETING BANNERS NOTIFIER + PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

class AdminMarketingBannersNotifier
    extends AsyncNotifier<List<MarketingBannerModel>> {
  @override
  Future<List<MarketingBannerModel>> build() async {
    return ref.watch(adminMarketingServiceProvider).getAllBanners();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminMarketingServiceProvider).getAllBanners(),
    );
  }

  Future<bool> create(Map<String, dynamic> payload) async {
    final ok = await ref
        .read(adminMarketingServiceProvider)
        .createBanner(payload);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> updateBanner(int id, Map<String, dynamic> payload) async {
    final ok = await ref
        .read(adminMarketingServiceProvider)
        .updateBanner(id, payload);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> toggleBanner(int id, {required bool isActive}) async {
    final ok = await ref
        .read(adminMarketingServiceProvider)
        .toggleActive(id, isActive: isActive);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> deleteBanner(int id) async {
    final ok = await ref.read(adminMarketingServiceProvider).deleteBanner(id);
    if (ok) await refresh();
    return ok;
  }
}

final adminMarketingBannersProvider =
    AsyncNotifierProvider<
      AdminMarketingBannersNotifier,
      List<MarketingBannerModel>
    >(AdminMarketingBannersNotifier.new);
