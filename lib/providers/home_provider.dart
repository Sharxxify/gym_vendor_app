import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/attendance_service.dart';
import '../services/customer_service.dart';
import '../services/gym_service.dart';

enum HomeTab { earnings, customers, attendance }

class HomeProvider extends ChangeNotifier {
  final CustomerService _customerService = CustomerService();
  final GymService _gymService = GymService();
  final AttendanceService _attendanceService = AttendanceService();

  HomeTab _selectedTab = HomeTab.earnings;
  bool _isLoading = false;
  String? _errorMessage;

  // Stats
  HomeStats? _stats;
  List<Transaction> _transactions = [];
  List<Customer> _customers = [];
  Map<DateTime, int> _attendanceData = {};
  dynamic _rawSubscriptionData; // cached for customer extraction fallback

  // Gym profile data
  Map<String, dynamic>? _gymProfileData;
  String? _gymName;
  double? _gymRating;
  int? _reviewCount;
  String? _gymStatus;
  String? _profilePictureUrl;

  // Elite membership data
  bool _isElite = false;
  String? _elitePlan;
  DateTime? _eliteValidTill;
  DateTime? _elitePurchasedAt;

  // Filter
  String _selectedPeriod = 'This Month';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Getters
  HomeTab get selectedTab => _selectedTab;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  HomeStats? get stats => _stats;
  List<Transaction> get transactions => _transactions;
  List<Customer> get customers => _customers;
  Map<DateTime, int> get attendanceData => _attendanceData;
  String get selectedPeriod => _selectedPeriod;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;

  /// Calculate total earnings from all transactions
  double get totalEarningsFromTransactions {
    if (_transactions.isEmpty) return 0.0;
    return _transactions
        .where((txn) =>
            txn.status != 'cancelled' &&
            txn.status != 'payment_pending' &&
            txn.status != 'failed' &&
            txn.status != 'rejected')
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  /// Calculate total earnings for selected period
  double get totalEarningsForPeriod {
    final filtered = filteredTransactions;
    if (filtered.isEmpty) return 0.0;
    return filtered
        .where((txn) =>
            txn.status != 'cancelled' &&
            txn.status != 'payment_pending' &&
            txn.status != 'failed' &&
            txn.status != 'rejected')
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  /// Get filtered transactions based on selected period
  List<Transaction> get filteredTransactions {
    // Exact day matching: Start at 00:00:00, End at 23:59:59
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

    return _transactions.where((txn) {
      return (txn.dateTime.isAtSameMomentAs(start) || txn.dateTime.isAfter(start)) &&
             (txn.dateTime.isAtSameMomentAs(end) || txn.dateTime.isBefore(end));
    }).toList();
  }

  // Gym profile getters
  Map<String, dynamic>? get gymProfileData => _gymProfileData;
  String? get gymName => _gymName;
  double? get gymRating => _gymRating;
  int? get reviewCount => _reviewCount;
  String? get gymStatus => _gymStatus;
  String? get profilePictureUrl => _profilePictureUrl;

  // Elite membership getters
  bool get isElite => _isElite;
  String? get elitePlan => _elitePlan;
  DateTime? get eliteValidTill => _eliteValidTill;
  DateTime? get elitePurchasedAt => _elitePurchasedAt;

  void setSelectedTab(HomeTab tab) {
    _selectedTab = tab;
    notifyListeners();
  }

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    final now = DateTime.now();
    switch (period) {
      case 'Today':
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
        break;
      case 'This Week':
        _startDate = now.subtract(Duration(days: now.weekday - 1));
        _endDate = now;
        break;
      case 'This Month':
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
        break;
      case 'This Year':
        _startDate = DateTime(now.year, 1, 1);
        _endDate = now;
        break;
    }
    notifyListeners();
    loadData();
  }

  /// Load all home data (gym profile, customers, stats, transactions)
  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Load gym profile
      await _loadGymProfile();

      // 2. Load all transactions
      await _loadTransactions();

      // 3. Load customers and overview
      await _loadCustomersAndOverview();

      _isLoading = false;
    } catch (e) {
      debugPrint('❌ Error loading data: $e');
      _errorMessage = e.toString();
      _isLoading = false;
    }

    notifyListeners();
  }

  /// Load gym profile data
  Future<void> _loadGymProfile() async {
    debugPrint('🏢 Loading gym profile...');

    final gymProfileResult = await _gymService.getGymProfile();

    if (gymProfileResult['success'] == true &&
        gymProfileResult['data'] != null) {
      _gymProfileData = gymProfileResult['data'];

      debugPrint('📦 Full gym profile data: $_gymProfileData');

      // Parse business info
      final business = _gymProfileData!['business'];
      if (business != null) {
        _gymName = business['name'];
        debugPrint('✅ Gym name: $_gymName');
      } else {
        debugPrint('⚠️ No business object in response');
      }

      // Parse status (it's at the top level, not inside business)
      _gymStatus = _gymProfileData!['status'];
      debugPrint('✅ Gym status: $_gymStatus');

      // Parse rating info (rating is an object with average and total_reviews)
      final rating = _gymProfileData!['rating'];
      if (rating != null && rating is Map) {
        _gymRating = (rating['average'] ?? 0).toDouble();
        _reviewCount = rating['total_reviews'] ?? 0;
        debugPrint('✅ Rating: $_gymRating, Reviews: $reviewCount');
      } else {
        _gymRating = 0.0;
        _reviewCount = 0;
        debugPrint('⚠️ No rating data in response');
      }

      // Parse profile picture with detailed logging
      debugPrint('🔍 Checking profile_picture field...');
      final profilePictures = _gymProfileData!['profile_picture'];
      debugPrint('📸 Profile pictures data: $profilePictures');
      debugPrint('📸 Profile pictures type: ${profilePictures.runtimeType}');

      if (profilePictures != null && profilePictures is List) {
        debugPrint(
            '✅ Profile pictures is a List with ${profilePictures.length} items');
        if (profilePictures.isNotEmpty) {
          debugPrint('📸 First profile picture item: ${profilePictures[0]}');
          if (profilePictures[0] is Map &&
              profilePictures[0]['s3_url'] != null) {
            _profilePictureUrl = profilePictures[0]['s3_url'];
            debugPrint('✅ Profile picture URL extracted: $_profilePictureUrl');
          } else {
            debugPrint('⚠️ Profile picture item does not have s3_url');
          }
        } else {
          debugPrint('⚠️ Profile pictures list is empty');
        }
      } else {
        debugPrint('❌ Profile pictures is not a List or is null');
      }

      if (_profilePictureUrl != null) {
        debugPrint('✅ Final profile picture URL: $_profilePictureUrl');
      } else {
        debugPrint('⚠️ No profile picture URL found - will show default icon');
      }

      debugPrint(
          '✅ Gym profile loaded: $_gymName, Rating: $_gymRating ($reviewCount reviews), Picture: ${_profilePictureUrl != null ? "Available" : "Not Available"}');

      // Parse elite membership
      final eliteMembership = _gymProfileData!['elite_membership'];
      if (eliteMembership != null && eliteMembership is Map) {
        _isElite = eliteMembership['is_elite'] ?? false;
        _elitePlan = eliteMembership['plan'];
        _eliteValidTill = eliteMembership['valid_till'] != null
            ? DateTime.tryParse(eliteMembership['valid_till'])
            : null;
        _elitePurchasedAt = eliteMembership['purchased_at'] != null
            ? DateTime.tryParse(eliteMembership['purchased_at'])
            : null;
        debugPrint(
            '💎 Elite membership: isElite=$_isElite, plan=$_elitePlan, validTill=$_eliteValidTill');
      } else {
        _isElite = false;
        _elitePlan = null;
        _eliteValidTill = null;
        _elitePurchasedAt = null;
        debugPrint('⚠️ No elite membership data in response');
      }
    } else {
      debugPrint(
          '⚠️ Failed to load gym profile: ${gymProfileResult['message']}');
    }
  }

  /// Load all transactions via new subscriptions endpoint
  Future<void> _loadTransactions() async {
    debugPrint('💰 Loading transactions via /subscriptions...');

    final result = await _customerService.getSubscriptions(
      type: 'all',
      status: 'confirmed',
    );

    if (result['success'] == true && result['data'] != null) {
      _rawSubscriptionData = result['data']; // cache for customer fallback
      _transactions = _customerService.parseSubscriptions(result['data']);
      debugPrint('✅ Loaded ${_transactions.length} transactions');
      debugPrint('💰 Total earnings: $totalEarningsFromTransactions');
    } else {
      debugPrint('⚠️ Failed to load transactions: ${result['message']}');
      _rawSubscriptionData = null;
      _transactions = [];
    }
  }

  /// Load customers: tries /members first, falls back to extracting from subscriptions
  Future<void> _loadCustomersAndOverview() async {
    debugPrint('👥 Loading members...');

    List<Customer> membersFromApi = [];

    final membersResult = await _customerService.getMembers(activeOnly: false);
    if (membersResult['success'] == true && membersResult['data'] != null) {
      membersFromApi = _customerService.parseMembers(membersResult['data']);
      debugPrint('✅ Loaded ${membersFromApi.length} members from /members');
    } else {
      debugPrint('⚠️ /members failed: ${membersResult['message']} — falling back to subscriptions');
    }

    // If /members returned nothing, derive customers from subscription user objects
    _customers = _customerService.parseCustomersFromSubscriptions(
      _rawSubscriptionData,
      membersFromApi: membersFromApi,
    );

    debugPrint('✅ Final customer list: ${_customers.length} customers');

    // Derive overview stats
    _stats = _customerService.parseOverviewFromSubscriptions(_transactions, _customers);
  }

  String searchQuery = '';

  List<Customer> get filteredCustomers {
    if (searchQuery.isEmpty) return _customers;
    return _customers
        .where((c) =>
            c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            c.phoneNumber.contains(searchQuery))
        .toList();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  /// Load customer transactions
  Future<List<Transaction>> loadCustomerTransactions(String customerId) async {
    try {
      // 1. Try the direct API first
      final result = await _customerService.getCustomerTransactions(customerId);

      if (result['success'] == true && result['data'] != null) {
        final transactions = _customerService.parseTransactions(result['data']);
        if (transactions.isNotEmpty) return transactions;
      }

      // 2. FALLBACK: If direct API has no records, filter the local main list
      final localMatches = _transactions.where((t) {
        return t.customerId == customerId;
      }).toList();
      
      if (localMatches.isNotEmpty) {
        return localMatches;
      }
    } catch (e) {
      debugPrint('❌ Error loading transactions: $e');
    }
    return [];
  }

  /// Load customer attendance
  Future<List<int>> loadCustomerAttendance(String customerId,
      {int? month, int? year}) async {
    try {
      final result = await _customerService.getCustomerAttendance(
        customerId,
        month: month,
        year: year,
      );

      if (result['success'] == true && result['data'] != null) {
        return _customerService.parseAttendance(result['data']);
      }
    } catch (e) {
      debugPrint('❌ Error loading attendance: $e');
    }
    return [];
  }

  /// Mark customer attendance via QR code (old system)
  Future<Map<String, dynamic>> markAttendanceOld({
    required String customerId,
    String? qrCode,
  }) async {
    try {
      final result = await _attendanceService.markAttendanceOld(
        customerId: customerId,
        qrCode: qrCode,
      );
      return result;
    } catch (e) {
      debugPrint('❌ Error marking attendance: $e');
      return {
        'success': false,
        'message': 'Error marking attendance: $e',
      };
    }
  }

  /// Mark attendance via QR code scan (new one-time scan system)
  Future<Map<String, dynamic>> markAttendance({
    required String qrCode,
    required String gymId,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final result = await _attendanceService.markAttendance(
        qrCode: qrCode,
        gymId: gymId,
        latitude: latitude,
        longitude: longitude,
      );
      return result;
    } catch (e) {
      debugPrint('❌ Error marking attendance: $e');
      return {
        'success': false,
        'message': 'Error marking attendance: $e',
      };
    }
  }

  /// Get today's attendance list
  Future<Map<String, dynamic>> getTodayAttendance() async {
    try {
      final result = await _attendanceService.getTodayAttendance();
      return result;
    } catch (e) {
      debugPrint('❌ Error getting today\'s attendance: $e');
      return {
        'success': false,
        'message': 'Error getting today\'s attendance: $e',
      };
    }
  }

  /// Get monthly attendance data
  Future<Map<String, dynamic>> getMonthlyAttendance({
    required int year,
    required int month,
  }) async {
    try {
      final result = await _attendanceService.getMonthlyAttendance(
        year: year,
        month: month,
      );
      return result;
    } catch (e) {
      debugPrint('❌ Error getting monthly attendance: $e');
      return {
        'success': false,
        'message': 'Error getting monthly attendance: $e',
      };
    }
  }

  /// Get attendance overview for stats
  Future<Map<String, dynamic>> getAttendanceOverview({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final result = await _attendanceService.getAttendanceOverview(
        startDate: startDate,
        endDate: endDate,
      );
      return result;
    } catch (e) {
      debugPrint('❌ Error getting attendance overview: $e');
      return {
        'success': false,
        'message': 'Error getting attendance overview: $e',
      };
    }
  }

  /// Clear all data
  void clearData() {
    _stats = null;
    _transactions = [];
    _customers = [];
    _attendanceData = {};
    _rawSubscriptionData = null;
    _gymProfileData = null;
    _gymName = null;
    _gymRating = null;
    _reviewCount = null;
    _gymStatus = null;
    _profilePictureUrl = null;
    _isElite = false;
    _elitePlan = null;
    _eliteValidTill = null;
    _elitePurchasedAt = null;
    _errorMessage = null;
    notifyListeners();
  }
}
