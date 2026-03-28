import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // ============================================================
  // CONFIGURATION - UPDATE THESE VALUES
  // ============================================================

  // Your actual API URL - update this when backend is ready
  static const String baseUrl = "http://13.49.224.36:3000";

  // For local development:
  // static const String baseUrl = "http://192.168.1.100:3000/api/v1";
  // static const String baseUrl = "http://10.0.2.2:3000/api/v1"; // Android emulator

  // ============================================================

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _phoneNumberKey = 'phone_number';
  static const String _isNewUserKey = 'is_new_user';
  static const String _gymIdKey = 'gym_id';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _displayVideoUrlKey = 'display_video_url';

  // Token management
  static Future<String?> getToken() async {
    try {
      // Check if token is expired
      final expiryStr = await _storage.read(key: _tokenExpiryKey);
      if (expiryStr != null) {
        final expiry = DateTime.tryParse(expiryStr);
        if (expiry != null && DateTime.now().isAfter(expiry)) {
          // Token expired
          await clearAll();
          return null;
        }
      }
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('❌ Error getting token: $e');
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      // Set token expiry to 3 months from now
      final expiry = DateTime.now().add(const Duration(days: 90));
      await _storage.write(
          key: _tokenExpiryKey, value: expiry.toIso8601String());
      debugPrint('✅ Token saved successfully');
    } catch (e) {
      debugPrint('❌ Error saving token: $e');
    }
  }

  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  static Future<String?> getPhoneNumber() async {
    return await _storage.read(key: _phoneNumberKey);
  }

  static Future<void> savePhoneNumber(String phone) async {
    await _storage.write(key: _phoneNumberKey, value: phone);
  }

  static Future<bool?> getIsNewUser() async {
    final value = await _storage.read(key: _isNewUserKey);
    if (value == null) return null;
    return value.toLowerCase() == 'true';
  }

  static Future<void> saveIsNewUser(bool isNewUser) async {
    await _storage.write(key: _isNewUserKey, value: isNewUser.toString());
  }

  static Future<String?> getGymId() async {
    return await _storage.read(key: _gymIdKey);
  }

  static Future<void> saveGymId(String gymId) async {
    await _storage.write(key: _gymIdKey, value: gymId);
  }

  /// Display video URL — local cache workaround while backend doesn't return it
  static Future<String?> getDisplayVideoUrl() async {
    return await _storage.read(key: _displayVideoUrlKey);
  }

  static Future<void> saveDisplayVideoUrl(String url) async {
    await _storage.write(key: _displayVideoUrlKey, value: url);
  }

  static Future<void> clearDisplayVideoUrl() async {
    await _storage.delete(key: _displayVideoUrlKey);
  }

  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('✅ All secure storage cleared');
    } catch (e) {
      debugPrint('❌ Error clearing storage: $e');
    }
  }

  // HTTP methods
  static Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      String url = '$baseUrl$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        url += '?' +
            queryParams.entries
                .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
                .join('&');
      }

      final headers = await _getHeaders(requiresAuth);
      debugPrint('📤 GET Request: $url');
      debugPrint('📤 Headers: $headers');

      final response = await http.get(Uri.parse(url), headers: headers);
      return _handleResponse(response, 'GET', endpoint);
    } catch (e) {
      debugPrint('❌ GET Error: $e');
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  static Future<ApiResponse> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = '$baseUrl$endpoint';
      final headers = await _getHeaders(requiresAuth);

      debugPrint('📤 POST Request: $url');
      debugPrint('📤 Headers: $headers');
      debugPrint('📤 Request Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response, 'POST', endpoint);
    } catch (e) {
      debugPrint('❌ POST Error: $e');
      debugPrint('❌ POST Error Type: ${e.runtimeType}');
      debugPrint('❌ POST Error Stack: ${e.toString()}');
      
      // Enhanced error handling for network issues
      if (e is SocketException) {
        return ApiResponse(
          success: false, 
          message: 'Network error: Unable to connect to server. Please check your internet connection.',
        );
      } else if (e.toString().contains('TimeoutException')) {
        return ApiResponse(
          success: false, 
          message: 'Network error: Request timed out. Please try again.',
        );
      } else if (e.toString().contains('ClientException')) {
        return ApiResponse(
          success: false, 
          message: 'Network error: Failed to fetch data from server.',
        );
      }
      
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  static Future<ApiResponse> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = '$baseUrl$endpoint';
      final headers = await _getHeaders(requiresAuth);

      debugPrint('📤 PATCH Request: $url');
      debugPrint('📤 Headers: $headers');
      debugPrint('📤 Request Body: ${jsonEncode(body)}');

      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response, 'PATCH', endpoint);
    } catch (e) {
      debugPrint('❌ PATCH Error: $e');
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  static Future<ApiResponse> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final url = '$baseUrl$endpoint';
      final headers = await _getHeaders(requiresAuth);

      debugPrint('📤 PUT Request: $url');
      debugPrint('📤 Headers: $headers');
      debugPrint('📤 Request Body: ${jsonEncode(body)}');

      final response = await http.put(
        Uri.parse(url),
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      );
      return _handleResponse(response, 'PUT', endpoint);
    } catch (e) {
      debugPrint('❌ PUT Error: $e');
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  static Future<ApiResponse> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    try {
      final url = '$baseUrl$endpoint';
      final headers = await _getHeaders(requiresAuth);

      debugPrint('📤 DELETE Request: $url');
      debugPrint('📤 Headers: $headers');

      final response = await http.delete(Uri.parse(url), headers: headers);
      return _handleResponse(response, 'DELETE', endpoint);
    } catch (e) {
      debugPrint('❌ DELETE Error: $e');
      return ApiResponse(success: false, message: 'Network error: $e');
    }
  }

  // Upload file to S3 using presigned URL
  static Future<bool> uploadToS3(
      String presignedUrl, List<int> fileBytes, String contentType) async {
    try {
      debugPrint('📤 Uploading to S3: $presignedUrl');

      final response = await http.put(
        Uri.parse(presignedUrl),
        headers: {'Content-Type': contentType},
        body: fileBytes,
      );

      debugPrint('📥 S3 Upload Response Status: ${response.statusCode}');
      debugPrint('📥 S3 Upload Response Body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ S3 Upload Error: $e');
      return false;
    }
  }

  static Future<Map<String, String>> _getHeaders(bool requiresAuth) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (requiresAuth) {
      final token = await getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static ApiResponse _handleResponse(
      http.Response response, String method, String endpoint) {
    debugPrint(
        '═══════════════════════════════════════════════════════════════');
    debugPrint('📥 $method Response for: $endpoint');
    debugPrint('📥 Status Code: ${response.statusCode}');
    debugPrint('📥 Response Headers: ${response.headers}');
    debugPrint('📥 Response Body: ${response.body}');
    debugPrint(
        '═══════════════════════════════════════════════════════════════');

    try {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ApiResponse(
          success: data['success'] ?? true,
          data: data,
          message: data['message'],
        );
      } else if (response.statusCode == 401) {
        // Token expired or invalid
        clearAll();
        return ApiResponse(
          success: false,
          message: 'Session expired. Please login again.',
          isUnauthorized: true,
        );
      } else {
        return ApiResponse(
          success: false,
          message: data['message'] ?? 'Request failed',
          data: data,
        );
      }
    } catch (e) {
      debugPrint('❌ Error parsing response: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to parse response: $e',
      );
    }
  }
}

class ApiResponse {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;
  final bool isUnauthorized;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.isUnauthorized = false,
  });

  @override
  String toString() {
    return 'ApiResponse(success: $success, message: $message, data: $data, isUnauthorized: $isUnauthorized)';
  }
}
