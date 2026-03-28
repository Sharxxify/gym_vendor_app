class Customer {
  final String id;
  final String name;
  final String phoneNumber;
  final String? profileImage;
  final String status;
  final DateTime memberSince;
  final String membershipType;
  final DateTime? membershipEndDate;
  final List<Transaction> transactions;
  final List<AttendanceRecord> attendance;
  final int daysRemaining;
  final DateTime? lastCheckin;

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.profileImage,
    this.status = 'Active',
    required this.memberSince,
    required this.membershipType,
    this.membershipEndDate,
    this.transactions = const [],
    this.attendance = const [],
    this.daysRemaining = 0,
    this.lastCheckin,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      profileImage: json['profile_image'],
      status: json['status'] ?? 'Active',
      memberSince: DateTime.tryParse(json['member_since'] ?? '') ?? DateTime.now(),
      membershipType: json['membership_type'] ?? 'Monthly',
      membershipEndDate: DateTime.tryParse(json['membership_end_date'] ?? ''),
      transactions: (json['transactions'] as List?)
              ?.map((e) => Transaction.fromJson(e))
              .toList() ?? [],
      attendance: (json['attendance'] as List?)
              ?.map((e) => AttendanceRecord.fromJson(e))
              .toList() ?? [],
      daysRemaining: json['days_remaining'] ?? 0,
      lastCheckin: DateTime.tryParse(json['last_checkin'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone_number': phoneNumber,
    'profile_image': profileImage,
    'status': status,
    'member_since': memberSince.toIso8601String(),
    'membership_type': membershipType,
    'membership_end_date': membershipEndDate?.toIso8601String(),
    'days_remaining': daysRemaining,
    'last_checkin': lastCheckin?.toIso8601String(),
  };

  int get attendancePercentage {
    if (attendance.isEmpty) return 0;
    final presentDays = attendance.where((a) => a.isPresent).length;
    return ((presentDays / attendance.length) * 100).round();
  }

  int get presentCount => attendance.where((a) => a.isPresent).length;
  int get absentCount => attendance.where((a) => !a.isPresent).length;
}

class Transaction {
  final String id;
  final String type;
  final double amount;
  final DateTime dateTime;
  final String? customerId;
  final String? customerName;
  final String? description;
  final String? qrCode;
  final DateTime? endDate;
  final int? daysRemaining;
  final String? status;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.dateTime,
    this.customerId,
    this.customerName,
    this.description,
    this.qrCode,
    this.endDate,
    this.daysRemaining,
    this.status,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      dateTime: DateTime.tryParse(json['date_time'] ?? '') ?? DateTime.now(),
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      description: json['description'],
      qrCode: json['qr_code'],
      endDate: DateTime.tryParse(json['end_date'] ?? ''),
      daysRemaining: json['days_remaining'],
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'amount': amount,
    'date_time': dateTime.toIso8601String(),
    'customer_id': customerId,
    'customer_name': customerName,
    'description': description,
    'qr_code': qrCode,
    'end_date': endDate?.toIso8601String(),
    'days_remaining': daysRemaining,
    'status': status,
  };
}

class AttendanceRecord {
  final String id;
  final DateTime date;
  final bool isPresent;

  AttendanceRecord({
    required this.id,
    required this.date,
    required this.isPresent,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] ?? '',
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      isPresent: json['is_present'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'is_present': isPresent,
  };
}

class Review {
  final String id;
  final String customerName;
  final String? customerImage;
  final double rating;
  final String comment;
  final DateTime dateTime;
  final String? reply;

  Review({
    required this.id,
    required this.customerName,
    this.customerImage,
    required this.rating,
    required this.comment,
    required this.dateTime,
    this.reply,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? '',
      customerName: json['customer_name'] ?? '',
      customerImage: json['customer_image'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'] ?? '',
      dateTime: DateTime.tryParse(json['date_time'] ?? '') ?? DateTime.now(),
      reply: json['reply'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customer_name': customerName,
    'customer_image': customerImage,
    'rating': rating,
    'comment': comment,
    'date_time': dateTime.toIso8601String(),
    'reply': reply,
  };
}

class HomeStats {
  final double totalEarnings;
  final double earningsChange;
  final int totalCustomers;
  final double customersChange;
  final int totalAttendance;
  final double attendanceChange;
  final String dateRange;

  HomeStats({
    required this.totalEarnings,
    required this.earningsChange,
    required this.totalCustomers,
    required this.customersChange,
    required this.totalAttendance,
    required this.attendanceChange,
    required this.dateRange,
  });

  factory HomeStats.fromJson(Map<String, dynamic> json) {
    return HomeStats(
      totalEarnings: (json['total_earnings'] ?? 0.0).toDouble(),
      earningsChange: (json['earnings_change'] ?? 0.0).toDouble(),
      totalCustomers: json['total_customers'] ?? 0,
      customersChange: (json['customers_change'] ?? 0.0).toDouble(),
      totalAttendance: json['total_attendance'] ?? 0,
      attendanceChange: (json['attendance_change'] ?? 0.0).toDouble(),
      dateRange: json['date_range'] ?? '',
    );
  }
}
