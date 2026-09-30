import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/user_role.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/role_screen.dart';
import '../../vendor/vendor_shell.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final name = session.user?.displayName.isNotEmpty == true
        ? session.user!.displayName
        : (session.name.isNotEmpty ? session.name : 'Customer');
    final phone = session.user?.phoneNumber != null
        ? session.user!.phoneNumber!
        : (session.phone.isNotEmpty ? session.phone : '');
    final initial = name.characters.first.toUpperCase();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Row(
            children: [
              Text('Profile', style: AppText.display(size: 28)),
              const Spacer(),
              InkWell(
                onTap: () => _editProfile(context, session, name),
                child: Text(
                  'Edit',
                  style: GoogleFonts.figtree(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
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
            child: Text(
              name,
              style: GoogleFonts.figtree(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Center(
            child: Text(
              phone.isEmpty
                  ? 'Phone unavailable'
                  : (phone.startsWith('+') ? phone : '+91 $phone'),
              style: GoogleFonts.figtree(color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                session.user?.isOwner == true
                    ? 'Verified Customer & Owner'
                    : 'Verified Customer',
                style: GoogleFonts.figtree(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryDeep,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _tile(Icons.person_outline, 'Personal information', () {
            _editProfile(context, session, name);
          }),
          _tile(
            Icons.storefront_outlined,
            session.user?.isOwner == true
                ? 'Switch to Vendor Board'
                : 'I own a Car Wash (Become Vendor)',
            () async {
              try {
                await session.switchRole(UserRole.vendor);
                await session.loadOwnerShops();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    VendorShell.route,
                    (route) => false,
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to switch role. Please try again.'),
                    ),
                  );
                }
              }
            },
          ),
          _tile(Icons.description_outlined, 'Terms and Conditions', () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Accepted Terms Version: v1')),
            );
          }),
          _tile(Icons.logout, 'Logout', () async {
            await session.logout();
            if (context.mounted) {
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(RoleScreen.route, (route) => false);
            }
          }),
        ],
      ),
    );
  }

  void _editProfile(
    BuildContext context,
    AppSession session,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Display Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.length >= 2) {
                try {
                  final updated = await session.userApi.updateProfile(
                    displayName: newName,
                  );
                  session.updateCurrentUser(updated);
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Unable to save profile. Please try again.',
                        ),
                      ),
                    );
                  }
                  return;
                }
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
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
      title: Text(
        label,
        style: GoogleFonts.figtree(fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.mutedLight,
      ),
    );
  }
}
