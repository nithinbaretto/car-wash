class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
    this.details,
    this.requestId,
  });

  factory ApiException.fromResponse({
    required int statusCode,
    required Map<String, dynamic> json,
  }) {
    final error = json['error'] is Map<String, dynamic>
        ? json['error'] as Map<String, dynamic>
        : null;

    final code = error?['code']?.toString() ?? 'HTTP_$statusCode';
    final message = error?['message']?.toString() ??
        json['message']?.toString() ??
        'Request failed with status $statusCode';
    final details = error?['details'] is Map<String, dynamic>
        ? error!['details'] as Map<String, dynamic>
        : null;
    final requestId = json['requestId']?.toString() ?? error?['requestId']?.toString();

    return ApiException(
      statusCode: statusCode,
      code: code,
      message: message,
      details: details,
      requestId: requestId,
    );
  }

  factory ApiException.networkError(dynamic originalError) {
    return ApiException(
      statusCode: 0,
      code: 'NETWORK_ERROR',
      message: 'Unable to connect to the server. Please check your internet connection.',
      details: {'original': originalError.toString()},
    );
  }

  final int statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  final String? requestId;

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isProfileNotFound => code == 'PROFILE_NOT_FOUND';
  bool get isSlotUnavailable => code == 'SLOT_UNAVAILABLE';

  @override
  String toString() => 'ApiException($statusCode $code): $message';
}
