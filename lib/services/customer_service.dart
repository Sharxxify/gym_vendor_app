import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

class CustomerService {
  // ----------------------------------------------------------------
  // 1. GET /api/v1/gym/customers/subscriptions
  //    All bookings/purchases at this gym (memberships + services)
  // ----------------------------------------------------------------
  Future<Map<String, dynamic>> getSubscriptions({
    String type = 'all',
    String status = 'all',
    int page = 1,
    int limit = 50,
  }) async {
    debugPrint('💰 Fetching gym subscriptions (type=$type, status=$status)...');

    final response = await ApiClient.get(
      '/api/v1/gym/customers/subscriptions',
      queryParams: {
        'type': type,
        'status': status,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    debugPrint('📥 Subscriptions Response: ${response.data}');

    if (response.success && response.data != null) {
      return {'success': true, 'data': response.data};
    } else if (response.isUnauthorized) {
      return {'success': false, 'message': 'Session expired', 'unauthorized': true};
    } else {
      return {'success': false, 'message': response.message ?? 'Failed to fetch subscriptions'};
    }
  }

  // ----------------------------------------------------------------
  // 2. GET /api/v1/gym/customers/checkins
  //    All check-in records at this gym
  // ----------------------------------------------------------------
  Future<Map<String, dynamic>> getCheckins({
    String? userId,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 50,
  }) async {
    debugPrint('📅 Fetching gym check-ins...');

    final Map<String, String> params = {
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (userId != null) params['user_id'] = userId;
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;

    final response = await ApiClient.get('/api/v1/gym/customers/checkins', queryParams: params);

    debugPrint('📥 Check-ins Response: ${response.data}');

    if (response.success && response.data != null) {
      return {'success': true, 'data': response.data};
    } else {
      return {'success': false, 'message': response.message ?? 'Failed to fetch check-ins'};
    }
  }

  // ----------------------------------------------------------------
  // 3. GET /api/v1/gym/customers/members
  //    All members with active paid memberships
  // ----------------------------------------------------------------
  Future<Map<String, dynamic>> getMembers({
    bool activeOnly = true,
    int page = 1,
    int limit = 50,
  }) async {
    debugPrint('👥 Fetching gym members (activeOnly=$activeOnly)...');
  
    final response = await ApiClient.get(
      '/api/v1/gym/customers/members',
      queryParams: {
        'active_only': activeOnly.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    debugPrint('📥 Members Response: ${response.data}');

    if (response.success && response.data != null) {
      return {'success': true, 'data': response.data};
    } else if (response.isUnauthorized) {
      return {'success': false, 'message': 'Session expired', 'unauthorized': true};
    } else {
      return {'success': false, 'message': response.message ?? 'Failed to fetch members'};
    }
  }

  // ----------------------------------------------------------------
  // Per-customer endpoints (still used by ClientDetailsScreen)
  // ----------------------------------------------------------------

  /// GET /api/v1/gym/customers/{customer_id}/transactions
  Future<Map<String, dynamic>> getCustomerTransactions(String customerId) async {
    debugPrint('💰 Fetching transactions for customer: $customerId');

    final response =
        await ApiClient.get('/api/v1/gym/customers/$customerId/transactions');

    debugPrint('📥 Get Customer Transactions Response: ${response.data}');

    if (response.success && response.data != null) {
      return {'success': true, 'data': response.data};
    } else {
      return {'success': false, 'message': response.message ?? 'Failed to fetch transactions'};
    }
  }

  /// GET /api/v1/gym/customers/{customer_id}/attendance
  Future<Map<String, dynamic>> getCustomerAttendance(
    String customerId, {
    int? month,
    int? year,
  }) async {
    debugPrint('📅 Fetching attendance for customer: $customerId');

    final now = DateTime.now();
    final response = await ApiClient.get(
      '/api/v1/gym/customers/$customerId/attendance',
      queryParams: {
        'month': (month ?? now.month).toString(),
        'year': (year ?? now.year).toString(),
      },
    );

    debugPrint('📥 Get Customer Attendance Response: ${response.data}');

    if (response.success && response.data != null) {
      return {'success': true, 'data': response.data};
    } else {
      return {'success': false, 'message': response.message ?? 'Failed to fetch attendance'};
    }
  }

  // ----------------------------------------------------------------
  // Parsers
  // ----------------------------------------------------------------

  /// Parse subscriptions response → List<Transaction>
  /// Handles the new /api/v1/gym/customers/subscriptions response
  List<Transaction> parseSubscriptions(dynamic data) {
    List<dynamic> list;

    if (data is List) {
      list = data;
    } else if (data is Map && data['subscriptions'] != null) {
      list = data['subscriptions'] as List;
    } else if (data is Map && data['bookings'] != null) {
      list = data['bookings'] as List;
    } else if (data is Map && data['data'] != null && data['data'] is List) {
      list = data['data'] as List;
    } else {
      debugPrint('⚠️ parseSubscriptions: unrecognised shape — keys: ${data is Map ? data.keys.toList() : data.runtimeType}');
      return [];
    }

    debugPrint('📋 parseSubscriptions: ${list.length} records. First: ${list.isNotEmpty ? list[0] : "EMPTY"}');

    return list.map((t) {
      // Log each raw record to inspect available fields
      debugPrint('  → record keys: ${(t as Map).keys.toList()}  user=${t['user']}');

      // Resolve customer name — prioritize customer_name from backend then user object
      final user = t['user'];
      final customerName = t['customer_name'] ?? 
                  t['user_name'] ?? 
                  t['name'] ??
                  (user != null ? (user['name'] ?? user['full_name'] ?? user['first_name']) : null) ??
                  'Customer';

      // Booking number / ID
      final id = t['booking_number'] ?? t['id'] ?? t['_id'] ?? '';

      // Type label
      final type = t['booking_type'] == 'service'
          ? (t['service_name'] ?? t['service'] ?? 'Service')
          : (t['plan_name'] ?? t['membership_type'] ?? t['type'] ?? 'Membership');

      // Amount
      final amount = (t['amount_paid'] ?? t['total_amount'] ?? t['amount'] ?? 0).toDouble();

      // Date
      final dateTime = DateTime.tryParse(
              t['created_at'] ?? t['payment_date'] ?? t['date'] ?? '') ??
          DateTime.now();

      // Status
      final status = (t['status'] ?? t['payment_status'] ?? 'confirmed').toString().toLowerCase();

      debugPrint('    → customerName="$customerName" type="$type" amount=$amount status="$status"');

      return Transaction(
        id: id.toString(),
        type: type.toString(),
        amount: amount,
        dateTime: dateTime,
        customerName: customerName.toString(),
        description: status, // Use status for the label in the list
        status: status,
        endDate: DateTime.tryParse(t['end_date'] ?? ''),
        daysRemaining: t['days_remaining'],
      );
    }).toList();
  }

  /// Parse members response → List<Customer>
  /// Handles the new /api/v1/gym/customers/members response
  List<Customer> parseMembers(dynamic data) {
    List<dynamic> list;

    if (data is List) {
      list = data;
    } else if (data is Map && data['members'] != null) {
      list = data['members'] as List;
    } else if (data is Map && data['data'] != null && data['data'] is List) {
      list = data['data'] as List;
    } else if (data is Map && data['customers'] != null) {
      list = data['customers'] as List;
    } else {
      return [];
    }

    debugPrint('👥 parseMembers: ${list.length} records. First raw: ${list.isNotEmpty ? list[0] : "EMPTY"}');

    return list.map((m) {
      final user = m['user'] ?? m;
      
      // Log for debugging name mapping
      if (list.indexOf(m) == 0) {
        debugPrint('  → Member[0] user keys: ${(user is Map) ? user.keys.toList() : "not a map"}');
        debugPrint('  → Member[0] raw object keys: ${(m is Map) ? m.keys.toList() : "not a map"}');
      }

      final name = m['customer_name'] ??
                  user['name'] ?? 
                  user['fullName'] ?? 
                  user['full_name'] ?? 
                  user['firstName'] ?? 
                  user['first_name'] ?? 
                  m['name'] ?? 
                  'Member';
      
      final phone = m['phone_number'] ??
                   m['phone'] ??
                   user['phone'] ?? 
                   user['phoneNumber'] ?? 
                   user['phone_number'] ?? 
                   '';
      final profileImage =
          user['profile_image_url'] ?? user['profile_image'] ?? m['profile_image_url'];
      final id = user['_id'] ?? user['id'] ?? m['user_id'] ?? m['id'] ?? '';

      final membershipType = m['plan_name'] ?? m['membership_type'] ?? 'Membership';
      final daysRemaining = m['days_remaining'] ?? 0;
      final amountPaid = (m['amount_paid'] ?? 0).toDouble();
      final startDate = DateTime.tryParse(m['start_date'] ?? m['created_at'] ?? '') ?? DateTime.now();
      final endDate = DateTime.tryParse(m['end_date'] ?? '');
      final lastCheckin = m['last_checkin'];

      final status = daysRemaining > 0 ? 'Active' : 'Expired';

      debugPrint('  → Parsed Member: name="$name", id="$id"');

      return Customer(
        id: id.toString(),
        name: name.toString(),
        phoneNumber: phone.toString(),
        profileImage: profileImage?.toString(),
        status: status,
        memberSince: startDate,
        membershipType: membershipType.toString(),
        membershipEndDate: endDate,
        daysRemaining: daysRemaining is int ? daysRemaining : (daysRemaining as num?)?.toInt() ?? 0,
        lastCheckin: lastCheckin != null ? DateTime.tryParse(lastCheckin.toString()) : null,
      );
    }).toList();
  }

  /// Extract unique customers from raw subscriptions data.
  /// Deduplicates by user_id — the first (latest) booking per user wins.
  /// Falls back to [membersFromApi] if provided and non-empty.
  List<Customer> parseCustomersFromSubscriptions(
    dynamic subscriptionData, {
    List<Customer> membersFromApi = const [],
  }) {
    // If /members already gave us results, use them (richer data)
    if (membersFromApi.isNotEmpty) return membersFromApi;

    List<dynamic> list;
    if (subscriptionData is List) {
      list = subscriptionData;
    } else if (subscriptionData is Map && subscriptionData['subscriptions'] != null) {
      list = subscriptionData['subscriptions'] as List;
    } else if (subscriptionData is Map &&
        subscriptionData['data'] != null &&
        subscriptionData['data'] is List) {
      list = subscriptionData['data'] as List;
    } else {
      return [];
    }

    // Deduplicate customers by user id
    final Map<String, Customer> seen = {};

    for (final t in list) {
      final user = t['user'];
      if (user == null) continue;

      final userId = (user['_id'] ?? user['id'] ?? '').toString();
      if (userId.isEmpty || seen.containsKey(userId)) continue;

      final name = (t['customer_name'] ??
                    user['name'] ?? 
                    user['fullName'] ?? 
                    user['full_name'] ?? 
                    user['firstName'] ?? 
                    user['first_name'] ?? 
                    'Customer').toString();
      
      final phone = (t['phone_number'] ??
                     user['phone'] ?? 
                     user['phoneNumber'] ?? 
                     user['phone_number'] ?? 
                     '').toString();
      final profileImage =
          (user['profile_image_url'] ?? user['profile_image'])?.toString();

      final membershipType = t['booking_type'] == 'service'
          ? (t['service_name'] ?? 'Service').toString()
          : (t['plan_name'] ?? t['membership_type'] ?? 'Membership').toString();

      final memberSince =
          DateTime.tryParse((t['created_at'] ?? t['payment_date'] ?? '').toString()) ??
              DateTime.now();

      final endDate = DateTime.tryParse((t['end_date'] ?? '').toString());

      // Compute days remaining if end_date is available
      final daysRemaining = endDate != null
          ? endDate.difference(DateTime.now()).inDays.clamp(0, 99999)
          : 0;

      final status = daysRemaining > 0 ? 'Active' : 'Active'; // treat as active

      seen[userId] = Customer(
        id: userId,
        name: name,
        phoneNumber: phone,
        profileImage: profileImage,
        status: status,
        memberSince: memberSince,
        membershipType: membershipType,
        membershipEndDate: endDate,
        daysRemaining: daysRemaining,
      );
    }

    debugPrint('👥 Extracted ${seen.values.length} unique customers from subscriptions');
    return seen.values.toList();
  }

  /// Parse transactions for a single customer (per-customer detail view)
  List<Transaction> parseTransactions(dynamic data) {
    List<dynamic> transactionsList;

    if (data is List) {
      transactionsList = data;
    } else if (data is Map && data['transactions'] != null) {
      transactionsList = data['transactions'] as List;
    } else {
      return [];
    }

    return transactionsList
        .map((t) => Transaction(
              id: t['transaction_id'] ?? t['id'] ?? '',
              type: t['title'] ?? t['type'] ?? '',
              amount: (t['amount'] ?? 0).toDouble(),
              dateTime: DateTime.tryParse(t['date'] ?? t['date_time'] ?? '') ?? DateTime.now(),
              customerName: t['customer_name'],
            ))
        .toList();
  }

  /// Parse attendance from API response
  List<int> parseAttendance(Map<String, dynamic> data) {
    if (data['attendance'] == null) return [];
    return (data['attendance'] as List).map((a) => a as int).toList();
  }

  /// Stub for overview — stats will be derived from subscriptions count
  HomeStats? parseOverviewFromSubscriptions(List<Transaction> transactions, List<Customer> customers) {
    final total = transactions.fold(0.0, (sum, t) => sum + t.amount);
    return HomeStats(
      totalEarnings: total,
      earningsChange: 0,
      totalCustomers: customers.length,
      customersChange: 0,
      totalAttendance: 0,
      attendanceChange: 0,
      dateRange: '',
    );
  }
}
