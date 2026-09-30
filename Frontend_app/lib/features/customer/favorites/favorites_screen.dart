import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/shop.dart';
import '../../../core/services/app_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/shop_cards.dart';
import '../shop_detail/shop_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final session = SessionScope.of(context);
      session.loadFavourites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);

    // Prefer loaded favourite shops from backend; merge with any cached matching favourites
    final shops = <Shop>[];
    final seenIds = <String>{};

    for (final s in session.favouriteShops) {
      if (seenIds.add(s.id)) shops.add(s);
    }
    for (final s in session.nearbyShops) {
      if (session.isFavorite(s.id) && seenIds.add(s.id)) {
        shops.add(s);
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Favourites', style: AppText.display()),
            const SizedBox(height: 4),
            Text(
              'Your saved car washes',
              style: GoogleFonts.figtree(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            if (session.loadErrors['favourites'] != null) ...[
              Text(
                session.loadErrors['favourites']!,
                style: const TextStyle(color: Colors.redAccent),
              ),
              TextButton(
                onPressed: () => session.loadFavourites(),
                child: const Text('Retry'),
              ),
            ],
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => session.loadFavourites(),
                child: shops.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            child: Center(
                              child: Text(
                                'No saved shops yet.\nTap the heart on any listing to save it here.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.figtree(
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
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
            ),
          ],
        ),
      ),
    );
  }
}
