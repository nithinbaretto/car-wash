import '../models/availability_slot.dart';
import '../models/shop.dart';
import '../network/api_client.dart';

class DiscoveryApiService {
  DiscoveryApiService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Returns supported wash categories (GET /v1/categories).
  Future<List<Map<String, String>>> getCategories() async {
    final response = await _api.get('/v1/categories');
    final list = response['categories'] as List<dynamic>?;
    if (list == null) return [];
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return {
          'id': item['id']?.toString() ?? '',
          'label': item['label']?.toString() ?? '',
        };
      }
      return {'id': item.toString(), 'label': item.toString()};
    }).toList();
  }

  /// Finds active car wash shops within radius (GET /v1/car-washes/nearby).
  Future<List<Shop>> getNearbyShops({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    String? category,
    int limit = 20,
  }) async {
    final query = <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      'radiusKm': radiusKm.clamp(1.0, 10.0),
      'limit': limit.clamp(1, 50),
    };

    if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
      query['category'] = category.toLowerCase();
    }

    final response = await _api.get(
      '/v1/car-washes/nearby',
      queryParameters: query,
    );

    final list = response['carWashes'] as List<dynamic>?;
    if (list == null) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => Shop.fromJson(json))
        .toList();
  }

  /// Returns public shop details and active services (GET /v1/car-washes/:carWashId).
  Future<Shop> getShopDetail(String carWashId) async {
    final response = await _api.get('/v1/car-washes/$carWashId');
    final shopData = response['carWash'] as Map<String, dynamic>;
    return Shop.fromJson(shopData);
  }

  /// Returns bookable slots for a date (GET /v1/car-washes/:carWashId/availability?date=YYYY-MM-DD).
  Future<List<AvailabilitySlot>> getAvailability({
    required String carWashId,
    required String date,
  }) async {
    final response = await _api.get(
      '/v1/car-washes/$carWashId/availability',
      queryParameters: {'date': date},
    );

    final list = response['slots'] as List<dynamic>?;
    if (list == null) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => AvailabilitySlot.fromJson(json))
        .toList();
  }
}
