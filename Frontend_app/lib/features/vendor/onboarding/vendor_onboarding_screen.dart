import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/buttons.dart';
import '../vendor_shell.dart';

class VendorOnboardingScreen extends StatelessWidget {
  const VendorOnboardingScreen({super.key});

  static const route = '/vendor-onboarding';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),
              Text(
                'List your shop',
                style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your shop name and area so customers can find you. You can edit this later.',
                style: GoogleFonts.montserrat(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 24),
              const TextField(
                decoration: InputDecoration(labelText: 'Shop name', hintText: 'Sparkle Auto Spa'),
              ),
              const SizedBox(height: 12),
              const TextField(
                decoration: InputDecoration(labelText: 'Area', hintText: 'Koramangala'),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Go to today board',
                onPressed: () => Navigator.of(context).pushReplacementNamed(VendorShell.route),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
