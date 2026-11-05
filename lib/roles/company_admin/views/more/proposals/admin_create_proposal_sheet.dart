import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/utils/app_toast.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/roles/company_admin/models/company_admin_models.dart';
import 'package:quickboom_app/roles/company_admin/viewmodels/company_admin_viewmodel.dart';

class AdminCreateProposalSheet extends ConsumerStatefulWidget {
  const AdminCreateProposalSheet({super.key});

  @override
  ConsumerState<AdminCreateProposalSheet> createState() =>
      _AdminCreateProposalSheetState();
}

class _AdminCreateProposalSheetState
    extends ConsumerState<AdminCreateProposalSheet> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedCustomer;
  final _bizNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedPackage = 'Growth';
  final _servicesController = TextEditingController(
    text:
        '12 High-Quality Reels, 12 Graphic Posts, 2 Shoot Sessions, Ad Management',
  );
  final _amountController = TextEditingController(text: '35000');
  String _validity = '30 Days';
  final _notesController = TextEditingController();

  final List<String> _packages = ['Starter', 'Growth', 'Premium', 'Custom'];
  final List<String> _validityOptions = [
    '7 Days',
    '15 Days',
    '30 Days',
    '60 Days',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customers = ref.read(companyAdminProvider).customers;
      if (customers.isNotEmpty) {
        _populateCustomerData(customers.first);
      }
    });
  }

  void _populateCustomerData(AdminCustomer customer) {
    setState(() {
      _selectedCustomer = customer.name;
      _bizNameController.text = customer.businessName;
      _mobileController.text = customer.mobile;
      _emailController.text = customer.email;
      _addressController.text =
          '${customer.city}, ${customer.state ?? 'Maharashtra'}';
    });
  }

  void _onPackageChanged(String pkg) {
    setState(() {
      _selectedPackage = pkg;
      if (pkg == 'Starter') {
        _servicesController.text =
            '6 High-Quality Reels, 8 Graphic Posts, 1 Half-Day Shoot';
        _amountController.text = '15000';
      } else if (pkg == 'Growth') {
        _servicesController.text =
            '12 High-Quality Reels, 12 Graphic Posts, 2 Shoot Sessions, Ad Optimization';
        _amountController.text = '35000';
      } else if (pkg == 'Premium') {
        _servicesController.text =
            '24 Cinematic Reels, 20 Graphic Posts, 4 Shoot Days with Drone, 24/7 Lead Support';
        _amountController.text = '65000';
      }
    });
  }

  @override
  void dispose() {
    _bizNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _servicesController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleCreateProposal() {
    if (!_formKey.currentState!.validate()) return;

    final newProp = AdminProposal(
      id: 'PROP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      customerName: _selectedCustomer ?? 'Client',
      businessName: _bizNameController.text.trim(),
      contact: _mobileController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      packageName: '$_selectedPackage Plan',
      services: _servicesController.text.trim(),
      amount: double.tryParse(_amountController.text.trim()) ?? 35000.0,
      validity: _validity,
      status: ProposalStatus.draft,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
      date: 'Today, 18 Aug',
    );

    ref.read(companyAdminProvider.notifier).addProposal(newProp);

    AppToast.success(
      context,
      'Proposal ${newProp.id} generated for ${newProp.customerName}.',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companyAdminProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Remix.file_paper_2_fill,
                        color: Color(0xFFD97706),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create Proposal',
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
                    _buildLabel('Select Customer (Auto-fills Details) *'),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      key: ValueKey(_selectedCustomer),
                      initialValue: _selectedCustomer,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      decoration: _inputDecoration('', Remix.building_2_line),
                      items: state.customers.map((c) {
                        return DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final match = state.customers.firstWhere(
                            (c) => c.name == val,
                          );
                          _populateCustomerData(match);
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Auto-filled Contact Card Banner
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-Filled Client Data:',
                            style: GoogleFonts.outfit(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Business: ${_bizNameController.text}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Phone: ${_mobileController.text} • Email: ${_emailController.text}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Address: ${_addressController.text}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Select Package'),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                key: ValueKey(_selectedPackage),
                                initialValue: _selectedPackage,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _inputDecoration(
                                  '',
                                  Remix.vip_diamond_line,
                                ),
                                items: _packages
                                    .map(
                                      (p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(
                                          p,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) _onPackageChanged(val);
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
                              _buildLabel('Amount (₹) *'),
                              TextFormField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.outfit(fontSize: 14),
                                decoration: _inputDecoration(
                                  '₹ Amount',
                                  Remix.money_dollar_circle_line,
                                ),
                                validator: (val) =>
                                    val == null || val.trim().isEmpty
                                    ? 'Amount required'
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Services Included'),
                    TextFormField(
                      controller: _servicesController,
                      maxLines: 2,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. 10 Reels, 5 Posts, Ad Spend',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Proposal Validity'),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _validity,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: _inputDecoration(
                                  '',
                                  Remix.time_line,
                                ),
                                items: _validityOptions
                                    .map(
                                      (v) => DropdownMenuItem(
                                        value: v,
                                        child: Text(
                                          v,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _validity = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _buildLabel('Notes & Special Terms'),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      style: GoogleFonts.outfit(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Payment milestones, discount terms, etc.',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.all(12),
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
                        onPressed: _handleCreateProposal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'CREATE PROPOSAL',
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
