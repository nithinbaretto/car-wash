class AvailabilitySlot {
  const AvailabilitySlot({
    required this.startAt,
    required this.endAt,
    required this.capacity,
    required this.availableCapacity,
    this.enabled = true,
  });

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      startAt: json['startAt']?.toString() ?? '',
      endAt: json['endAt']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 1,
      availableCapacity: (json['availableCapacity'] as num?)?.toInt() ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  final String startAt;
  final String endAt;
  final int capacity;
  final int availableCapacity;
  final bool enabled;

  bool get isAvailable => enabled && availableCapacity > 0;
  String get label => '$startAt - $endAt';

  Map<String, dynamic> toJson() {
    return {
      'startAt': startAt,
      'endAt': endAt,
      'capacity': capacity,
      'availableCapacity': availableCapacity,
      'enabled': enabled,
    };
  }
}
