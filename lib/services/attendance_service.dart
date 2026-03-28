import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';

class AttendanceService {
  /// Get attendance overview for home screen
  /// GET /api/v1/gym/attendance/overview
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> getAttendanceOverview({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('📊 Fetching attendance overview...');

    final queryParams = <String, String>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
    }

    final response = await ApiClient.get(
      '/api/v1/gym/attendance/overview',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );

    debugPrint('📥 Get Attendance Overview Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'data': response.data,
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to fetch attendance overview',
      };
    }
  }

  /// Mark customer attendance via QR scan (old system)
  /// POST /api/v1/gym/attendance/mark
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> markAttendanceOld({
    required String customerId,
    String? qrCode,
  }) async {
    debugPrint('✅ Marking attendance for: $customerId');

    final body = <String, dynamic>{
      'customer_id': customerId,
    };
    if (qrCode != null) {
      body['qr_code'] = qrCode;
    }

    final response = await ApiClient.post('/api/v1/gym/attendance/mark', body: body);

    debugPrint('📥 Mark Attendance Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'message': response.data!['message'] ?? 'Attendance marked successfully',
        'attendance': response.data!['attendance'],
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to mark attendance',
      };
    }
  }

  /// Mark attendance via QR code scan (new one-time scan system)
  /// POST /api/v1/attendance/check-in
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> markAttendance({
    required String qrCode,
    required String gymId,
    double? latitude,
    double? longitude,
  }) async {
    debugPrint('🎫 Marking attendance for gym: $gymId');

    final body = <String, dynamic>{
      'qr_code': qrCode,
      'gym_id': gymId,
    };
    if (latitude != null) {
      body['latitude'] = latitude;
    }
    if (longitude != null) {
      body['longitude'] = longitude;
    }

    final response = await ApiClient.post('/api/v1/attendance/check-in', body: body);

    debugPrint('📥 Mark Attendance Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'message': response.data!['message'] ?? 'Attendance marked successfully',
        'attendance': response.data!['attendance'],
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to mark attendance',
      };
    }
  }

  /// Get today's attendance list
  /// GET /api/v1/gym/attendance/today
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> getTodayAttendance() async {
    debugPrint('📅 Fetching today\'s attendance...');

    final response = await ApiClient.get('/api/v1/gym/attendance/today');

    debugPrint('📥 Get Today Attendance Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'data': response.data,
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to fetch today\'s attendance',
      };
    }
  }

  /// Get attendance calendar data for a month
  /// GET /api/v1/gym/attendance/monthly
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> getMonthlyAttendance({
    required int year,
    required int month,
  }) async {
    debugPrint('📆 Fetching monthly attendance for $month/$year');

    final response = await ApiClient.get(
      '/api/v1/gym/attendance/monthly',
      queryParams: {
        'month': month.toString(),
        'year': year.toString(),
      },
    );

    debugPrint('📥 Get Monthly Attendance Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'year': response.data!['year'] ?? year,
        'month': response.data!['month'] ?? month,
        'days_in_month': response.data!['days_in_month'],
        'attendance': response.data!['attendance'],
        'total_visits': response.data!['total_visits'],
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to fetch monthly attendance',
      };
    }
  }
}
