import '../models/shop.dart';
import '../network/api_client.dart';

class FavouritesApiService {
  FavouritesApiService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Returns saved active shops for current user (GET /v1/me/favourites).
  Future<List<Shop>> getFavourites({int limit = 50}) async {
    final response = await _api.get(
      '/v1/me/favourites',
      queryParameters: {'limit': limit.clamp(1, 50)},
    );

    final list = response['carWashes'] as List<dynamic>?;
    if (list == null) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => Shop.fromJson(json))
        .toList();
  }

  /// Saves a shop idempotently (PUT /v1/me/favourites/:carWashId).
  Future<void> addFavourite(String carWashId) async {
    await _api.put('/v1/me/favourites/$carWashId');
  }

  /// Removes a saved shop idempotently (DELETE /v1/me/favourites/:carWashId).
  Future<void> removeFavourite(String carWashId) async {
    await _api.delete('/v1/me/favourites/$carWashId');
  }
}
