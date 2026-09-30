import '../models/user_profile.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';

class UserApiService {
  UserApiService({required ApiClient apiClient}) : _api = apiClient;

  final ApiClient _api;

  /// Creates authenticated user profile on the backend (POST /v1/me/onboarding).
  /// If the profile already exists, retrieves it via GET /v1/me.
  Future<UserProfile> onboard({
    required String displayName,
    required String initialRole, // 'customer' or 'owner'
    String acceptedTermsVersion = 'v1',
    String acceptedPrivacyVersion = 'v1',
  }) async {
    try {
      final response = await _api.post(
        '/v1/me/onboarding',
        body: {
          'displayName': displayName,
          'initialRole': initialRole,
          'acceptedTermsVersion': acceptedTermsVersion,
          'acceptedPrivacyVersion': acceptedPrivacyVersion,
        },
      );
      final userData = response['user'] as Map<String, dynamic>;
      return UserProfile.fromJson(userData);
    } on ApiException catch (e) {
      if (e.code == 'PROFILE_ALREADY_ONBOARDED' || e.statusCode == 409) {
        return getProfile();
      }
      rethrow;
    }
  }

  /// Returns authenticated user profile (GET /v1/me).
  Future<UserProfile> getProfile() async {
    final response = await _api.get('/v1/me');
    final userData = response['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(userData);
  }

  /// Updates display name or photo URL (PATCH /v1/me).
  Future<UserProfile> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (photoUrl != null) body['photoUrl'] = photoUrl;

    final response = await _api.patch('/v1/me', body: body);
    final userData = response['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(userData);
  }

  /// Enrolls an active customer as owner (POST /v1/me/owner-enrollment).
  Future<UserProfile> enrollOwner() async {
    final response = await _api.post('/v1/me/owner-enrollment', body: {});
    final userData = response['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(userData);
  }

  /// Switches active role between customer and owner (PUT /v1/me/active-role).
  Future<UserProfile> switchActiveRole(String activeRole) async {
    final response = await _api.put(
      '/v1/me/active-role',
      body: {'activeRole': activeRole},
    );
    final userData = response['user'] as Map<String, dynamic>;
    return UserProfile.fromJson(userData);
  }

  /// Registers device installation ID for push notifications (POST /v1/me/devices).
  Future<void> registerDevice({
    required String installationId,
    required String fcmToken,
    required String platform, // 'android', 'ios', or 'web'
  }) async {
    await _api.post(
      '/v1/me/devices',
      body: {
        'installationId': installationId,
        'fcmToken': fcmToken,
        'platform': platform,
      },
    );
  }

  /// Removes device installation on logout (DELETE /v1/me/devices/:installationId).
  Future<void> removeDevice(String installationId) async {
    await _api.delete('/v1/me/devices/$installationId');
  }
}
