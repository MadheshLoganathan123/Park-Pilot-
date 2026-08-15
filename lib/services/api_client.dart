import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException ($statusCode): $message';
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  Future<Map<String, String>> _buildHeaders([String? token, bool forceRefresh = false]) async {
    final firebaseToken = token ?? await FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (firebaseToken != null && firebaseToken.isNotEmpty) headers['Authorization'] = 'Bearer $firebaseToken';
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    final String fullUrl = '${ApiConfig.baseUrl}$cleanPath';
    if (queryParams != null && queryParams.isNotEmpty) {
      final String queryString = Uri(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString()))).query;
      return Uri.parse('$fullUrl?$queryString');
    }
    return Uri.parse(fullUrl);
  }

  Future<dynamic> _request(
    Future<http.Response> Function(Map<String, String> headers) send, {
    String? token,
  }) async {
    var headers = await _buildHeaders(token);
    var response = await send(headers);
    if (response.statusCode == 401 && token == null) {
      headers = await _buildHeaders(null, true);
      response = await send(headers);
    }
    return _processResponse(response);
  }

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, String? token}) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      return await _request(
        (headers) => _client.get(uri, headers: headers).timeout(const Duration(seconds: 15)),
        token: token,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, String? token}) async {
    try {
      final uri = _buildUri(endpoint);
      return await _request(
        (headers) => _client
            .post(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(const Duration(seconds: 15)),
        token: token,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, String? token}) async {
    try {
      final uri = _buildUri(endpoint);
      return await _request(
        (headers) => _client
            .put(
              uri,
              headers: headers,
              body: body != null ? jsonEncode(body) : null,
            )
            .timeout(const Duration(seconds: 15)),
        token: token,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> delete(String endpoint, {String? token}) async {
    try {
      final uri = _buildUri(endpoint);
      return await _request(
        (headers) => _client.delete(uri, headers: headers).timeout(const Duration(seconds: 15)),
        token: token,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonResponse;
    try {
      jsonResponse = jsonDecode(response.body);
    } catch (_) {
      jsonResponse = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('data')) {
        return jsonResponse['data'];
      }
      return jsonResponse;
    } else {
      final message = (jsonResponse is Map<String, dynamic> && jsonResponse['message'] != null)
          ? jsonResponse['message'].toString()
          : 'HTTP Request failed with status code ${response.statusCode}';
      throw ApiException(message, response.statusCode);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is ApiException) return error;
    return ApiException('Network connection error: ${error.toString()}');
  }
}
