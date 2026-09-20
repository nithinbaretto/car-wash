import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/user_role.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/role_screen.dart';
import '../../vendor/vendor_shell.dart';
import '../../../core/theme/app_typography.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final name = session.name.isEmpty ? 'Raghavendra' : session.name;
    final phone = session.phone.isEmpty ? '8865745553' : session.phone;
    final initial = name.characters.first.toUpperCase();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Text(
                'Profile',
                style: AppText.display(size: 28),
              ),
              const Spacer(),
              Text(
                'Edit',
                style: GoogleFonts.figtree(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: CircleAvatar(
              radius: 46,
              backgroundColor: AppColors.primarySoft,
              child: Text(
                initial,
                style: GoogleFonts.figtree(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(name, style: GoogleFonts.figtree(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          Center(
            child: Text('+91 $phone', style: GoogleFonts.figtree(color: AppColors.muted)),
          ),
          const SizedBox(height: 20),
          _tile(Icons.person_outline, 'Personal information', () {}),
          _tile(Icons.directions_car_outlined, 'My vehicles', () {}),
          _tile(Icons.support_agent_outlined, 'Support', () {}),
          _tile(
            Icons.storefront_outlined,
            'I own a Car Wash',
            () {
              session.selectRole(UserRole.vendor);
              Navigator.of(context).pushNamedAndRemoveUntil(
                VendorShell.route,
                (route) => false,
              );
            },
          ),
          _tile(Icons.description_outlined, 'Terms and Conditions', () {}),
          _tile(
            Icons.logout,
            'Logout',
            () {
              session.logout();
              Navigator.of(context).pushNamedAndRemoveUntil(
                RoleScreen.route,
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.ink),
      title: Text(label, style: GoogleFonts.figtree(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.mutedLight),
    );
  }
}
