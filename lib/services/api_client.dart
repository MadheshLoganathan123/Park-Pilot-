import 'dart:convert';
import 'package:http/http.dart' as http;
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

  Map<String, String> _buildHeaders([String? token]) {
    final defaultToken = token ?? 'dev-token-customer';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $defaultToken',
    };
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

  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams, String? token}) async {
    try {
      final uri = _buildUri(endpoint, queryParams);
      final response = await _client.get(uri, headers: _buildHeaders(token)).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body, String? token}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<dynamic> put(String endpoint, {dynamic body, String? token}) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(token),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
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
