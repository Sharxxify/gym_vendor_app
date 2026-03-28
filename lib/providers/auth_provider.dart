import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// Fix for "Could not find summary for library" error
// This comment helps the analyzer understand the library structure

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  otpSent,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  String? _errorMessage;
  String? _phoneNumber;
  String? _otpId;
  String? _userId;
  bool _isNewUser = false;

  // Getters
  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get phoneNumber => _phoneNumber;
  String? get userId => _userId;
  bool get isNewUser => _isNewUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  /// Check auth status on app start
  Future<void> checkAuthStatus() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      final isLoggedIn = await _authService.isAuthenticated();
      
      if (isLoggedIn) {
        _userId = await _authService.getUserId();
        _phoneNumber = await _authService.getPhoneNumber();
        _isNewUser = await _authService.getIsNewUser() ?? false;
        _status = AuthStatus.authenticated;
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      _status = AuthStatus.unauthenticated;
      _errorMessage = e.toString();
    }
    
    notifyListeners();
  }

  /// Send OTP to phone number
  Future<bool> sendOtp(String phone) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.sendOtp(phone);
      
      if (result['success'] == true) {
        _phoneNumber = phone;
        _otpId = result['otp_id'];
        _status = AuthStatus.otpSent;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Failed to send OTP';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Verify OTP
  Future<bool> verifyOtp(String otp) async {
    if (_phoneNumber == null) {
      _errorMessage = 'Phone number not found';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.verifyOtp(_phoneNumber!, otp, _otpId);
      
      if (result['success'] == true) {
        _userId = result['user']?['user_id'];
        _isNewUser = result['is_new_user'] ?? false;
        _status = AuthStatus.authenticated;
        
        debugPrint('🔐 OTP verification successful');
        debugPrint('📞 Phone number: $_phoneNumber');
        debugPrint('👤 User ID: $_userId');
        debugPrint('🆕 Is New User: $_isNewUser');
        
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Invalid OTP';
        _status = AuthStatus.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Resend OTP
  Future<bool> resendOtp() async {
    if (_phoneNumber == null) {
      _errorMessage = 'Phone number not found';
      return false;
    }

    try {
      final result = await _authService.resendOtp(_phoneNumber!);
      return result['success'] == true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  /// Logout
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    await _authService.logout();
    
    _userId = null;
    _phoneNumber = null;
    _otpId = null;
    _isNewUser = false;
    _status = AuthStatus.unauthenticated;
    
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Reset to initial state
  void resetToInitial() {
    _status = AuthStatus.initial;
    _phoneNumber = null;
    _otpId = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Handle unauthorized response (token expired)
  void handleUnauthorized() {
    logout();
  }
}
