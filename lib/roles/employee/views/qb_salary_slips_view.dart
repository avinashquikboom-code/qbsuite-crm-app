import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:quickboom_app/core/theme/app_colors.dart';
import 'package:quickboom_app/core/theme/app_typography.dart';
import 'package:quickboom_app/core/widgets/qb_widgets.dart';

class QBSalarySlipsView extends StatelessWidget {
  const QBSalarySlipsView({super.key});

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: true,
        title: Text(
          'Salary Slips & Payslips',
          style: AppTypography.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        itemCount: 12,
        itemBuilder: (context, index) {
          final monthIndex = (index % 12);
          final year = 2026 - (index ~/ 12);
          final months = [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ];
          final monthName = months[monthIndex];
          final amount = 100000.0;
          final isPaid = index < 3; // Last 3 months as paid

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SalaryCard(
              month: '$monthName $year',
              amount: _formatCurrency(amount),
              status: isPaid ? 'Paid' : 'Pending',
              onDownload: () {
                // Download payslip
              },
            ),
          );
        },
      ),
    );
  }
}
