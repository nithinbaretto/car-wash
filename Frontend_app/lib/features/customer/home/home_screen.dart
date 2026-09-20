import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/shop.dart';
import '../../../core/services/app_session.dart';
import '../../../core/services/mock_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../../core/widgets/shop_cards.dart';
import '../location/location_picker_screen.dart';
import '../notifications/notifications_screen.dart';
import '../shop_detail/shop_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _service = 'All';
  bool _openNow = false;

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

  List<Shop> _filteredShops(AppSession session) {
    final loc = session.location;
    final shops = MockData.shops.where((shop) {
      if (_openNow && !shop.isOpen) return false;
      return shop.matchesService(_service);
    }).toList();
    if (loc == null) return shops;
    shops.sort(
      (a, b) => a
          .distanceFrom(loc.latitude, loc.longitude)
          .compareTo(b.distanceFrom(loc.latitude, loc.longitude)),
    );
    return shops;
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final name = _firstName(session.name);
    final shops = _filteredShops(session);
    final locationLabel = session.location?.headerLabel ?? 'Set location';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${_greeting()},\n$name',
                          style: AppText.display(size: 28, height: 1.15),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(NotificationsScreen.route),
                        icon: Badge(
                          smallSize: 8,
                          child: Icon(
                            Icons.notifications_none,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: () => Navigator.of(context).pushNamed(
                      LocationPickerScreen.route,
                      arguments: true,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            locationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.figtree(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _ServiceFilters(
                  selected: _service,
                  openNow: _openNow,
                  onService: (value) => setState(() => _service = value),
                  onOpenNow: () => setState(() => _openNow = !_openNow),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _service == 'All'
                              ? 'Nearby car washes'
                              : '$_service nearby',
                          style: GoogleFonts.figtree(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${shops.length} ${shops.length == 1 ? 'shop' : 'shops'}',
                        style: AppText.ui(
                          size: 13,
                          weight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: shops.isEmpty
                ? const Padding(
                    padding: EdgeInsets.fromLTRB(20, 28, 20, 8),
                    child: _EmptyFilterState(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: shops.length,
                    itemBuilder: (context, index) {
                      final shop = shops[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: NearbyShopCard(
                          shop: shop,
                          onTap: () => _openShop(context, shop),
                          onBook: () => _openShop(context, shop),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _openShop(BuildContext context, Shop shop) {
    Navigator.of(context).pushNamed(ShopDetailScreen.route, arguments: shop);
  }
}

class _ServiceFilters extends StatelessWidget {
  const _ServiceFilters({
    required this.selected,
    required this.openNow,
    required this.onService,
    required this.onOpenNow,
  });

  final String selected;
  final bool openNow;
  final ValueChanged<String> onService;
  final VoidCallback onOpenNow;

  static const _services = [
    (null, 'All'),
    (AppAssets.iconQuick, 'Quick'),
    (AppAssets.iconInterior, 'Interior'),
    (AppAssets.iconComplete, 'Complete'),
    (AppAssets.iconPremium, 'Premium'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          ..._services.map((item) {
            final label = item.$2;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterPill(
                label: label,
                iconAsset: item.$1,
                selected: selected == label,
                onTap: () => onService(label),
              ),
            );
          }),
          _FilterPill(
            label: 'Open now',
            icon: Icons.schedule_rounded,
            selected: openNow,
            onTap: onOpenNow,
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.iconAsset,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? iconAsset;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primaryDeep : AppColors.ink;
    return Material(
      color: selected ? AppColors.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconAsset != null) ...[
                Image.asset(iconAsset!, width: 20, height: 20),
                const SizedBox(width: 8),
              ] else if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.figtree(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.search_off_rounded, size: 36, color: AppColors.mutedLight),
        const SizedBox(height: 10),
        Text(
          'No shops match this filter',
          style: AppText.ui(size: 15, weight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Try another service or turn off Open now.',
          style: AppText.ui(size: 13, color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
