import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';

class AdminScheduleVisitSheet extends ConsumerStatefulWidget {
  const AdminScheduleVisitSheet({super.key});

  @override
  ConsumerState<AdminScheduleVisitSheet> createState() =>
      _AdminScheduleVisitSheetState();
}

class _AdminScheduleVisitSheetState
    extends ConsumerState<AdminScheduleVisitSheet> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomer;
  String _selectedEmployee = 'Demo User';
  final _locationController = TextEditingController(
    text: 'Andheri West, Mumbai',
  );
  final _timeController = TextEditingController(text: '11:00 AM');
  final _notesController = TextEditingController();

  final List<String> _employees = [
    'Demo User',
    'Amit Verma',
    'Rahul Sharma',
    'Sneha Patel',
    'Priya Deshmukh',
    'Neha Kulkarni',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSaveVisit() {
    if (!_formKey.currentState!.validate()) return;

    final newVisit = AdminVisit(
      id: 'VIS-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      customerName: _selectedCustomer ?? 'Care Fitness Gym',
      employeeName: _selectedEmployee,
      date: 'Today',
      time: _timeController.text.trim(),
      location: _locationController.text.trim(),
      status: VisitStatus.today,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    ref.read(companyAdminProvider.notifier).addVisit(newVisit);

    AppToast.success(
      context,
      'Visit scheduled for "${newVisit.customerName}".',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyAdminProvider);
    final customerNames = state.customers.map((c) => c.name).toSet().toList();

    if (_selectedCustomer == null && customerNames.isNotEmpty) {
      _selectedCustomer = customerNames.first;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Remix.map_pin_time_fill,
                        color: Color(0xFF0284C7),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Schedule Client Visit',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Remix.close_line,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Select Customer *'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedCustomer,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _inputDecoration('', Remix.building_2_line),
                      items: customerNames
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCustomer = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Assigned Field Staff *'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedEmployee,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _inputDecoration('', Remix.user_3_line),
                      items: _employees
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedEmployee = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Visit Time *'),
                              TextFormField(
                                controller: _timeController,
                                style: GoogleFonts.outfit(fontSize: 14),
                                decoration: _inputDecoration(
                                  '11:00 AM',
                                  Remix.time_line,
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'Time required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Location Area *'),
                              TextFormField(
                                controller: _locationController,
                                style: GoogleFonts.outfit(fontSize: 14),
                                decoration: _inputDecoration(
                                  'Mumbai',
                                  Remix.map_pin_2_line,
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'Location required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Agenda / Notes'),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText:
                            'e.g. Testimonial recording, shoot prep meeting...',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _handleSaveVisit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'SCHEDULE VISIT',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(
        fontSize: 13,
        color: const Color(0xFF94A3B8),
      ),
      prefixIcon: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      isDense: true,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }
}
