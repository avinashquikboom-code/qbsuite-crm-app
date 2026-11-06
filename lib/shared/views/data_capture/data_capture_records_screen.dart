import 'package:quickboom_app/core/icons/remix_icon.dart';
import 'dart:async';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import '../../../core/services/permission_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../models/data_capture_record.dart';
import '../../services/data_capture_records_service.dart';
import '../../../core/network/api_client.dart';
import '../../viewmodels/leads_viewmodel.dart';
import '../../viewmodels/lead_stages_viewmodel.dart';
import '../../widgets/social_media_profiles_card.dart';
import '../leads/leads_view.dart';
import '../../../core/utils/app_snack_bar.dart';

class DataCaptureRecordsScreen extends ConsumerStatefulWidget {
  final String? jobId;
  final bool fromHistory;
  const DataCaptureRecordsScreen({
    super.key,
    this.jobId,
    this.fromHistory = false,
  });
  @override
  ConsumerState<DataCaptureRecordsScreen> createState() => _RecordsState();
}

class _RecordsState extends ConsumerState<DataCaptureRecordsScreen> {
  late final DataCaptureRecordsService _service;
  final _search = TextEditingController();
  Timer? _debounce;
  DataCapturePage? _data;
  String? _error;
  final String _status = 'ALL', _source = 'ALL';
  bool _loading = true;
  int _generation = 0;
  bool _importing = false, _confirmingImport = false;
  final Map<int, String> _selected = {};

  void _toggleRecord(DataCaptureRecord record) {
    if (_importing) return;
    setState(() {
      if (_selected.containsKey(record.id)) {
        _selected.remove(record.id);
      } else {
        _selected[record.id] = record.businessName;
      }
    });
  }

  Future<void> _importSelected() async {
    if (_importing ||
        _confirmingImport ||
        _selected.isEmpty ||
        !ref.read(permissionManagerProvider).canEdit('DATA_CAPTURE')) {
      return;
    }
    _confirmingImport = true;
    final selected = Map<int, String>.from(_selected);
    Object? importError;
    Map<String, dynamic>? result;
    var submitting = false;
    try {
      result = await showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, updateDialog) {
            return PopScope(
              canPop: !submitting,
              child: AlertDialog(
                title: Text(
                  selected.length == 1
                      ? 'Import to Leads?'
                      : 'Import ${selected.length} records?',
                ),
                content: Text(
                  selected.length == 1
                      ? 'Import "${selected.values.first.isNotEmpty ? selected.values.first : 'this business'}" into Leads?\n\nOnly validated records can be imported.'
                      : 'Import the ${selected.length} selected businesses into Leads?\n\nOnly validated records can be imported. Other records will remain selected.',
                ),
                actions: [
                  TextButton(
                    onPressed: submitting ? null : () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: submitting
                        ? null
                        : () async {
                            if (submitting ||
                                !ref
                                    .read(permissionManagerProvider)
                                    .canEdit('DATA_CAPTURE'))
                              return;
                            updateDialog(() => submitting = true);
                            setState(() => _importing = true);
                            try {
                              for (final id in selected.keys) {
                                final record = _data?.records
                                    .where((r) => r.id == id)
                                    .firstOrNull;
                                if (record != null &&
                                    record.status != 'VALIDATED' &&
                                    record.fields['isImported'] != true) {
                                  await _service.status(id, 'validate');
                                }
                              }
                              final response = await _service.importSelected(
                                selected.keys.toList(),
                              );
                              if (ctx.mounted) Navigator.pop(ctx, response);
                            } catch (error) {
                              importError = error;
                              if (ctx.mounted) Navigator.pop(ctx);
                            }
                          },
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            selected.length == 1
                                ? 'Import Record'
                                : 'Import Records',
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } finally {
      _confirmingImport = false;
      if (mounted) setState(() => _importing = false);
    }
    if (!mounted) return;
    if (importError != null) {
      AppSnackBar.showError(context, dataCaptureError(importError!));
      return;
    }
    final outcome = result;
    if (outcome == null) return;
    try {
      debugPrint('[DATA_CAPTURE_IMPORT_UI] flow=list result=parsed');
      final imported = outcome['importedCount'] as int;
      final duplicates = outcome['alreadyImportedCount'] as int;
      final skipped = outcome['skippedCount'] as int;
      final failed = outcome['failedCount'] as int;
      final unsuccessful = [
        ...outcome['skipped'] as List,
        ...outcome['failed'] as List,
      ];
      setState(() {
        for (final record in [
          ...outcome['imported'] as List,
          ...outcome['alreadyImported'] as List,
        ]) {
          _selected.remove(int.parse(record['captureId'].toString()));
        }
      });
      if (imported > 0 || duplicates > 0) {
        ref.invalidate(leadsProvider);
        ref.invalidate(leadStagesProvider);
      }
      if (!mounted) return;
      setState(() => _importing = false);
      if ((imported > 0 || duplicates > 0) &&
          (ref.read(permissionManagerProvider).canViewLeads ||
              ref.read(permissionManagerProvider).isCrmEligible)) {
        final successMsg = imported > 0
            ? '$imported ${imported == 1 ? 'record' : 'records'} imported successfully!${unsuccessful.isEmpty ? '' : ' $failed failed, $skipped skipped. ${unsuccessful.map((r) => r['reason']).join('; ')}'}'
            : 'Selected businesses are already in Leads.';
        AppSnackBar.showSuccess(context, successMsg);
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LeadsView()));
        if (mounted) await _load(_data?.page ?? 1);
        return;
      }
      await _load(_data?.page ?? 1);
      if (!mounted) return;
      final viewLeads = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            imported > 0 || duplicates > 0
                ? 'Import Completed'
                : 'Import not completed',
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$imported imported successfully'),
                  if (duplicates > 0) Text('$duplicates already in Leads'),
                  if (skipped > 0) Text('$skipped skipped'),
                  if (failed > 0) Text('$failed failed'),
                  if (unsuccessful.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Unsuccessful records remain selected for retry.',
                    ),
                    ...unsuccessful.map((record) {
                      final id = int.parse(record['captureId'].toString());
                      final name = selected[id];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${name?.isNotEmpty == true ? name : 'Record #$id'}: ${record['reason'] ?? 'Import was not completed'}',
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Close'),
            ),
            if ((imported > 0 || duplicates > 0) &&
                (ref.read(permissionManagerProvider).canViewLeads ||
                    ref.read(permissionManagerProvider).isCrmEligible))
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('View Leads'),
              ),
          ],
        ),
      );
      if (viewLeads == true && mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const LeadsView()));
      }
    } catch (error) {
      debugPrint(
        '[DATA_CAPTURE_UI_ERROR] type=${error.runtimeType} mounted=$mounted',
      );
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        error is FormatException
            ? 'Unable to read the import result. Selection kept; refresh records before retrying.'
            : dataCaptureError(error),
      );
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _service = DataCaptureRecordsService(ref.read(apiClientProvider));
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load([int page = 1]) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.list(
        page: page,
        search: _search.text.trim(),
        status: _status,
        source: _source,
        jobId: widget.jobId,
        fromHistory: widget.fromHistory,
      );
      if (mounted && generation == _generation) setState(() => _data = data);
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = dataCaptureError(e));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _open(DataCaptureRecord? record, {bool edit = false}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DataCaptureRecordScreen(record: record, editing: edit),
      ),
    );
    if (changed == true && mounted) await _load();
  }

  void _copyPhone(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    AppSnackBar.showSuccess(context, 'Phone number copied: $phone');
  }

  String _formatFilterLabel(String val) {
    switch (val) {
      case 'ALL':
        return 'All';
      case 'CAPTURED':
        return 'Captured';
      case 'VALIDATED':
        return 'Validated';
      case 'REJECTED':
        return 'Rejected';
      case 'DUPLICATE':
        return 'Duplicate';
      case 'LEAD_CREATED':
        return 'Lead Created';
      case 'LEAD_IMPORTED':
        return 'Lead Imported';
      case 'MANUAL':
        return 'Manual';
      case 'GOOGLE_PLACES':
        return 'Google Places';
      default:
        return val;
    }
  }

  String _formatDate(dynamic rawDate) {
    if (rawDate == null) return '';
    DateTime? dt;
    if (rawDate is DateTime) {
      dt = rawDate;
    } else {
      dt = DateTime.tryParse(rawDate.toString());
    }
    if (dt == null) return rawDate.toString();
    final local = dt.toLocal();
    const months = [
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
    final month = months[local.month - 1];
    final hour = local.hour == 0
        ? 12
        : (local.hour > 12 ? local.hour - 12 : local.hour);
    final period = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '$month ${local.day}, ${local.year} • ${hour.toString().padLeft(2, '0')}:$min $period';
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    Color border;

    final upper = status.toUpperCase();
    switch (upper) {
      case 'CAPTURED':
      case 'VALIDATED':
      case 'LEAD_CREATED':
      case 'LEAD_IMPORTED':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF166534);
        border = const Color(0xFFBBF7D0);
        break;
      case 'REJECTED':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFF991B1B);
        border = const Color(0xFFFECACA);
        break;
      case 'DUPLICATE':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFF92400E);
        border = const Color(0xFFFDE68A);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF475569);
        border = const Color(0xFFE2E8F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Text(
        _formatFilterLabel(upper),
        style: AppTypography.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildPhotoOrIcon(String? photoUrl) {
    if (photoUrl != null && photoUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          photoUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _defaultBuildingIcon(),
        ),
      );
    }
    return _defaultBuildingIcon();
  }

  Widget _defaultBuildingIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 0.8),
      ),
      child: const Center(
        child: Icon(
          LegacyRemixIcons.businessRounded,
          size: 22,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildRecordCard(DataCaptureRecord record) {
    final address =
        record.fields['address']?.toString() ?? record.business.address;
    final phone = record.fields['phone']?.toString() ?? record.business.phone;
    final hasAddress = address.trim().isNotEmpty && address != 'N/A';
    final hasPhone = phone.trim().isNotEmpty && phone != 'N/A';
    final capturedAt =
        record.fields['capturedAt'] ??
        record.fields['createdAt'] ??
        record.business.capturedAt;
    final formattedDate = _formatDate(capturedAt);

    final isSelected = _selected.containsKey(record.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _importing ? null : () => _open(record),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPhotoOrIcon(record.business.primaryPhotoUrl),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.businessName.isNotEmpty
                                ? record.businessName
                                : 'Unnamed Business',
                            style: AppTypography.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF111827),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          _buildStatusBadge(record.status),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      semanticLabel: 'Select ${record.businessName}',
                      onChanged: _importing
                          ? null
                          : (_) => _toggleRecord(record),
                    ),
                  ],
                ),
                if (hasAddress || hasPhone || formattedDate.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 10),
                ],
                if (hasAddress)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            LegacyRemixIcons.locationOnOutlined,
                            size: 15,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address,
                            style: AppTypography.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hasPhone)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        const Icon(
                          LegacyRemixIcons.phoneOutlined,
                          size: 15,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            phone,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => _copyPhone(phone),
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LegacyRemixIcons.copyRounded,
                                  size: 12,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Copy',
                                  style: AppTypography.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (formattedDate.isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        LegacyRemixIcons.calendarTodayOutlined,
                        size: 13,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formattedDate,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.inter(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionManagerProvider);
    final canImport = permissions.canEdit('DATA_CAPTURE');
    final canCreate = permissions.canCreate('DATA_CAPTURE');
    return PopScope(
      canPop: !_importing && _selected.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_importing && _selected.isNotEmpty) {
          setState(_selected.clear);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(
              LegacyRemixIcons.arrowBack,
              color: Color(0xFF111827),
            ),
            tooltip: 'Back',
            onPressed: _importing
                ? null
                : () {
                    if (_selected.isNotEmpty) {
                      setState(_selected.clear);
                      return;
                    }
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Data Capture Records',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'View and manage captured business records',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loading || _importing
                  ? null
                  : () => _load(_data?.page ?? 1),
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(
                      LegacyRemixIcons.refreshRounded,
                      color: Color(0xFF64748B),
                    ),
            ),
            const SizedBox(width: 6),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: const Color(0xFFE2E8F0), height: 1),
          ),
        ),
        floatingActionButton: canCreate && _selected.isEmpty
            ? FloatingActionButton(
                onPressed: () => _open(null, edit: true),
                backgroundColor: AppColors.primary,
                child: const Icon(LegacyRemixIcons.add, color: Colors.white),
              )
            : null,
        bottomNavigationBar: _selected.isNotEmpty
            ? Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            onPressed: _importing
                                ? null
                                : () => setState(_selected.clear),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Clear Selection',
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: FilledButton.icon(
                            onPressed: canImport && !_importing
                                ? _importSelected
                                : null,
                            icon: _importing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    LegacyRemixIcons.fileDownloadOutlined,
                                    size: 20,
                                  ),
                            label: Text(
                              _importing
                                  ? 'Importing…'
                                  : 'Import to Leads (${_selected.length})',
                              style: AppTypography.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        body: Column(
          children: [
            // Filter & Search Controls Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  // Full-width Search Bar
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _search,
                      style: AppTypography.inter(
                        fontSize: 13,
                        color: const Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search businesses, phone or location...',
                        hintStyle: AppTypography.inter(
                          fontSize: 13,
                          color: const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          LegacyRemixIcons.searchRounded,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                        suffixIcon: _search.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  LegacyRemixIcons.closeRounded,
                                  size: 18,
                                  color: Color(0xFF94A3B8),
                                ),
                                onPressed: () {
                                  _search.clear();
                                  _load();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) {
                        _debounce?.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 350),
                          () => _load(),
                        );
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Records Header Toolbar with Select All & Sort
            Builder(
              builder: (context) {
                final records = _data?.records ?? const <DataCaptureRecord>[];
                final selectedOnPageCount = records
                    .where((record) => _selected.containsKey(record.id))
                    .length;
                final allOnPageSelected =
                    records.isNotEmpty && selectedOnPageCount == records.length;
                final someOnPageSelected =
                    selectedOnPageCount > 0 && !allOnPageSelected;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        tristate: true,
                        value: records.isEmpty
                            ? false
                            : (allOnPageSelected
                                  ? true
                                  : (someOnPageSelected ? null : false)),
                        activeColor: AppColors.primary,
                        visualDensity: const VisualDensity(
                          horizontal: -4,
                          vertical: -4,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        semanticLabel: 'Select all records on this page',
                        onChanged:
                            _importing ||
                                _loading ||
                                _error != null ||
                                records.isEmpty
                            ? null
                            : (_) {
                                setState(() {
                                  if (allOnPageSelected) {
                                    for (final r in records) {
                                      _selected.remove(r.id);
                                    }
                                  } else {
                                    for (final r in records) {
                                      _selected[r.id] = r.businessName;
                                    }
                                  }
                                });
                              },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Select All',
                        style: AppTypography.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_selected.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Text(
                            '${_selected.length} selected',
                            style: AppTypography.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF166534),
                            ),
                          ),
                        )
                      else
                        Text(
                          '(${_data?.total ?? 0} ${_data?.total == 1 ? "record" : "records"})',
                          style: AppTypography.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),

            // Records List / Loading / Error / Empty state
            Expanded(
              child: _loading && _data == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEE2E2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LegacyRemixIcons.errorOutlineRounded,
                                size: 26,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Failed to load records',
                              style: AppTypography.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: AppTypography.inter(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _load(),
                              icon: const Icon(
                                LegacyRemixIcons.refreshRounded,
                                size: 16,
                              ),
                              label: const Text('Retry'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _load(_data?.page ?? 1),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        children: [
                          if (_data?.records.isEmpty ?? true)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 48,
                                horizontal: 24,
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF1F5F9),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        LegacyRemixIcons.inventory2Outlined,
                                        size: 28,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'No Records Found',
                                      style: AppTypography.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF111827),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Try adjusting your search query or filters to discover captured businesses.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.inter(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                    if (_search.text.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _search.clear();
                                          });
                                          _load();
                                        },
                                        icon: const Icon(
                                          LegacyRemixIcons.clearAllRounded,
                                          size: 16,
                                        ),
                                        label: const Text('Clear Search'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(
                                            color: AppColors.primary,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ...?_data?.records.map(_buildRecordCard),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _photo(String? url, {double size = 120}) => url == null
    ? SizedBox(
        width: size,
        height: size,
        child: const Icon(LegacyRemixIcons.business),
      )
    : Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => SizedBox(
          width: size,
          height: size,
          child: const Icon(LegacyRemixIcons.brokenImageOutlined),
        ),
      );

class DataCaptureRecordScreen extends ConsumerStatefulWidget {
  final DataCaptureRecord? record;
  final bool editing;
  const DataCaptureRecordScreen({super.key, this.record, this.editing = false});
  @override
  ConsumerState<DataCaptureRecordScreen> createState() => _RecordState();
}

class _RecordState extends ConsumerState<DataCaptureRecordScreen> {
  final _service = DataCaptureRecordsService();
  final _form = GlobalKey<FormState>();
  static const _fields = {
    'businessName': 'Business name',
    'category': 'Category',
    'address': 'Address',
    'phone': 'Phone',
    'email': 'Email',
    'website': 'Website',
    'notes': 'Notes',
    'latitude': 'Latitude',
    'longitude': 'Longitude',
  };
  final Map<String, TextEditingController> _controllers = {};
  DataCaptureRecord? _record;
  bool _loading = false, _busy = false, _changed = false;
  bool _importing = false;
  bool get _isImported =>
      _record?.fields['isImported'] == true ||
      _record?.fields['importedLeadId'] != null ||
      const ['LEAD_IMPORTED', 'LEAD_CREATED'].contains(_record?.status);
  late bool _editing;
  String? _error;
  @override
  void initState() {
    super.initState();
    _record = widget.record;
    _editing = widget.editing;
    for (final key in _fields.keys) {
      _controllers[key] = TextEditingController();
    }
    _populate();
    if (_record != null) _fetch();
  }

  void _populate() {
    for (final key in _fields.keys) {
      _controllers[key]!.text = _record?.fields[key]?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final record = await _service.detail(_record!.id);
      if (mounted) {
        setState(() {
          _record = record;
          _populate();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = dataCaptureError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _perform(
    Future<void> Function() action, {
    bool close = false,
  }) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      _changed = true;
      if (!mounted) return;
      AppSnackBar.showSuccess(context, 'Data Capture saved successfully');
      if (close) {
        Navigator.pop(context, true);
      } else {
        await _fetch();
      }
    } catch (e) {
      if (mounted) setState(() => _error = dataCaptureError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final payload = <String, dynamic>{};
    for (final key in _fields.keys) {
      final text = _controllers[key]!.text.trim();
      final old = _record?.fields[key]?.toString() ?? '';
      if (_record != null && text == old) continue;
      if (_record == null && text.isEmpty && key != 'businessName') continue;
      if (key == 'latitude' || key == 'longitude') {
        // Omit blank coordinates; clearing them is not supported by the DTO.
        if (text.isNotEmpty) payload[key] = double.parse(text);
      } else {
        payload[key] = text;
      }
    }
    if (_record == null) {
      payload['status'] = 'VALIDATED';
    }
    await _perform(
      () => _record == null
          ? _service.create(payload)
          : _service.update(_record!.id, payload),
      close: true,
    );
  }

  Future<void> _importAsLead() async {
    if (_busy ||
        _loading ||
        _record == null ||
        _isImported ||
        !ref.read(permissionManagerProvider).canEdit('DATA_CAPTURE')) {
      return;
    }
    setState(() {
      _busy = true;
      _importing = true;
    });
    try {
      if (_record!.status.toUpperCase() != 'VALIDATED') {
        try {
          await _service.status(_record!.id, 'validate');
          _record = DataCaptureRecord.fromJson({
            ..._record!.fields,
            'status': 'VALIDATED',
          });
        } catch (valErr) {
          debugPrint(
            '[DATA_CAPTURE] Validation before single import error: $valErr',
          );
        }
      }
      // Import the saved record by ID, preserving the existing server mapping.
      final result = await _service.importSelected([_record!.id]);
      if (!mounted) return;
      debugPrint('[DATA_CAPTURE_IMPORT_UI] flow=details result=parsed');
      final imported = result['imported'] as List;
      final duplicates = result['alreadyImported'] as List;
      if (imported.isNotEmpty || duplicates.isNotEmpty) {
        final lead = (imported.isNotEmpty ? imported : duplicates).first as Map;
        setState(() {
          _changed = true;
          _record = DataCaptureRecord.fromJson({
            ..._record!.fields,
            'isImported': true,
            'importedLeadId': lead['leadId'],
            'status': 'LEAD_IMPORTED',
          });
        });
        ref.invalidate(leadsProvider);
        ref.invalidate(leadStagesProvider);
        if (!mounted) return;
        AppSnackBar.showSuccess(
          context,
          imported.isNotEmpty
              ? 'Business imported to Leads successfully.'
              : 'This business is already in Leads.',
        );
        if ((ref.read(permissionManagerProvider).canViewLeads ||
            ref.read(permissionManagerProvider).isCrmEligible)) {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const LeadsView()));
        } else {
          AppSnackBar.showInfo(
            context,
            'Lead imported. Your account does not have access to the Leads screen.',
          );
        }
      } else {
        final unsuccessful = [
          ...result['skipped'] as List,
          ...result['failed'] as List,
        ];
        AppSnackBar.showError(
          context,
          unsuccessful.firstOrNull?['reason']?.toString() ??
              'Import was not completed. Please retry.',
        );
      }
    } catch (error) {
      debugPrint(
        '[DATA_CAPTURE_UI_ERROR] type=${error.runtimeType} mounted=$mounted',
      );
      if (!mounted) return;
      AppSnackBar.showError(
        context,
        error is FormatException
            ? 'Unable to read the import result. Reload this record before retrying.'
            : dataCaptureError(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _importing = false;
        });
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete captured record?'),
        content: const Text('This record will be removed from the list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _perform(() => _service.delete(_record!.id), close: true);
    }
  }

  String _value(String key) => _record?.fields[key]?.toString() ?? '';

  Future<void> _copyValue(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    AppSnackBar.showSuccess(context, '$label copied');
  }

  Future<void> _openLink(
    String value, {
    bool phone = false,
    bool email = false,
  }) async {
    try {
      final target = phone
          ? 'tel:${value.replaceAll(RegExp(r'[^0-9+]'), '')}'
          : email
          ? 'mailto:${value.trim()}'
          : value.startsWith(RegExp(r'https?://'))
          ? value
          : 'https://$value';
      final uri = Uri.parse(target);
      if (!['http', 'https', 'tel', 'mailto'].contains(uri.scheme) ||
          !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Unable to open link');
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.showError(context, 'Unable to open this link.');
    }
  }

  Widget _detailCard(String title, IconData icon, Widget content) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: AppTypography.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF17243B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    ),
  );

  Widget _detailValue(
    String label,
    String value, {
    bool copy = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              SelectableText(
                value.isEmpty ? '—' : value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF17243B)),
              ),
            ],
          ),
        ),
        if (copy && value.isNotEmpty)
          IconButton(
            tooltip: 'Copy $label',
            onPressed: () => _copyValue(label, value),
            icon: const Icon(LegacyRemixIcons.copyOutlined, size: 18),
          ),
      ],
    ),
  );

  Widget _badge(String text, {bool green = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: green ? const Color(0xFFE8F5E9) : const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: green ? const Color(0xFF157A3D) : const Color(0xFF475569),
      ),
    ),
  );

  Widget _stat(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE2E8F0)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 19),
        const SizedBox(height: 8),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF17243B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
      ],
    ),
  );

  List<Widget> _businessDetails() {
    final record = _record!;
    final phone = _value('phone');
    final website = _value('website');
    final maps = _value('googleMapsUrl');
    const primaryFields = {
      'businessName',
      'category',
      'status',
      'provider',
      'source',
      'id',
      'rating',
      'reviewCount',
      'businessStatus',
      'address',
      'phone',
      'website',
      'email',
      'googlePlaceId',
      'latitude',
      'longitude',
      'googleMapsUrl',
      'socialMedia',
    };
    return [
      if (record.business.primaryPhotoUrl != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _photo(record.business.primaryPhotoUrl, size: 96),
          ),
        ),
      _detailCard(
        'Business overview',
        LegacyRemixIcons.businessOutlined,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.businessName.isEmpty
                  ? 'Business name unavailable'
                  : record.businessName,
              style: AppTypography.inter(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF17243B),
              ),
            ),
            if (_value('category').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _value('category'),
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (record.status.isNotEmpty)
                  _badge(record.status, green: true),
                if (_value('provider').isNotEmpty ||
                    _value('source').isNotEmpty)
                  _badge(
                    _value('provider').isNotEmpty
                        ? _value('provider')
                        : _value('source'),
                  ),
                _badge('Record #${record.id}'),
              ],
            ),
          ],
        ),
      ),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns =
              constraints.maxWidth < 340 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20
              ? 1
              : 3;
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                SizedBox(
                  width: width,
                  child: _stat(
                    'Rating',
                    _value('rating'),
                    LegacyRemixIcons.starOutlineRounded,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _stat(
                    'Reviews',
                    _value('reviewCount'),
                    LegacyRemixIcons.reviewsOutlined,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: _stat(
                    'Business status',
                    _value('businessStatus'),
                    LegacyRemixIcons.storefrontOutlined,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      _detailCard(
        'Address',
        LegacyRemixIcons.locationOnOutlined,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailValue('Full address', _value('address'), copy: true),
            if (maps.isNotEmpty)
              TextButton.icon(
                onPressed: () => _openLink(maps),
                icon: const Icon(LegacyRemixIcons.mapOutlined),
                label: const Text('Open in Maps'),
              ),
          ],
        ),
      ),
      if (phone.isNotEmpty)
        _detailCard(
          'Phone',
          LegacyRemixIcons.phoneOutlined,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailValue('Phone number', phone, copy: true),
              TextButton.icon(
                onPressed: () => _openLink(phone, phone: true),
                icon: const Icon(LegacyRemixIcons.callOutlined),
                label: const Text('Call business'),
              ),
            ],
          ),
        ),
      if (website.isNotEmpty)
        _detailCard(
          'Website',
          LegacyRemixIcons.languageOutlined,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailValue('Website URL', website, copy: true),
              TextButton.icon(
                onPressed: () => _openLink(website),
                icon: const Icon(LegacyRemixIcons.openInNew),
                label: const Text('Visit Website'),
              ),
            ],
          ),
        ),
      if (_value('email').isNotEmpty)
        _detailCard(
          'Email',
          LegacyRemixIcons.mailOutline,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailValue('Email address', _value('email'), copy: true),
              TextButton.icon(
                onPressed: () => _openLink(_value('email'), email: true),
                icon: const Icon(LegacyRemixIcons.mailOutlined),
                label: const Text('Send Email'),
              ),
            ],
          ),
        ),
      if (record.fields['socialMedia'] != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: SocialMediaProfilesCard(
            socialMedia: record.fields['socialMedia'],
          ),
        ),
      _detailCard(
        'Google Places information',
        LegacyRemixIcons.travelExploreOutlined,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailValue(
              'Google Place ID',
              _value('googlePlaceId'),
              copy: true,
            ),
            _detailValue('Provider', _value('provider')),
            LayoutBuilder(
              builder: (context, constraints) {
                final coordinates = [
                  _detailValue('Latitude', _value('latitude'), copy: true),
                  _detailValue('Longitude', _value('longitude'), copy: true),
                ];
                return constraints.maxWidth < 300 ||
                        MediaQuery.textScalerOf(context).scale(14) > 20
                    ? Column(children: coordinates)
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: coordinates[0]),
                          const SizedBox(width: 12),
                          Expanded(child: coordinates[1]),
                        ],
                      );
              },
            ),
            if (maps.isNotEmpty) ...[
              _detailValue('Google Maps URL', maps, copy: true),
              TextButton.icon(
                onPressed: () => _openLink(maps),
                icon: const Icon(LegacyRemixIcons.openInNew),
                label: const Text('Open Google Maps'),
              ),
            ],
          ],
        ),
      ),
      Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(
              'Additional Information',
              style: AppTypography.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: const Icon(
              LegacyRemixIcons.infoOutline,
              color: AppColors.primary,
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              ...record.fields.entries
                  .where(
                    (entry) =>
                        !primaryFields.contains(entry.key) &&
                        entry.value != null,
                  )
                  .map(
                    (entry) => entry.value is Map || entry.value is List
                        ? ExpansionTile(
                            title: Text(_readableLabel(entry.key)),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: SelectableText(
                                  const JsonEncoder.withIndent(
                                    '  ',
                                  ).convert(entry.value),
                                ),
                              ),
                            ],
                          )
                        : _detailValue(
                            _readableLabel(entry.key),
                            entry.value.toString(),
                          ),
                  ),
              ExpansionTile(
                title: const Text('Raw record data'),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      const JsonEncoder.withIndent('  ').convert(record.fields),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }

  String _readableLabel(String key) {
    final label = key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ');
    return label.isEmpty
        ? label
        : '${label[0].toUpperCase()}${label.substring(1)}';
  }

  Widget? _bottomLinks() {
    if (_editing || _record == null || _loading || _error != null) return null;
    final phone = _value('phone'),
        website = _value('website'),
        maps = _value('googleMapsUrl');
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.4,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (ref
                          .watch(permissionManagerProvider)
                          .canEdit('DATA_CAPTURE') ||
                      _isImported)
                    FilledButton.icon(
                      onPressed: _busy || _isImported ? null : _importAsLead,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                                semanticsLabel: 'Importing to Leads',
                              ),
                            )
                          : Icon(
                              _isImported
                                  ? LegacyRemixIcons.checkCircleOutline
                                  : LegacyRemixIcons.personAddAlt1,
                            ),
                      label: Text(
                        _importing
                            ? 'Importing…'
                            : _isImported
                            ? 'Imported'
                            : 'Import to Leads',
                      ),
                    ),
                  if (phone.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _openLink(phone, phone: true),
                      icon: const Icon(LegacyRemixIcons.callOutlined, size: 18),
                      label: const Text('Call'),
                    ),
                  if (website.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _openLink(website),
                      icon: const Icon(LegacyRemixIcons.language, size: 18),
                      label: const Text('Website'),
                    ),
                  if (maps.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _openLink(maps),
                      icon: const Icon(LegacyRemixIcons.mapOutlined, size: 18),
                      label: const Text('Maps'),
                    ),
                  Builder(
                    builder: (buttonContext) => OutlinedButton.icon(
                      onPressed: () async {
                        final box =
                            buttonContext.findRenderObject() as RenderBox?;
                        try {
                          await SharePlus.instance.share(
                            ShareParams(
                              text: [
                                _record!.businessName,
                                _value('address'),
                                phone,
                                website,
                                maps,
                              ].where((v) => v.isNotEmpty).join('\n'),
                              sharePositionOrigin: box == null
                                  ? null
                                  : box.localToGlobal(Offset.zero) & box.size,
                            ),
                          );
                        } catch (_) {
                          if (!mounted) return;
                          AppSnackBar.showError(
                            context,
                            'Unable to share this record.',
                          );
                        }
                      },
                      icon: const Icon(
                        LegacyRemixIcons.shareOutlined,
                        size: 18,
                      ),
                      label: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionManagerProvider);
    final canSave = _record == null
        ? permissions.canCreate('DATA_CAPTURE')
        : permissions.canEdit('DATA_CAPTURE');
    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_busy) Navigator.pop(context, _changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            _record == null ? 'New Data Capture' : 'Data Capture Details',
          ),
        ),
        bottomNavigationBar: _bottomLinks(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _form,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(_error!),
                              if (_record != null)
                                TextButton(
                                  onPressed: _busy ? null : _fetch,
                                  child: const Text('Reload record'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    if (_error == null || _record == null) ...[
                      if (_editing) ...[
                        ..._fields.entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _controllers[entry.key],
                              enabled: !_busy && canSave,
                              maxLines:
                                  entry.key == 'notes' || entry.key == 'address'
                                  ? 3
                                  : 1,
                              decoration: InputDecoration(
                                labelText: entry.value,
                              ),
                              keyboardType:
                                  ['latitude', 'longitude'].contains(entry.key)
                                  ? const TextInputType.numberWithOptions(
                                      decimal: true,
                                      signed: true,
                                    )
                                  : TextInputType.text,
                              validator: (value) {
                                final text = value?.trim() ?? '';
                                if (entry.key == 'businessName' &&
                                    text.isEmpty) {
                                  return 'Business name is required';
                                }
                                if ([
                                      'latitude',
                                      'longitude',
                                    ].contains(entry.key) &&
                                    text.isNotEmpty) {
                                  final number = double.tryParse(text);
                                  final bound = entry.key == 'latitude'
                                      ? 90
                                      : 180;
                                  if (number == null ||
                                      !number.isFinite ||
                                      number.abs() > bound) {
                                    return 'Enter a valid ${entry.value.toLowerCase()}';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                        if (canSave)
                          FilledButton(
                            onPressed: _busy ? null : _save,
                            child: Text(_busy ? 'Saving…' : 'Save'),
                          ),
                      ] else if (_record != null) ...[
                        ..._businessDetails(),
                        if (permissions.canEdit('DATA_CAPTURE')) ...[
                          FilledButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _editing = true;
                                    _populate();
                                  }),
                            child: const Text('Edit'),
                          ),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _perform(
                                    () => _service.status(
                                      _record!.id,
                                      'validate',
                                    ),
                                  ),
                            child: const Text('Mark validated'),
                          ),
                          OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => _perform(
                                    () =>
                                        _service.status(_record!.id, 'reject'),
                                  ),
                            child: const Text('Reject'),
                          ),
                        ],
                        if (permissions.canDelete('DATA_CAPTURE'))
                          TextButton(
                            onPressed: _busy ? null : _delete,
                            child: const Text('Delete'),
                          ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
