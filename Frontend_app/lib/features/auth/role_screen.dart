import 'package:flutter/material.dart';

import '../../core/models/user_role.dart';
import '../../core/services/app_session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
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
    final canContinue = session.role != null;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
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
                'STEP 01',
                style: AppText.ui(
                  size: 11,
                  weight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 2.6,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              Text('Choose your\nrole.', style: AppText.display(size: 40)),
              const SizedBox(height: 12),
              Text(
                'Tell us how you want to use this app.',
                style: AppText.ui(size: 16, color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 32),
              _RoleCard(
                selected: session.role == UserRole.customer,
                iconAsset: AppAssets.iconCar,
                kicker: 'For drivers',
                title: 'I’m a Customer',
                subtitle: 'Find and book car washes near you',
                onTap: () => session.selectRole(UserRole.customer),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                selected: session.role == UserRole.vendor,
                iconAsset: AppAssets.iconShop,
                kicker: 'For owners',
                title: 'I own a Car Wash',
                subtitle: 'List my shop and manage bookings',
                onTap: () => session.selectRole(UserRole.vendor),
              ),
              const Spacer(),
              AppPrimaryButton(
                label: 'Continue',
                trailing: const Icon(Icons.arrow_forward_rounded),
                onPressed: canContinue
                    ? () => Navigator.of(context).pushNamed(LoginScreen.route)
                    : null,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'You can always change this later\nin your profile',
                  textAlign: TextAlign.center,
                  style: AppText.ui(
                    size: 13,
                    color: AppColors.mutedLight,
                    height: 1.45,
                  ),
                ),
              ),
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
    required this.kicker,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String iconAsset;
  final String kicker;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = selected ? AppColors.primaryDeep : AppColors.ink;
    final bodyColor = selected ? const Color(0xFF3E6A94) : AppColors.muted;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: selected ? AppColors.selectedFill : AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.4 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: selected ? 0.06 : 0.04),
            blurRadius: selected ? 14 : 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFBFDFF8)
                        : const Color(0xFFEAF4FC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    iconAsset,
                    width: 28,
                    height: 24,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kicker.toUpperCase(),
                        style: AppText.ui(
                          size: 10.5,
                          weight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1.4,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        style: AppText.display(size: 20, color: titleColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppText.ui(
                          size: 13.5,
                          color: bodyColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.fieldBorder,
                      width: 1.4,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
