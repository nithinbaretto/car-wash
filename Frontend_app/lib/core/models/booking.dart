enum BookingStatus { upcoming, inProgress, completed, cancelled }

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
  });

  final String id;
  final String shopId;
  final String shopName;
  final String shopImageUrl;
  final String service;
  final String whenLabel;
  final BookingStatus status;
  final int price;
}
