import '../models/app_notification.dart';
import '../network/api_client.dart';

class NotificationApiService {
  NotificationApiService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Customer notification feed (GET /v1/me/notifications).
  Future<List<AppNotification>> getNotifications({
    String type = 'all', // 'all', 'booking', 'offer', 'update'
    bool? unreadOnly,
    int limit = 50,
  }) async {
    final query = <String, dynamic>{
      'type': type,
      'limit': limit.clamp(1, 50),
    };
    if (unreadOnly == true) {
      query['unreadOnly'] = 'true';
    }

    final response = await _api.get(
      '/v1/me/notifications',
      queryParameters: query,
    );

    final list = response['notifications'] as List<dynamic>?;
    if (list == null) return [];

    return list
        .whereType<Map<String, dynamic>>()
        .map((json) => AppNotification.fromJson(json))
        .toList();
  }

  /// Marks selected or all notifications as read (POST /v1/me/notifications/read).
  Future<int> markRead({
    List<String>? notificationIds,
    bool markAll = false,
  }) async {
    final body = <String, dynamic>{};
    if (markAll) {
      body['markAll'] = true;
    } else if (notificationIds != null && notificationIds.isNotEmpty) {
      body['notificationIds'] = notificationIds;
    } else {
      body['markAll'] = true;
    }

    final response = await _api.post(
      '/v1/me/notifications/read',
      body: body,
    );

    return (response['marked'] as num?)?.toInt() ?? 0;
  }
}
