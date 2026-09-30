import 'dart:math';
import '../models/booking.dart';
import '../network/api_client.dart';

class BookingApiService {
  BookingApiService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  String generateIdempotencyKey() {
    final rand = Random().nextInt(999999);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'req_${timestamp}_$rand';
  }

  /// Reserves an available slot as pending (POST /v1/bookings).
  Future<Booking> createBooking({
    required String carWashId,
    required String serviceId,
    required String date, // YYYY-MM-DD
    required String startAt, // HH:MM
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? generateIdempotencyKey();

    final response = await _api.post(
      '/v1/bookings',
      idempotencyKey: key,
      body: {
        'carWashId': carWashId,
        'serviceId': serviceId,
        'date': date,
        'startAt': startAt,
      },
    );

    final bookingData = response['booking'] as Map<String, dynamic>;
    return Booking.fromJson(bookingData);
  }

  /// Lists customer bookings (GET /v1/me/bookings?tab=ongoing|completed).
  Future<List<Booking>> getMyBookings({
    String tab = 'ongoing', // 'ongoing' or 'completed'
    int limit = 50,
  }) async {
    final response = await _api.get(
      '/v1/me/bookings',
      queryParameters: {
        'tab': tab,
        'limit': limit.clamp(1, 50),
      },
    );

    final list = response['bookings'] as List<dynamic>?;
    if (list == null) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  /// Returns booking details by ID (GET /v1/bookings/:bookingId).
  Future<Booking> getBookingDetail(String bookingId) async {
    final response = await _api.get('/v1/bookings/$bookingId');
    final bookingData = response['booking'] as Map<String, dynamic>;
    return Booking.fromJson(bookingData);
  }

  /// Cancels a pending booking and releases slot capacity (POST /v1/bookings/:bookingId/cancel).
  Future<Booking> cancelBooking(String bookingId) async {
    final response = await _api.post(
      '/v1/bookings/$bookingId/cancel',
      body: {},
    );
    final bookingData = response['booking'] as Map<String, dynamic>;
    return Booking.fromJson(bookingData);
  }
}
