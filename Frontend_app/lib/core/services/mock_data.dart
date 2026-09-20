import '../models/app_notification.dart';
import '../models/booking.dart';
import '../models/shop.dart';

abstract final class MockData {
  static const otpCode = '123456';

  static const shops = [
    Shop(
      id: 'shop-sparkle',
      name: 'Sparkle Auto Spa',
      imageUrl:
          'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?auto=format&fit=crop&w=1200&q=80',
      rating: 4.7,
      reviewCount: 325,
      distanceKm: 1.8,
      isOpen: true,
      nextAvailable: 'Today - 3:30 PM',
      priceFrom: 250,
      services: ['Car wash', 'Detailing', 'Interior cleaning'],
      address: '12, 5th Cross, Koramangala, Bengaluru',
      latitude: 12.9352,
      longitude: 77.6245,
      about:
          'Premium hand wash and detailing. Live bay availability so you can skip the queue and get back on the road.',
    ),
    Shop(
      id: 'shop-cleanride',
      name: 'CleanRide Car Spa',
      imageUrl:
          'https://images.unsplash.com/photo-1619642751034-76511d3a0d4e?auto=format&fit=crop&w=1200&q=80',
      rating: 4.6,
      reviewCount: 198,
      distanceKm: 2.4,
      isOpen: true,
      nextAvailable: 'Today - 4:15 PM',
      priceFrom: 199,
      services: ['Car wash', 'Wax', 'Interior cleaning'],
      address: 'Indiranagar 100 Feet Road, Bengaluru',
      latitude: 12.9784,
      longitude: 77.6408,
      about:
          'Fast exterior wash with ceramic options. Ideal for daily drivers who want a reliable slot.',
    ),
    Shop(
      id: 'shop-shinepro',
      name: 'Shine Pro Detailing',
      imageUrl:
          'https://images.unsplash.com/photo-1489824904134-891ab64532f1?auto=format&fit=crop&w=1200&q=80',
      rating: 4.9,
      reviewCount: 412,
      distanceKm: 3.1,
      isOpen: false,
      nextAvailable: 'Tomorrow - 9:00 AM',
      priceFrom: 349,
      services: ['Detailing', 'Premium', 'Interior cleaning'],
      address: 'HSR Layout, Sector 4, Bengaluru',
      latitude: 12.9121,
      longitude: 77.6446,
      about:
          'Studio-grade detailing for interiors and paint correction. Book premium bays in advance.',
    ),
  ];

  static Shop shopById(String id) =>
      shops.firstWhere((shop) => shop.id == id, orElse: () => shops.first);

  static const seedBookings = [
    Booking(
      id: 'b1',
      shopId: 'shop-sparkle',
      shopName: 'Sparkle Auto Spa',
      shopImageUrl:
          'https://images.unsplash.com/photo-1607860108855-64acf2078ed9?auto=format&fit=crop&w=1200&q=80',
      service: 'Complete wash',
      whenLabel: 'Today, 3:30 PM',
      status: BookingStatus.upcoming,
      price: 250,
    ),
    Booking(
      id: 'b2',
      shopId: 'shop-cleanride',
      shopName: 'CleanRide Car Spa',
      shopImageUrl:
          'https://images.unsplash.com/photo-1619642751034-76511d3a0d4e?auto=format&fit=crop&w=1200&q=80',
      service: 'Interior cleaning',
      whenLabel: 'Yesterday, 6:10 PM',
      status: BookingStatus.completed,
      price: 199,
    ),
  ];

  static const notifications = [
    AppNotification(
      id: 'n1',
      kind: NotificationKind.completed,
      title: 'Wash Completed',
      body: 'Your car wash is completed at Sparkle Auto Spa',
      timeAgo: '30 min ago',
      section: 'Today',
    ),
    AppNotification(
      id: 'n2',
      kind: NotificationKind.inProgress,
      title: 'Your car wash in progress',
      body: 'Your vehicle is being washed at Sparkle Auto Spa',
      timeAgo: '30 min ago',
      section: 'Today',
    ),
    AppNotification(
      id: 'n3',
      kind: NotificationKind.booking,
      title: 'Booking accepted',
      body: 'Sparkle Auto Spa accepted your request for today at 3:30 PM.',
      timeAgo: '45 min ago',
      section: 'Today',
    ),
    AppNotification(
      id: 'n4',
      kind: NotificationKind.offer,
      title: 'Special Offer',
      body: 'Get 20% off on Premium Wash this weekend !',
      timeAgo: '1 day ago',
      section: 'Today',
    ),
  ];

  static const vendorToday = [
    ('Priya K', 'Honda City · Complete', '3:30 PM', 'Confirmed'),
    ('Walk-in', 'Swift · Quick wash', '3:45 PM', 'Bay 2'),
    ('Arjun M', 'Creta · Interior', '4:15 PM', 'Arriving'),
  ];

  static const vendorEarnings = (today: 12450, week: 68200, pending: 3200);
}
