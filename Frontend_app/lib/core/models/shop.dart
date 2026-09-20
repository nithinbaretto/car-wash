import '../services/location_catalog.dart';

class Shop {
  const Shop({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
    required this.isOpen,
    required this.nextAvailable,
    required this.priceFrom,
    required this.services,
    required this.address,
    required this.about,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final bool isOpen;
  final String nextAvailable;
  final int priceFrom;
  final List<String> services;
  final String address;
  final String about;
  final double latitude;
  final double longitude;

  double distanceFrom(double lat, double lng) {
    return LocationCatalog.distanceKm(lat, lng, latitude, longitude);
  }

  String distanceLabel({double? fromLat, double? fromLng}) {
    final km = (fromLat != null && fromLng != null)
        ? distanceFrom(fromLat, fromLng)
        : distanceKm;
    return '${km.toStringAsFixed(1)}km';
  }

  bool matchesService(String filter) {
    if (filter == 'All') return true;
    final tags = services.map((s) => s.toLowerCase()).join(' ');
    return switch (filter) {
      'Quick' =>
        tags.contains('car wash') ||
            tags.contains('wax') ||
            tags.contains('quick'),
      'Interior' => tags.contains('interior'),
      'Complete' =>
        tags.contains('complete') ||
            tags.contains('car wash') ||
            tags.contains('detail'),
      'Premium' => tags.contains('premium') || tags.contains('detail'),
      _ => true,
    };
  }
}
