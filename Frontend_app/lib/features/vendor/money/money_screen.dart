import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = MockData.vendorEarnings;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            'Money',
            style: AppText.display(),
          ),
          const SizedBox(height: 4),
          Text(
            'Earnings snapshot · mock figures',
            style: GoogleFonts.figtree(color: AppColors.muted),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: GoogleFonts.figtree(color: Colors.white70)),
                Text(
                  '₹ ${data.today}',
                  style: AppText.display(size: 32, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _row('This week', '₹ ${data.week}'),
          _row('Pending payout', '₹ ${data.pending}'),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.figtree(color: AppColors.muted)),
          const Spacer(),
          Text(value, style: GoogleFonts.figtree(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
