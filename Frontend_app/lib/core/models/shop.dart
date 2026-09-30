import '../services/location_catalog.dart';
import 'shop_service.dart';

class ShopAddress {
  const ShopAddress({
    this.line1 = '',
    this.area = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.formattedAddress = '',
  });

  factory ShopAddress.fromJson(dynamic json) {
    if (json is String) {
      return ShopAddress(formattedAddress: json);
    }
    if (json is Map<String, dynamic>) {
      return ShopAddress(
        line1: json['line1']?.toString() ?? '',
        area: json['area']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        postalCode: json['postalCode']?.toString() ?? '',
        formattedAddress:
            json['formattedAddress']?.toString() ??
            '${json['area'] ?? ''}, ${json['city'] ?? ''}'.trim(),
      );
    }
    return const ShopAddress();
  }

  final String line1;
  final String area;
  final String city;
  final String state;
  final String postalCode;
  final String formattedAddress;

  Map<String, dynamic> toJson() {
    return {
      'line1': line1,
      'area': area,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'formattedAddress': formattedAddress,
    };
  }

  @override
  String toString() =>
      formattedAddress.isNotEmpty ? formattedAddress : '$area, $city';
}

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
    this.addressDetail,
    this.startingPriceMinor,
    this.currency = 'INR',
    this.isFavourite = false,
    this.contactPhone,
    this.status = 'active',
    this.reviewReason,
    this.serviceDetails = const [],
    this.categoryIds = const [],
  });

  factory Shop.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    final coverImageUrl =
        json['coverImageUrl']?.toString() ?? json['imageUrl']?.toString() ?? '';

    final ratingMap = json['rating'] is Map<String, dynamic>
        ? json['rating'] as Map<String, dynamic>
        : null;
    final rating =
        (ratingMap?['average'] as num?)?.toDouble() ??
        (json['ratingAverage'] as num?)?.toDouble() ??
        (json['rating'] is num ? (json['rating'] as num).toDouble() : null) ??
        0.0;
    final reviewCount =
        (ratingMap?['count'] as num?)?.toInt() ??
        (json['ratingCount'] as num?)?.toInt() ??
        (json['reviewCount'] as num?)?.toInt() ??
        0;

    final distanceKm = (json['distanceKm'] as num?)?.toDouble() ?? 0.0;

    final locationMap = json['location'] is Map<String, dynamic>
        ? json['location'] as Map<String, dynamic>
        : null;
    final latitude =
        (locationMap?['latitude'] as num?)?.toDouble() ??
        (json['latitude'] as num?)?.toDouble() ??
        12.9352;
    final longitude =
        (locationMap?['longitude'] as num?)?.toDouble() ??
        (json['longitude'] as num?)?.toDouble() ??
        77.6245;

    final addressData = json['address'];
    final addressObj = ShopAddress.fromJson(addressData);
    final addressStr = addressObj.formattedAddress.isNotEmpty
        ? addressObj.formattedAddress
        : (json['address']?.toString() ?? 'Bengaluru');

    final startingPriceMinor =
        (json['startingPriceMinor'] as num?)?.toInt() ??
        (json['minPriceMinor'] as num?)?.toInt();
    final priceFrom = startingPriceMinor != null
        ? startingPriceMinor ~/ 100
        : ((json['priceFrom'] as num?)?.toInt() ?? 250);

    final rawServices = json['services'] as List<dynamic>?;
    final serviceDetails = <ShopService>[];
    final serviceStrings = <String>[];

    if (rawServices != null) {
      for (final s in rawServices) {
        if (s is Map<String, dynamic>) {
          final svc = ShopService.fromJson(s);
          serviceDetails.add(svc);
          serviceStrings.add(svc.name);
        } else if (s != null) {
          serviceStrings.add(s.toString());
        }
      }
    }

    final rawCategories = json['categories'] as List<dynamic>?;
    final categoryIds = rawCategories?.map((c) => c.toString()).toList() ?? [];

    final isFav = json['isFavourite'] as bool? ?? false;
    final phone = json['contactPhone']?.toString();
    final status = json['status']?.toString() ?? 'active';

    final isOpen = json['isOpen'] as bool? ?? true;
    final nextAvailable =
        json['nextAvailable']?.toString() ?? 'Today - Live bays';
    final about =
        json['about']?.toString() ??
        'Professional automotive detailing and car wash services with state-of-the-art equipment.';

    return Shop(
      id: id,
      name: name,
      imageUrl: coverImageUrl,
      rating: rating,
      reviewCount: reviewCount,
      distanceKm: distanceKm,
      isOpen: isOpen,
      nextAvailable: nextAvailable,
      priceFrom: priceFrom,
      services: serviceStrings,
      address: addressStr,
      about: about,
      latitude: latitude,
      longitude: longitude,
      addressDetail: addressObj,
      startingPriceMinor: startingPriceMinor,
      currency: json['currency']?.toString() ?? 'INR',
      isFavourite: isFav,
      contactPhone: phone,
      status: status,
      reviewReason: (json['review'] is Map ? json['review']['reason'] : null)
          ?.toString(),
      serviceDetails: serviceDetails,
      categoryIds: categoryIds,
    );
  }

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

  final ShopAddress? addressDetail;
  final int? startingPriceMinor;
  final String currency;
  final bool isFavourite;
  final String? contactPhone;
  final String status;
  final String? reviewReason;
  final List<ShopService> serviceDetails;
  final List<String> categoryIds;

  String get displayPrice => '₹$priceFrom';
  String get coverImageUrl => imageUrl;

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
    final filterLower = filter.toLowerCase();
    if (categoryIds.contains(filterLower)) return true;

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

  Shop copyWith({
    String? id,
    String? name,
    String? imageUrl,
    double? rating,
    int? reviewCount,
    double? distanceKm,
    bool? isOpen,
    String? nextAvailable,
    int? priceFrom,
    List<String>? services,
    String? address,
    String? about,
    double? latitude,
    double? longitude,
    ShopAddress? addressDetail,
    int? startingPriceMinor,
    String? currency,
    bool? isFavourite,
    String? contactPhone,
    String? status,
    String? reviewReason,
    List<ShopService>? serviceDetails,
    List<String>? categoryIds,
  }) {
    return Shop(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      distanceKm: distanceKm ?? this.distanceKm,
      isOpen: isOpen ?? this.isOpen,
      nextAvailable: nextAvailable ?? this.nextAvailable,
      priceFrom: priceFrom ?? this.priceFrom,
      services: services ?? this.services,
      address: address ?? this.address,
      about: about ?? this.about,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressDetail: addressDetail ?? this.addressDetail,
      startingPriceMinor: startingPriceMinor ?? this.startingPriceMinor,
      currency: currency ?? this.currency,
      isFavourite: isFavourite ?? this.isFavourite,
      contactPhone: contactPhone ?? this.contactPhone,
      status: status ?? this.status,
      reviewReason: reviewReason ?? this.reviewReason,
      serviceDetails: serviceDetails ?? this.serviceDetails,
      categoryIds: categoryIds ?? this.categoryIds,
    );
  }
}
