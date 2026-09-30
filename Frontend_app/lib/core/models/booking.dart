enum BookingStatus {
  pending,
  accepted,
  inProgress,
  completed,
  cancelled,
  rejected,
  upcoming; // Backward compatibility alias for accepted/pending

  static BookingStatus fromString(String? value) {
    if (value == null) return BookingStatus.pending;
    return switch (value.toLowerCase()) {
      'pending' => BookingStatus.pending,
      'accepted' => BookingStatus.accepted,
      'in_progress' || 'inprogress' => BookingStatus.inProgress,
      'completed' => BookingStatus.completed,
      'cancelled' || 'canceled' => BookingStatus.cancelled,
      'rejected' => BookingStatus.rejected,
      'upcoming' => BookingStatus.upcoming,
      _ => BookingStatus.pending,
    };
  }

  String get label => switch (this) {
    BookingStatus.pending => 'Pending Approval',
    BookingStatus.accepted || BookingStatus.upcoming => 'Accepted',
    BookingStatus.inProgress => 'In Progress',
    BookingStatus.completed => 'Completed',
    BookingStatus.cancelled => 'Cancelled',
    BookingStatus.rejected => 'Rejected',
  };

  bool get isOngoing =>
      this == BookingStatus.pending ||
      this == BookingStatus.accepted ||
      this == BookingStatus.inProgress ||
      this == BookingStatus.upcoming;

  bool get isPast =>
      this == BookingStatus.completed ||
      this == BookingStatus.cancelled ||
      this == BookingStatus.rejected;
}

class Booking {
  const Booking({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.shopImageUrl,
    required this.service,
    required this.whenLabel,
    required this.status,
    required this.price,
    this.priceMinor,
    this.currency = 'INR',
    this.scheduledDate = '',
    this.startAt = '',
    this.endAt = '',
    this.carWashArea = '',
    this.carWashCity = '',
    this.carWashFormattedAddress = '',
    this.serviceCategory = '',
    this.serviceDurationMinutes = 30,
    this.customerName,
    this.customerPhone,
    this.vehicleRegistration,
    this.createdAt,
    this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final shopId =
        json['carWashId']?.toString() ?? json['shopId']?.toString() ?? '';

    final carWashMap = json['carWash'] is Map<String, dynamic>
        ? json['carWash'] as Map<String, dynamic>
        : (json['carWashSnapshot'] is Map<String, dynamic>
              ? json['carWashSnapshot'] as Map<String, dynamic>
              : null);

    final shopName =
        carWashMap?['name']?.toString() ??
        json['shopName']?.toString() ??
        'Car Wash';
    final shopImageUrl =
        carWashMap?['coverImageUrl']?.toString() ??
        json['shopImageUrl']?.toString() ??
        '';

    final addressMap = carWashMap?['address'] is Map<String, dynamic>
        ? carWashMap!['address'] as Map<String, dynamic>
        : null;
    final carWashArea = addressMap?['area']?.toString() ?? '';
    final carWashCity = addressMap?['city']?.toString() ?? '';
    final carWashFormattedAddress =
        addressMap?['formattedAddress']?.toString() ?? '';

    final serviceMap = json['service'] is Map<String, dynamic>
        ? json['service'] as Map<String, dynamic>
        : (json['serviceSnapshot'] is Map<String, dynamic>
              ? json['serviceSnapshot'] as Map<String, dynamic>
              : null);

    final service =
        serviceMap?['name']?.toString() ??
        json['service']?.toString() ??
        'Car Wash';
    final serviceCategory = serviceMap?['category']?.toString() ?? '';
    final serviceDurationMinutes =
        (serviceMap?['durationMinutes'] as num?)?.toInt() ?? 30;

    final customerMap = json['customer'] is Map<String, dynamic>
        ? json['customer'] as Map<String, dynamic>
        : (json['customerSnapshot'] is Map<String, dynamic>
              ? json['customerSnapshot'] as Map<String, dynamic>
              : null);
    final customerName =
        customerMap?['displayName']?.toString() ??
        json['customerName']?.toString();
    final customerPhone =
        customerMap?['phoneNumber']?.toString() ??
        json['customerPhone']?.toString();

    final scheduledDate =
        json['scheduledDate']?.toString() ??
        json['availabilityDate']?.toString() ??
        '';
    final startAt =
        json['startAt']?.toString() ?? json['slotStartAt']?.toString() ?? '';
    final endAt =
        json['endAt']?.toString() ?? json['slotEndAt']?.toString() ?? '';

    final whenLabel =
        json['whenLabel']?.toString() ??
        (scheduledDate.isNotEmpty && startAt.isNotEmpty
            ? '$scheduledDate · $startAt'
            : (startAt.isNotEmpty ? startAt : 'Scheduled'));

    final statusStr = json['status']?.toString();
    final status = BookingStatus.fromString(statusStr);

    final priceMinor = (json['priceMinor'] as num?)?.toInt();
    final price = priceMinor != null
        ? priceMinor ~/ 100
        : ((json['price'] as num?)?.toInt() ?? 250);

    return Booking(
      id: id,
      shopId: shopId,
      shopName: shopName,
      shopImageUrl: shopImageUrl,
      service: service,
      whenLabel: whenLabel,
      status: status,
      price: price,
      priceMinor: priceMinor ?? (price * 100),
      currency: json['currency']?.toString() ?? 'INR',
      scheduledDate: scheduledDate,
      startAt: startAt,
      endAt: endAt,
      carWashArea: carWashArea,
      carWashCity: carWashCity,
      carWashFormattedAddress: carWashFormattedAddress,
      serviceCategory: serviceCategory,
      serviceDurationMinutes: serviceDurationMinutes,
      customerName: customerName,
      customerPhone: customerPhone,
      vehicleRegistration:
          (json['vehicle'] as Map<String, dynamic>?)?['registrationNumber']
              ?.toString(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  final String id;
  final String shopId;
  final String shopName;
  final String shopImageUrl;
  final String service;
  final String whenLabel;
  final BookingStatus status;
  final int price;

  final int? priceMinor;
  final String currency;
  final String scheduledDate;
  final String startAt;
  final String endAt;
  final String carWashArea;
  final String carWashCity;
  final String carWashFormattedAddress;
  final String serviceCategory;
  final int serviceDurationMinutes;
  final String? customerName;
  final String? customerPhone;
  final String? vehicleRegistration;
  final dynamic createdAt;
  final dynamic updatedAt;

  bool get canCancel => status == BookingStatus.pending;
  String get displayPrice => '₹$price';

  Booking copyWith({
    String? id,
    String? shopId,
    String? shopName,
    String? shopImageUrl,
    String? service,
    String? whenLabel,
    BookingStatus? status,
    int? price,
    int? priceMinor,
    String? currency,
    String? scheduledDate,
    String? startAt,
    String? endAt,
    String? carWashArea,
    String? carWashCity,
    String? carWashFormattedAddress,
    String? serviceCategory,
    int? serviceDurationMinutes,
    String? customerName,
    String? customerPhone,
  }) {
    return Booking(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
      shopImageUrl: shopImageUrl ?? this.shopImageUrl,
      service: service ?? this.service,
      whenLabel: whenLabel ?? this.whenLabel,
      status: status ?? this.status,
      price: price ?? this.price,
      priceMinor: priceMinor ?? this.priceMinor,
      currency: currency ?? this.currency,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      carWashArea: carWashArea ?? this.carWashArea,
      carWashCity: carWashCity ?? this.carWashCity,
      carWashFormattedAddress:
          carWashFormattedAddress ?? this.carWashFormattedAddress,
      serviceCategory: serviceCategory ?? this.serviceCategory,
      serviceDurationMinutes:
          serviceDurationMinutes ?? this.serviceDurationMinutes,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehicleRegistration: vehicleRegistration,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
