import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';

class AuthService {
  /// Send OTP to phone number
  /// POST /api/v1/auth/send-otp
  Future<Map<String, dynamic>> sendOtp(String phone) async {
    debugPrint('📱 Sending OTP to: $phone');
    
    final response = await ApiClient.post(
      '/auth/send-otp',
      body: {'phone': phone},
      requiresAuth: false,
    );

    debugPrint('📥 Send OTP Response: ${response.data}');

    if (response.success && response.data != null) {
      await ApiClient.savePhoneNumber(phone);
      return {
        'success': true,
        'message': response.data!['message'] ?? 'OTP sent successfully',
        'otp_id': response.data!['otp_id'],
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to send OTP',
      };
    }
  }

  /// Verify OTP and get auth token
  /// POST /api/v1/auth/verify-otp
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp, String? otpId) async {
    debugPrint('🔐 Verifying OTP for: $phone');
    
    final body = <String, dynamic>{
      'phone': phone,
      'otp': otp,
    };
    if (otpId != null) {
      body['otp_id'] = otpId;
    }

    final response = await ApiClient.post(
      '/auth/verify-otp',
      body: body,
      requiresAuth: false,
    );

    debugPrint('📥 Verify OTP Response: ${response.data}');

    if (response.success && response.data != null) {
      final data = response.data!;
      
      // Save auth token
      if (data['auth_token'] != null) {
        await ApiClient.saveToken(data['auth_token']);
        debugPrint('✅ Auth token saved');
      }
      
      // Save user details
      if (data['user'] != null) {
        final user = data['user'];
        if (user['user_id'] != null) {
          await ApiClient.saveUserId(user['user_id']);
        }
      }
      
      // Save is_new_user flag - this determines flow
      final isNewUser = data['is_new_user'] ?? false;
      await ApiClient.saveIsNewUser(isNewUser);
      
      debugPrint('📞 Phone number: $phone');
      debugPrint('👤 User ID: ${data['user']?['user_id']}');
      debugPrint('🆕 Is New User: $isNewUser');
      debugPrint('✅ OTP verification successful');
      
      return {
        'success': true,
        'message': data['message'] ?? 'OTP verified',
        'user': data['user'],
        'auth_token': data['auth_token'],
        'is_new_user': isNewUser,
      };
    } else {
      debugPrint('❌ OTP verification failed: ${response.message}');
      return {
        'success': false,
        'message': response.message ?? 'Invalid OTP',
      };
    }
  }

  /// Resend OTP
  /// POST /api/v1/auth/resend-otp
  Future<Map<String, dynamic>> resendOtp(String phone) async {
    debugPrint('🔄 Resending OTP to: $phone');
    
    final response = await ApiClient.post(
      '/auth/resend-otp',
      body: {'phone': phone},
      requiresAuth: false,
    );

    debugPrint('📥 Resend OTP Response: ${response.data}');

    return {
      'success': response.success,
      'message': response.message ?? (response.success ? 'OTP re-sent successfully' : 'Failed to resend OTP'),
    };
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    return await ApiClient.isAuthenticated();
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    return await ApiClient.getUserId();
  }

  /// Get stored phone number
  Future<String?> getPhoneNumber() async {
    return await ApiClient.getPhoneNumber();
  }

  /// Get is_new_user status
  Future<bool?> getIsNewUser() async {
    return await ApiClient.getIsNewUser();
  }

  /// Get gym ID
  Future<String?> getGymId() async {
    return await ApiClient.getGymId();
  }

  /// Logout - clear all stored data
  Future<void> logout() async {
    debugPrint('🚪 Logging out...');
    await ApiClient.clearAll();
  }

  /// Check token validity
  Future<bool> isTokenValid() async {
    final token = await ApiClient.getToken();
    return token != null && token.isNotEmpty;
  }
}
