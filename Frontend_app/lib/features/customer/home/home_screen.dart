import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/shop.dart';
import '../../../core/services/app_session.dart';
import '../../../core/services/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shop_cards.dart';
import '../notifications/notifications_screen.dart';
import '../shop_detail/shop_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _firstName(String name) {
    if (name.trim().isEmpty) return 'Raghav';
    return name.trim().split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final name = _firstName(session.name);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${_greeting()},\n$name',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(NotificationsScreen.route),
                icon: Badge(
                  smallSize: 8,
                  child: Icon(Icons.notifications_none, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 18, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                'Near Koramangala',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toast(context, 'Ask AI coming with backend'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.ink,
                    side: const BorderSide(color: AppColors.fieldBorder),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                  label: Text('Ask Ai', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                onTap: () => _toast(context, 'Scan is mock-only for now'),
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: const Icon(Icons.qr_code_scanner, color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const _ServiceRow(),
          const SizedBox(height: 22),
          Row(
            children: [
              Text(
                'Nearby car washes',
                style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Text(
                'See all',
                style: GoogleFonts.montserrat(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...MockData.shops.map(
            (shop) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: NearbyShopCard(
                shop: shop,
                onTap: () => _openShop(context, shop),
                onBook: () => _openShop(context, shop),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openShop(BuildContext context, Shop shop) {
    Navigator.of(context).pushNamed(ShopDetailScreen.route, arguments: shop);
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.bolt_outlined, 'Quick'),
      (Icons.chair_outlined, 'Interior'),
      (Icons.layers_outlined, 'Complete'),
      (Icons.workspace_premium_outlined, 'Premium'),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items
          .map(
            (item) => Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Icon(item.$1, color: AppColors.ink),
                ),
                const SizedBox(height: 8),
                Text(item.$2, style: GoogleFonts.montserrat(fontSize: 12)),
              ],
            ),
          )
          .toList(),
    );
  }
}
