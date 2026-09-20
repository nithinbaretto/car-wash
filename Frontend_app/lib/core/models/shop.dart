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
}
