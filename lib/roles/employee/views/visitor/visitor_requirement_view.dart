import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/network/api_client.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/roles/employee/views/visitor/visitor_complete_view.dart';

class VisitorRequirementView extends ConsumerStatefulWidget {
  final Map<String, dynamic> visit;
  final VoidCallback? onVisitUpdated;

  const VisitorRequirementView({
    super.key,
    required this.visit,
    this.onVisitUpdated,
  });

  @override
  ConsumerState<VisitorRequirementView> createState() =>
      _VisitorRequirementViewState();
}

class _VisitorRequirementViewState
    extends ConsumerState<VisitorRequirementView> {
  final _requirementController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  final List<String> _commonServices = [
    'E-commerce Website',
    'Social Media Marketing',
    'SEO (Optional)',
    'Website Development',
    'Mobile Application',
    'Other',
  ];

  final Set<String> _selectedServices = {
    'E-commerce Website',
    'Social Media Marketing',
  };
  String _selectedBudget = '₹50,000 - ₹1,00,000';
  final List<String> _budgetOptions = [
    '< ₹50,000',
    '₹50,000 - ₹1,00,000',
    '₹1,00,000 - ₹2,50,000',
    '₹2,50,000+',
  ];

  String _selectedTimeline = 'Within 1 Month';
  final List<String> _timelines = [
    'Within 1 Month',
    '1 - 2 Months',
    'Immediate (1-2 weeks)',
    '3 - 6 Months',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Pre-populate if notes or purpose has info
    final purpose = widget.visit['purpose']?.toString() ?? '';
    if (purpose.isNotEmpty) {
      _requirementController.text = purpose;
    }
  }

  @override
  void dispose() {
    _requirementController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveRequirement() async {
    final visitId = widget.visit['id'];
    if (visitId == null) return;

    final requirement = _requirementController.text.trim();
    if (requirement.isEmpty && _selectedServices.isEmpty) {
      AppToast.error(
        context,
        'Please specify requirement or select required services',
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final servicesStr = _selectedServices.join(', ');
      final budgetStr = _selectedBudget;
      final notesStr = _notesController.text.trim();

      final res = await ref
          .read(apiClientProvider)
          .patch(
            '/mobile/visits/$visitId/requirement',
            data: {
              'requirement': requirement,
              'services': servicesStr,
              'budget': budgetStr,
              'timeline': _selectedTimeline,
              'notes': notesStr,
            },
          );

      Map<String, dynamic> updatedVisit = widget.visit;
      if (res.data != null && res.data is Map) {
        final raw = res.data['data'] is Map
            ? res.data['data']
            : (res.data['visit'] is Map ? res.data['visit'] : res.data);
        updatedVisit = Map<String, dynamic>.from(raw);
      }

      if (mounted) {
        AppToast.success(context, 'Requirement saved successfully!');
        widget.onVisitUpdated?.call();

        // Continue to Complete Visit flow
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VisitorCompleteView(
              visit: updatedVisit,
              requirementSummary: {
                'requirement': requirement,
                'services': servicesStr,
                'budget': budgetStr,
                'timeline': _selectedTimeline,
                'notes': notesStr,
              },
              onVisitUpdated: widget.onVisitUpdated,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Failed to save requirement: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customerName =
        widget.visit['customer']?.toString() ??
        widget.visit['customerName']?.toString() ??
        'Client';

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Remix.arrow_left_line, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Customer Requirement',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Remix.user_star_fill,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customerName,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        Text(
                          widget.visit['location']?.toString() ?? '',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Step 1 of 2',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Requirement Details *',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _requirementController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Client needs high-converting e-commerce web app & marketing campaign...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textPlaceholder,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderLight,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderLight,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Required Services',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _commonServices.map((service) {
                      final isSelected = _selectedServices.contains(service);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(service),
                        labelStyle: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.scaffoldBg,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.borderLight,
                          ),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedServices.add(service);
                            } else {
                              _selectedServices.remove(service);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget (Approx.)',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedBudget,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              items: _budgetOptions.map((b) {
                                return DropdownMenuItem(
                                  value: b,
                                  child: Text(
                                    b,
                                    style: GoogleFonts.outfit(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedBudget = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expected Timeline',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTimeline,
                              isExpanded: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.borderLight,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              items: _timelines.map((t) {
                                return DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: GoogleFonts.outfit(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedTimeline = val);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Additional Notes',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText:
                          'Client ne branding aur ad campaign bhi discuss kiya...',
                      hintStyle: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.textPlaceholder,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.borderLight,
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),

                  const SizedBox(height: 14),

                  InkWell(
                    onTap: () {
                      AppToast.info(context, 'Photo attachment feature ready');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.scaffoldBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Remix.camera_line,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add Photos (Optional)',
                            style: GoogleFonts.outfit(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(color: AppColors.borderLight, width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              offset: Offset(0, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _isSaving ? null : _handleSaveRequirement,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Remix.arrow_right_line, size: 20),
              label: Text(
                _isSaving ? 'SAVING...' : 'Save & Continue',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
