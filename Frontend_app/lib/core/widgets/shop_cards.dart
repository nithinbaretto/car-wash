import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/shop.dart';
import '../services/app_session.dart';
import '../theme/app_colors.dart';

class NearbyShopCard extends StatelessWidget {
  const NearbyShopCard({
    super.key,
    required this.shop,
    required this.onTap,
    required this.onBook,
  });

  final Shop shop;
  final VoidCallback onTap;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final fav = session.isFavorite(shop.id);

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(shop.imageUrl, fit: BoxFit.cover),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: _chip(
                      icon: Icons.location_on_outlined,
                      label: '${shop.distanceKm}km',
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: _circleButton(
                      icon: fav ? Icons.favorite : Icons.favorite_border,
                      color: fav ? AppColors.heart : Colors.white,
                      onTap: () => session.toggleFavorite(shop.id),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    shop.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  shop.isOpen ? 'Open' : 'Closed',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: shop.isOpen ? AppColors.open : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: Color(0xFFF5B400)),
                const SizedBox(width: 4),
                Text(
                  '${shop.rating}',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '  (${shop.reviewCount})  ·  ${shop.nextAvailable}',
                  style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              shop.services.join('  ·  '),
              style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'From  ',
                  style: GoogleFonts.montserrat(color: AppColors.muted, fontSize: 14),
                ),
                Text(
                  '${shop.priceFrom}\$',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onBook,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Book now  >'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.montserrat(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class FavoriteShopTile extends StatelessWidget {
  const FavoriteShopTile({
    super.key,
    required this.shop,
    required this.onTap,
  });

  final Shop shop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                shop.imageUrl,
                width: 86,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF5B400)),
                      Text(
                        ' ${shop.rating}  ·  ${shop.distanceKm} Km',
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Next Available',
                    style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.mutedLight),
                  ),
                  Text(
                    shop.nextAvailable,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  onPressed: () => session.toggleFavorite(shop.id),
                  icon: const Icon(Icons.favorite, color: AppColors.heart),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
