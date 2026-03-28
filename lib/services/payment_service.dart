import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';

class PaymentService {
  /// Create Elite Payment Order
  /// POST /api/v1/payments/elite/create-order
  /// Auth: Authorization: Bearer <JWT>
  /// Body: None required
  /// Prerequisite: Gym owner must have a gym profile created
  /// Response: Payment link with order details
  Future<Map<String, dynamic>> createElitePaymentOrder() async {
    debugPrint('💳 Creating Elite payment order...');

    final response =
        await ApiClient.post('/api/v1/payments/elite/create-order');

    debugPrint('📥 Create Elite Payment Order Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'order_id': response.data!['order_id'],
        'payment_link_id': response.data!['payment_link_id'],
        'payment_link_url': response.data!['payment_link_url'],
        'amount': response.data!['amount'],
        'currency': response.data!['currency'],
        'plan_id': response.data!['plan_id'],
        'message': response.data!['message'] ?? 'Payment link created successfully',
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to create payment order',
        'error_code': response.data?['error_code'],
      };
    }
  }


  /// Verify Elite Plan payment
  /// POST /api/v1/payments/elite/verify
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> verifyElitePayment({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    debugPrint('✅ Verifying Elite payment...');

    final response = await ApiClient.post(
      '/payments/elite/verify',
      body: {
        'order_id': orderId,
        'payment_id': paymentId,
        'signature': signature,
      },
    );

    debugPrint('📥 Verify Elite Payment Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'message': response.data!['message'] ?? 'Payment verified successfully',
        'elite_status': response.data!['elite_status'],
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Payment verification failed',
        'error_code': response.data?['error_code'],
      };
    }
  }

  /// Get Elite Plan details
  /// GET /api/v1/payments/elite/plans
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> getElitePlanDetails() async {
    debugPrint('📋 Fetching Elite plan details...');

    final response = await ApiClient.get('/payments/elite/plans');

    debugPrint('📥 Get Elite Plan Details Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'plans': response.data!['plans'],
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to fetch Elite plan details',
      };
    }
  }

  /// Get current Elite subscription status
  /// GET /api/v1/gym/elite/status
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> getEliteStatus() async {
    debugPrint('📊 Fetching Elite status...');

    final response = await ApiClient.get('/gym/elite/status');

    debugPrint('📥 Get Elite Status Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'is_elite': response.data!['is_elite'] ?? false,
        'plan': response.data!['plan'],
        'valid_till': response.data!['valid_till'],
      };
    } else {
      return {
        'success': false,
        'is_elite': false,
        'message': response.message ?? 'Failed to fetch Elite status',
      };
    }
  }

  /// Check membership status for a specific gym
  /// GET /api/v1/memberships/check/:gym_id
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> checkMembershipStatus(String gymId) async {
    debugPrint('🎫 Checking membership status for gym: $gymId');

    final response = await ApiClient.get('/api/v1/memberships/check/$gymId');

    debugPrint('📥 Check Membership Status Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'is_member': response.data!['is_member'] ?? false,
        'membership_type': response.data!['membership_type'],
        'end_date': response.data!['end_date'],
        'booking_id': response.data!['booking_id'],
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to check membership status',
      };
    }
  }

  /// Get multi-gym pricing
  /// GET /api/v1/memberships/multi-gym-pricing
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> getMultiGymPricing() async {
    debugPrint('💰 Fetching multi-gym pricing...');

    final response = await ApiClient.get('/api/v1/memberships/multi-gym-pricing');

    debugPrint('📥 Get Multi-Gym Pricing Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'pricing': response.data!['pricing'],
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to fetch multi-gym pricing',
      };
    }
  }
}
