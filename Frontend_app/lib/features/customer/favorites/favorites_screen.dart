import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/app_session.dart';
import '../../../core/services/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/shop_cards.dart';
import '../shop_detail/shop_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final shops =
        MockData.shops.where((shop) => session.favoriteIds.contains(shop.id)).toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Favourites',
              style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Your saved car washes',
              style: GoogleFonts.montserrat(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: shops.isEmpty
                  ? Center(
                      child: Text(
                        'No saved shops yet.\nTap the heart on a listing to add one.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(color: AppColors.muted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: shops.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final shop = shops[index];
                        return FavoriteShopTile(
                          shop: shop,
                          onTap: () => Navigator.of(context).pushNamed(
                            ShopDetailScreen.route,
                            arguments: shop,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
