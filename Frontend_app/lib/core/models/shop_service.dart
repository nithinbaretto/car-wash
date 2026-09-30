class ShopService {
  const ShopService({
    required this.id,
    required this.name,
    required this.category,
    required this.priceMinor,
    required this.durationMinutes,
    this.active = true,
  });

  factory ShopService.fromJson(Map<String, dynamic> json) {
    return ShopService(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? 'quick',
      priceMinor: (json['priceMinor'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 30,
      active: json['active'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String category;
  final int priceMinor;
  final int durationMinutes;
  final bool active;

  double get priceInRupees => priceMinor / 100.0;
  String get formattedPrice => '₹${(priceMinor / 100).toStringAsFixed(0)}';
  String get formattedDuration => '${durationMinutes}m';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'priceMinor': priceMinor,
      'durationMinutes': durationMinutes,
      'active': active,
    };
  }
}
