class User {
  final String id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final String? profileImage;
  final bool isVerified;
  final bool isKycVerified;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    this.profileImage,
    this.isVerified = false,
    this.isKycVerified = false,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      name: json['name'],
      email: json['email'],
      profileImage: json['profile_image'],
      isVerified: json['is_verified'] ?? false,
      isKycVerified: json['is_kyc_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'name': name,
      'email': email,
      'profile_image': profileImage,
      'is_verified': isVerified,
      'is_kyc_verified': isKycVerified,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? phoneNumber,
    String? name,
    String? email,
    String? profileImage,
    bool? isVerified,
    bool? isKycVerified,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      isKycVerified: isKycVerified ?? this.isKycVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuthResponse {
  final String? accessToken;
  final String? refreshToken;
  final User? user;
  final bool isNewUser;
  final String? message;

  AuthResponse({
    this.accessToken,
    this.refreshToken,
    this.user,
    this.isNewUser = false,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      isNewUser: json['is_new_user'] ?? false,
      message: json['message'],
    );
  }
}

class OtpResponse {
  final bool success;
  final String? message;
  final String? otpId;

  OtpResponse({
    required this.success,
    this.message,
    this.otpId,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] ?? false,
      message: json['message'],
      otpId: json['otp_id'],
    );
  }
}
