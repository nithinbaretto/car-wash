import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../customer/profile/profile_screen.dart';
import '../../../core/theme/app_typography.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Today',
                  style: AppText.display(),
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                icon: const Icon(Icons.person_outline),
              ),
            ],
          ),
          Text(
            'Live bay board · mock data',
            style: GoogleFonts.figtree(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('In queue', '3'),
              const SizedBox(width: 10),
              _stat('In bay', '2'),
              const SizedBox(width: 10),
              _stat('Done', '11'),
            ],
          ),
          const SizedBox(height: 20),
          ...MockData.vendorToday.map(
            (row) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    child: Text(row.$1.characters.first, style: GoogleFonts.figtree(color: AppColors.primary, fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.$1, style: GoogleFonts.figtree(fontWeight: FontWeight.w700)),
                        Text(row.$2, style: GoogleFonts.figtree(color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(row.$3, style: GoogleFonts.figtree(fontWeight: FontWeight.w600)),
                      Text(row.$4, style: GoogleFonts.figtree(color: AppColors.primary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.figtree(fontSize: 22, fontWeight: FontWeight.w800)),
            Text(label, style: GoogleFonts.figtree(color: AppColors.muted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
