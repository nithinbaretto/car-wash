import '../models/availability_slot.dart';
import '../models/booking.dart';
import '../models/shop.dart';
import '../models/shop_service.dart';
import '../network/api_client.dart';

class OwnerApiService {
  OwnerApiService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  Future<Map<String, dynamic>> getOnboarding(String shopId) async {
    return await _api.get('/v1/owner/car-washes/$shopId/onboarding')
        as Map<String, dynamic>;
  }

  Future<Shop> submitOnboarding({
    String? shopId,
    required Map<String, dynamic> body,
    required String idempotencyKey,
  }) async {
    final response = shopId == null
        ? await _api.post(
            '/v1/owner/car-washes/onboarding',
            body: body,
            idempotencyKey: idempotencyKey,
          )
        : await _api.put(
            '/v1/owner/car-washes/$shopId/onboarding',
            body: body,
            headers: {'Idempotency-Key': idempotencyKey},
          );
    return Shop.fromJson(response['carWash'] as Map<String, dynamic>);
  }

  /// Creates a car-wash shop for the authenticated owner (POST /v1/owner/car-washes).
  Future<Shop> createShop({
    required String name,
    required String contactPhone,
    required Map<String, dynamic> address,
    required Map<String, dynamic> location,
    required List<String> categories,
    String? coverImageUrl,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'contactPhone': contactPhone,
      'address': address,
      'location': location,
      'categories': categories,
    };
    if (coverImageUrl != null && coverImageUrl.isNotEmpty) {
      body['coverImageUrl'] = coverImageUrl;
    }

    final response = await _api.post('/v1/owner/car-washes', body: body);

    final shopData = response['carWash'] as Map<String, dynamic>;
    return Shop.fromJson(shopData);
  }

  /// Lists shops managed by the authenticated owner (GET /v1/owner/car-washes).
  Future<List<Shop>> getOwnerShops() async {
    final response = await _api.get('/v1/owner/car-washes');
    final list = response['carWashes'] as List<dynamic>?;
    if (list == null) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => Shop.fromJson(json))
        .toList();
  }

  /// Returns one managed shop (GET /v1/owner/car-washes/:carWashId).
  Future<Shop> getOwnerShop(String carWashId) async {
    final response = await _api.get('/v1/owner/car-washes/$carWashId');
    final shopData = response['carWash'] as Map<String, dynamic>;
    return Shop.fromJson(shopData);
  }

  /// Updates shop details or map pin (PATCH /v1/owner/car-washes/:carWashId).
  Future<Shop> updateShop(
    String carWashId,
    Map<String, dynamic> updates,
  ) async {
    final response = await _api.patch(
      '/v1/owner/car-washes/$carWashId',
      body: updates,
    );
    final shopData = response['carWash'] as Map<String, dynamic>;
    return Shop.fromJson(shopData);
  }

  /// Resubmits a rejected shop for admin review (POST /v1/owner/car-washes/:carWashId/resubmit).
  Future<void> resubmitShop(String carWashId) async {
    await _api.post('/v1/owner/car-washes/$carWashId/resubmit', body: {});
  }

  /// Adds a service to a shop (POST /v1/owner/car-washes/:carWashId/services).
  Future<ShopService> addService({
    required String carWashId,
    required String name,
    required String category, // quick, interior, complete, premium
    required int priceMinor, // in paise
    required int durationMinutes,
    bool active = true,
  }) async {
    final response = await _api.post(
      '/v1/owner/car-washes/$carWashId/services',
      body: {
        'name': name,
        'category': category,
        'priceMinor': priceMinor,
        'durationMinutes': durationMinutes,
        'active': active,
      },
    );

    final serviceData = response['service'] as Map<String, dynamic>;
    return ShopService.fromJson(serviceData);
  }

  /// Saves daily booking slots (PUT /v1/owner/car-washes/:carWashId/availability/:date).
  Future<List<AvailabilitySlot>> setAvailability({
    required String carWashId,
    required String date, // YYYY-MM-DD
    required List<Map<String, dynamic>> slots,
  }) async {
    final response = await _api.put(
      '/v1/owner/car-washes/$carWashId/availability/$date',
      body: {'slots': slots},
    );

    final list = response['slots'] as List<dynamic>?;
    if (list == null) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => AvailabilitySlot.fromJson(json))
        .toList();
  }

  /// Owner booking queue for a given date (GET /v1/owner/car-washes/:carWashId/bookings?date=...).
  Future<List<Booking>> getOwnerBookings({
    required String carWashId,
    required String date, // YYYY-MM-DD
    String? status, // 'pending', 'accepted', 'in_progress', 'completed'
    int limit = 50,
  }) async {
    final query = <String, dynamic>{'date': date, 'limit': limit.clamp(1, 50)};
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    final response = await _api.get(
      '/v1/owner/car-washes/$carWashId/bookings',
      queryParameters: query,
    );

    final list = response['bookings'] as List<dynamic>?;
    if (list == null) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  /// Accepts, rejects, starts, or completes a booking (POST /v1/owner/bookings/:bookingId/status).
  Future<Booking> updateBookingStatus({
    required String bookingId,
    required String
    status, // 'accepted', 'rejected', 'in_progress', 'completed'
  }) async {
    final response = await _api.post(
      '/v1/owner/bookings/$bookingId/status',
      body: {'status': status},
    );

    final bookingData = response['booking'] as Map<String, dynamic>;
    return Booking.fromJson(bookingData);
  }

  Future<List<ShopService>> getServices(String carWashId) async {
    final response = await _api.get('/v1/owner/car-washes/$carWashId/services');
    return (response['services'] as List<dynamic>)
        .map((item) => ShopService.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AvailabilitySlot>> getAvailability(
    String carWashId,
    String date,
  ) async {
    final response = await _api.get(
      '/v1/owner/car-washes/$carWashId/availability',
      queryParameters: {'date': date},
    );
    return (response['slots'] as List<dynamic>)
        .map((item) => AvailabilitySlot.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getEarnings(
    String carWashId,
    String date,
  ) async {
    final response = await _api.get(
      '/v1/owner/car-washes/$carWashId/earnings',
      queryParameters: {'date': date},
    );
    return response['earnings'] as Map<String, dynamic>;
  }

  Future<Booking> createWalkIn({
    required String carWashId,
    required String serviceId,
    required String customerName,
    required String vehicle,
    required String date,
    required String startAt,
    required String idempotencyKey,
  }) async {
    final response = await _api.post(
      '/v1/owner/car-washes/$carWashId/walk-ins',
      idempotencyKey: idempotencyKey,
      body: {
        'serviceId': serviceId,
        'customerName': customerName,
        'vehicle': vehicle,
        'date': date,
        'startAt': startAt,
      },
    );
    return Booking.fromJson(response['booking'] as Map<String, dynamic>);
  }
}
