import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/models/user_role.dart';
import '../../core/services/app_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/buttons.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  static const route = '/role';

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBackCircle(
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                    return;
                  }
                  Navigator.of(context)
                      .pushReplacementNamed(OnboardingScreen.route);
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Choose your role',
                style: GoogleFonts.montserrat(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tell us how you want to use this app.',
                style: GoogleFonts.montserrat(fontSize: 16, color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              _RoleCard(
                selected: session.role == UserRole.customer,
                iconAsset: AppAssets.iconCar,
                title: 'I’m a Customer',
                subtitle: 'Find and book car washes\nnear you',
                onTap: () => session.selectRole(UserRole.customer),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                selected: session.role == UserRole.vendor,
                iconAsset: AppAssets.iconShop,
                title: 'I own a Car Wash',
                subtitle: 'List my shop and manage\nbookings',
                onTap: () => session.selectRole(UserRole.vendor),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 260,
                  child: AppPrimaryButton(
                    label: 'Continue',
                    onPressed: session.role == null
                        ? null
                        : () => Navigator.of(context).pushNamed(LoginScreen.route),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'You can always change this later\nin your profile',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(color: AppColors.mutedLight, height: 1.35),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.selected,
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(22, 22, 16, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.fieldBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      iconAsset,
                      width: 40,
                      height: 32,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.montserrat(color: AppColors.muted, height: 1.3),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.chevron_right,
                  color: selected ? AppColors.primary : AppColors.mutedLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
