import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
// intl is not a direct dependency — use built-in date formatting instead.
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/services/admin_marketing_service.dart';
import 'package:quickboom_app/shared/models/marketing_banner_model.dart';

// Simple date formatter using dart:core only (no intl package required).
String _fmtDate(DateTime d) {
  const months = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${d.day.toString().padLeft(2, '0')} ${months[d.month]} ${d.year}';
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN MARKETING BANNERS VIEW
// Allows admins to create / edit / deactivate / delete the Marketing Banners
// that power both the main promotional slider AND the coupon carousel on the
// Customer Home screen.
// ─────────────────────────────────────────────────────────────────────────────

class AdminMarketingBannersView extends ConsumerStatefulWidget {
  const AdminMarketingBannersView({super.key});

  @override
  ConsumerState<AdminMarketingBannersView> createState() =>
      _AdminMarketingBannersViewState();
}

class _AdminMarketingBannersViewState
    extends ConsumerState<AdminMarketingBannersView> {
  // Filter: 'all' | 'active' | 'inactive' | 'coupon'
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(adminMarketingBannersProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Marketing Banners',
              style: AppTypography.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Manage promotional banners & coupon offers',
              style: AppTypography.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Remix.refresh_line,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onPressed: () =>
                ref.read(adminMarketingBannersProvider.notifier).refresh(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Remix.add_line, size: 16),
              label: Text(
                'New',
                style: AppTypography.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter chips ───────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('all', 'All'),
                  _chip('active', 'Active'),
                  _chip('inactive', 'Inactive'),
                  _chip('coupon', 'Coupons'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: async.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
              error: (e, _) => _ErrorState(
                onRetry: () =>
                    ref.read(adminMarketingBannersProvider.notifier).refresh(),
              ),
              data: (banners) {
                final filtered = _applyFilter(banners);
                if (filtered.isEmpty) {
                  return _EmptyState(
                    filter: _filter,
                    onCreate: () => _openForm(context),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => ref
                      .read(adminMarketingBannersProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _BannerCard(
                      banner: filtered[i],
                      onEdit: () => _openForm(ctx, existing: filtered[i]),
                      onToggle: (v) => _toggle(ctx, filtered[i], v),
                      onDelete: () => _confirmDelete(ctx, filtered[i]),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<MarketingBannerModel> _applyFilter(List<MarketingBannerModel> banners) {
    switch (_filter) {
      case 'active':
        return banners.where((b) => b.isActive).toList();
      case 'inactive':
        return banners.where((b) => !b.isActive).toList();
      case 'coupon':
        return banners
            .where(
              (b) =>
                  b.couponCode?.isNotEmpty == true ||
                  b.discount?.isNotEmpty == true,
            )
            .toList();
      default:
        return banners;
    }
  }

  Widget _chip(String value, String label) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(
        label,
        style: AppTypography.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _filter == value ? Colors.white : AppColors.textSecondary,
        ),
      ),
      selected: _filter == value,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.pillBg,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) => setState(() => _filter = value),
    ),
  );

  Future<void> _toggle(
    BuildContext context,
    MarketingBannerModel b,
    bool isActive,
  ) async {
    final ok = await ref
        .read(adminMarketingBannersProvider.notifier)
        .toggleBanner(b.id, isActive: isActive);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? '${b.title ?? 'Banner'} ${isActive ? 'activated' : 'deactivated'}'
                : 'Update failed. Please try again.',
          ),
          backgroundColor: ok ? AppColors.primary : AppColors.error,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    MarketingBannerModel b,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Banner',
          style: AppTypography.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete "${b.title ?? 'this banner'}"? This action cannot be undone.',
          style: AppTypography.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: AppTypography.inter(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text('Delete', style: AppTypography.inter()),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref
        .read(adminMarketingBannersProvider.notifier)
        .deleteBanner(b.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Banner deleted.' : 'Delete failed.'),
          backgroundColor: ok ? AppColors.textPrimary : AppColors.error,
        ),
      );
    }
  }

  void _openForm(BuildContext context, {MarketingBannerModel? existing}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _BannerFormView(existing: existing)),
    ).then((_) {
      // Refresh list after returning from form
      ref.read(adminMarketingBannersProvider.notifier).refresh();
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BANNER CARD (list tile in admin)
// ─────────────────────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final MarketingBannerModel banner;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const _BannerCard({
    required this.banner,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasCoupon = banner.couponCode?.isNotEmpty == true;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 0),
            child: Row(
              children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: hasCoupon
                        ? const Color(0xFFFEF3C7)
                        : AppColors.pillBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasCoupon ? Remix.coupon_3_line : Remix.image_line,
                        size: 11,
                        color: hasCoupon
                            ? const Color(0xFFB45309)
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        hasCoupon ? 'COUPON' : 'BANNER',
                        style: AppTypography.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: hasCoupon
                              ? const Color(0xFFB45309)
                              : AppColors.textSecondary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Active toggle
                Transform.scale(
                  scale: 0.78,
                  child: Switch.adaptive(
                    value: banner.isActive,
                    onChanged: onToggle,
                    activeTrackColor: AppColors.primary,
                  ),
                ),
                // More actions
                PopupMenuButton<String>(
                  icon: const Icon(
                    Remix.more_2_fill,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Remix.edit_line, size: 16),
                          const SizedBox(width: 8),
                          Text('Edit', style: AppTypography.inter()),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(
                            Remix.delete_bin_line,
                            size: 16,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: AppTypography.inter(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Title + meta ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title ?? banner.discount ?? 'Untitled Banner',
                  style: AppTypography.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (banner.subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    banner.subtitle!,
                    style: AppTypography.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Coupon fields (shown only for coupon-type banners) ────────
          if (hasCoupon)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Row(
                children: [
                  if (banner.discount?.isNotEmpty == true)
                    _pill(
                      banner.discount!,
                      AppColors.primary,
                      AppColors.primaryLight,
                    ),
                  const SizedBox(width: 6),
                  _pill(
                    banner.couponCode!,
                    AppColors.textPrimary,
                    AppColors.pillBg,
                  ),
                ],
              ),
            ),

          // ── Dates + status ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
            child: Row(
              children: [
                Icon(Remix.calendar_line, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  _dateRange(banner.startAt, banner.endAt),
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  Remix.bar_chart_grouped_line,
                  size: 12,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 4),
                Text(
                  'Priority ${banner.priority}',
                  style: AppTypography.inter(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: banner.isActive
                        ? AppColors.subtleGreenBg
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    banner.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: AppTypography.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: banner.isActive
                          ? AppColors.primaryDark
                          : AppColors.error,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color fg, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: AppTypography.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: fg,
      ),
    ),
  );

  String _dateRange(DateTime? start, DateTime? end) {
    if (start == null && end == null) return 'Always active';
    if (start != null && end != null) {
      return '${_fmtDate(start)} – ${_fmtDate(end)}';
    }
    if (start != null) return 'From ${_fmtDate(start)}';
    return 'Until ${_fmtDate(end!)}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BANNER FORM VIEW (create / edit)
// ─────────────────────────────────────────────────────────────────────────────

class _BannerFormView extends ConsumerStatefulWidget {
  final MarketingBannerModel? existing;
  const _BannerFormView({this.existing});

  @override
  ConsumerState<_BannerFormView> createState() => _BannerFormViewState();
}

class _BannerFormViewState extends ConsumerState<_BannerFormView> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  // Controllers
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _description;
  late final TextEditingController _imageUrl;
  late final TextEditingController _ctaText;
  late final TextEditingController _ctaUrl;
  late final TextEditingController _couponCode;
  late final TextEditingController _discount;
  late final TextEditingController _brand;
  late final TextEditingController _category;
  late final TextEditingController _terms;
  late final TextEditingController _priority;
  late final TextEditingController _actionType;

  bool _isActive = true;
  bool _isPublished = true;
  DateTime? _startAt;
  DateTime? _endAt;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _subtitle = TextEditingController(text: e?.subtitle ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _imageUrl = TextEditingController(text: e?.imageUrl ?? '');
    _ctaText = TextEditingController(text: e?.ctaText ?? '');
    _ctaUrl = TextEditingController(text: e?.ctaUrl ?? '');
    _couponCode = TextEditingController(text: e?.couponCode ?? '');
    _discount = TextEditingController(text: e?.discount ?? '');
    _brand = TextEditingController(text: e?.brand ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _terms = TextEditingController(text: e?.terms ?? '');
    _priority = TextEditingController(text: (e?.priority ?? 0).toString());
    _actionType = TextEditingController(text: e?.actionType ?? '');
    _isActive = e?.isActive ?? true;
    _isPublished = e?.isPublished ?? true;
    _startAt = e?.startAt;
    _endAt = e?.endAt;
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _subtitle,
      _description,
      _imageUrl,
      _ctaText,
      _ctaUrl,
      _couponCode,
      _discount,
      _brand,
      _category,
      _terms,
      _priority,
      _actionType,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: Text(
          _isEdit ? 'Edit Banner' : 'New Banner',
          style: AppTypography.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _isEdit ? 'Save' : 'Create',
                      style: AppTypography.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Basic Info'),
            _field(_title, 'Title', hint: 'e.g. Glow Up Festival Offer'),
            _field(
              _subtitle,
              'Subtitle',
              hint: 'e.g. Top Cosmetics & Skincare Collections',
              required: false,
            ),
            _field(
              _description,
              'Description',
              hint: 'Short promotional copy',
              required: false,
              maxLines: 3,
            ),

            _section('Coupon / Offer Fields'),
            _field(
              _couponCode,
              'Coupon Code',
              hint: 'e.g. QBBPRO30',
              required: false,
            ),
            _field(
              _discount,
              'Discount Value',
              hint: 'e.g. 30% OFF or ₹500 OFF',
              required: false,
            ),
            _field(
              _brand,
              'Brand / Label',
              hint: 'e.g. PRO TIER or FWD',
              required: false,
            ),
            _field(
              _category,
              'Category',
              hint: 'e.g. Fashion',
              required: false,
            ),
            _field(
              _terms,
              'Terms & Conditions',
              hint: 'Min. purchase, eligibility etc.',
              required: false,
            ),

            _section('Banner Image'),
            _field(
              _imageUrl,
              'Image URL',
              hint: 'https://...',
              required: false,
            ),
            const SizedBox(height: 4),
            Text(
              'Paste a publicly accessible HTTPS image URL.',
              style: AppTypography.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),

            _section('Call-To-Action'),
            _field(
              _ctaText,
              'CTA Button Text',
              hint: 'e.g. Claim Reward',
              required: false,
            ),
            _field(
              _ctaUrl,
              'CTA URL / Route',
              hint: 'e.g. /plans or https://…',
              required: false,
            ),
            _field(
              _actionType,
              'Action Type',
              hint: 'OPEN_PLAN | OPEN_URL | OPEN_ORDERS | NONE',
              required: false,
            ),

            _section('Schedule & Priority'),
            _datePicker('Start Date (optional)', _startAt, (d) {
              setState(() => _startAt = d);
            }),
            const SizedBox(height: 10),
            _datePicker('Expiry Date (optional)', _endAt, (d) {
              setState(() => _endAt = d);
            }),
            const SizedBox(height: 10),
            _field(
              _priority,
              'Display Priority',
              hint: '0 = highest',
              keyboard: TextInputType.number,
              required: false,
            ),

            _section('Visibility'),
            _toggle('Active', _isActive, (v) {
              setState(() => _isActive = v);
            }),
            const SizedBox(height: 4),
            _toggle('Published', _isPublished, (v) {
              setState(() => _isPublished = v);
            }),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String label) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 8),
    child: Text(
      label,
      style: AppTypography.inter(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    bool required = true,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: AppTypography.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: AppTypography.inter(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTypography.inter(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
          : null,
    ),
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChange) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTypography.inter(fontSize: 14)),
            ),
            Switch.adaptive(
              value: value,
              onChanged: onChange,
              activeTrackColor: AppColors.primary,
            ),
          ],
        ),
      );

  Widget _datePicker(
    String label,
    DateTime? current,
    ValueChanged<DateTime?> onPick,
  ) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: current ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          builder: (ctx, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            const Icon(
              Remix.calendar_line,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                current != null ? _fmtDate(current) : label,
                style: AppTypography.inter(
                  fontSize: 14,
                  color: current != null
                      ? AppColors.textPrimary
                      : AppColors.textMuted,
                ),
              ),
            ),
            if (current != null)
              GestureDetector(
                onTap: () => onPick(null),
                child: const Icon(
                  Remix.close_circle_line,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'title': _title.text.trim().isEmpty ? null : _title.text.trim(),
      'subtitle': _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'imageUrl': _imageUrl.text.trim(),
      'ctaText': _ctaText.text.trim().isEmpty ? null : _ctaText.text.trim(),
      'ctaUrl': _ctaUrl.text.trim().isEmpty ? null : _ctaUrl.text.trim(),
      'couponCode': _couponCode.text.trim().isEmpty
          ? null
          : _couponCode.text.trim(),
      'discount': _discount.text.trim().isEmpty ? null : _discount.text.trim(),
      'brand': _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      'category': _category.text.trim().isEmpty ? null : _category.text.trim(),
      'terms': _terms.text.trim().isEmpty ? null : _terms.text.trim(),
      'actionType': _actionType.text.trim().isEmpty
          ? null
          : _actionType.text.trim().toUpperCase(),
      'priority': int.tryParse(_priority.text.trim()) ?? 0,
      'isActive': _isActive,
      'isPublished': _isPublished,
      'startAt': _startAt?.toIso8601String(),
      'endAt': _endAt?.toIso8601String(),
    };

    final notifier = ref.read(adminMarketingBannersProvider.notifier);
    final ok = _isEdit
        ? await notifier.updateBanner(widget.existing!.id, payload)
        : await notifier.create(payload);

    setState(() => _saving = false);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? 'Banner updated successfully.'
                : 'Banner created successfully.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save failed. Check your connection and try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY & ERROR STATES
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String filter;
  final VoidCallback onCreate;
  const _EmptyState({required this.filter, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final msg = filter == 'coupon'
        ? 'No coupon banners yet.'
        : filter == 'active'
        ? 'No active banners.'
        : 'No banners found.';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Remix.image_line, size: 48, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          Text(
            msg,
            style: AppTypography.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Remix.add_line, size: 16),
            label: Text(
              'Create Banner',
              style: AppTypography.inter(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Remix.error_warning_line,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 12),
          Text(
            'Failed to load banners',
            style: AppTypography.inter(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Retry',
              style: AppTypography.inter(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
