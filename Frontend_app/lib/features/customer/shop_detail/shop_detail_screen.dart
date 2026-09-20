import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/booking.dart';
import '../../../core/models/shop.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/buttons.dart';

class ShopDetailScreen extends StatelessWidget {
  const ShopDetailScreen({super.key, required this.shop});

  static const route = '/shop';

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final fav = session.isFavorite(shop.id);

    return Scaffold(
      body: Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 11,
                child: Image.asset(AppAssets.carWashCard, fit: BoxFit.cover),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const AppBackCircle(),
                      const Spacer(),
                      _round(
                        icon: fav ? Icons.favorite : Icons.favorite_border,
                        color: fav ? AppColors.heart : AppColors.ink,
                        onTap: () => session.toggleFavorite(shop.id),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        shop.name,
                        style: AppText.display(size: 24),
                      ),
                    ),
                    Text(
                      shop.isOpen ? 'Open' : 'Closed',
                      style: GoogleFonts.figtree(
                        color: shop.isOpen ? AppColors.open : AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(shop.address, style: GoogleFonts.figtree(color: AppColors.muted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF5B400), size: 18),
                    Text(
                      '  ${shop.rating}  (${shop.reviewCount})',
                      style: GoogleFonts.figtree(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      '  ·  ${shop.distanceLabel(fromLat: session.location?.latitude, fromLng: session.location?.longitude)}',
                      style: GoogleFonts.figtree(color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('Services', style: GoogleFonts.figtree(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: shop.services
                      .map(
                        (service) => Chip(
                          label: Text(service),
                          backgroundColor: AppColors.primarySoft,
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 18),
                Text('About', style: GoogleFonts.figtree(fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 8),
                Text(shop.about, style: GoogleFonts.figtree(color: AppColors.muted, height: 1.45)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Next available', style: GoogleFonts.figtree(color: AppColors.muted, fontSize: 12)),
                          Text(
                            shop.nextAvailable,
                            style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        'From ${shop.priceFrom}\$',
                        style: GoogleFonts.figtree(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: AppPrimaryButton(
              label: 'Book now',
              onPressed: () => _book(context, session),
            ),
          ),
        ],
      ),
    );
  }

  Widget _round({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Ink(
        width: 46,
        height: 46,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
    );
  }

  void _book(BuildContext context, AppSession session) {
    session.addBooking(
      Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        shopId: shop.id,
        shopName: shop.name,
        shopImageUrl: shop.imageUrl,
        service: shop.services.first,
        whenLabel: shop.nextAvailable,
        status: BookingStatus.upcoming,
        price: shop.priceFrom,
      ),
    );
    session.setCustomerTab(2);
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Booked ${shop.name} · ${shop.nextAvailable}')),
    );
  }
}
