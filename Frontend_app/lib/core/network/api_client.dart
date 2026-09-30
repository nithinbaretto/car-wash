import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

typedef TokenProvider = Future<String?> Function();

class ApiClient {
  ApiClient({http.Client? httpClient, this.tokenProvider})
    : _client = httpClient ?? http.Client();

  final http.Client _client;
  TokenProvider? tokenProvider;

  String? _authToken;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Future<String?> _resolveToken() async {
    if (tokenProvider != null) {
      _authToken = await tokenProvider!();
      return _authToken;
    }
    return _authToken;
  }

  Future<Map<String, String>> _buildHeaders({
    String? idempotencyKey,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = await _resolveToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = ApiConfig.baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$normalizedPath';

    final uri = Uri.parse(fullUrl);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final queryMap = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value != null) {
        queryMap[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: {...uri.queryParameters, ...queryMap});
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path, queryParameters);
      final requestHeaders = await _buildHeaders(extraHeaders: headers);
      if (kDebugMode) {
        debugPrint('[API GET] $uri');
      }
      final response = await _client
          .get(uri, headers: requestHeaders)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path);
      final requestHeaders = await _buildHeaders(
        idempotencyKey: idempotencyKey,
        extraHeaders: headers,
      );
      final encodedBody = body != null ? jsonEncode(body) : null;
      if (kDebugMode) {
        debugPrint('[API POST] $uri');
      }
      final response = await _client
          .post(uri, headers: requestHeaders, body: encodedBody)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path);
      final requestHeaders = await _buildHeaders(extraHeaders: headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      if (kDebugMode) {
        debugPrint('[API PUT] $uri');
      }
      final response = await _client
          .put(uri, headers: requestHeaders, body: encodedBody)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = _buildUri(path);
      final requestHeaders = await _buildHeaders(extraHeaders: headers);
      final encodedBody = body != null ? jsonEncode(body) : null;
      if (kDebugMode) {
        debugPrint('[API PATCH] $uri');
      }
      final response = await _client
          .patch(uri, headers: requestHeaders, body: encodedBody)
          .timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  Future<void> delete(String path, {Map<String, String>? headers}) async {
    try {
      final uri = _buildUri(path);
      final requestHeaders = await _buildHeaders(extraHeaders: headers);
      if (kDebugMode) {
        debugPrint('[API DELETE] $uri');
      }
      final response = await _client
          .delete(uri, headers: requestHeaders)
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 204) {
        return;
      }
      _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException.networkError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (kDebugMode) {
      debugPrint('[API RESPONSE] ${response.statusCode}');
    }

    if (response.statusCode == 204) {
      return null;
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw ApiException(
        statusCode: response.statusCode,
        code: 'PARSE_ERROR',
        message: 'The server returned an invalid response.',
      );
    }

    final success = json['success'] == true;
    if (!success || response.statusCode >= 400) {
      throw ApiException.fromResponse(
        statusCode: response.statusCode,
        json: json,
      );
    }

    return json['data'];
  }
}
