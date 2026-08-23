// ============================================================================
// customer_model.dart
// ----------------------------------------------------------------------------
// Mirrors the `customers` table in database/schema.sql. This is the single
// profile record every vertical (grocery, food, services, ads, real estate)
// reads from — it is intentionally NOT vertical-specific.
// ============================================================================

import '../../core/constants/membership_constants.dart';

class CustomerModel {
  final String id;
  final String customerCode; // SB000001
  final String? authUserId;
  final String fullName;
  final String mobileNumber; // 10 digits, no +91
  final String? email;
  final String? profilePhotoUrl;

  final MembershipTier membershipTier;
  final int completedOrders;

  final int rewardPoints;
  final double walletBalance;

  final String? referralCode;
  final String? referredBy;

  final DateTime registrationDate;
  final DateTime? lastLogin;
  final bool isActive;

  const CustomerModel({
    required this.id,
    required this.customerCode,
    this.authUserId,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.profilePhotoUrl,
    this.membershipTier = MembershipTier.bronze,
    this.completedOrders = 0,
    this.rewardPoints = 0,
    this.walletBalance = 0,
    this.referralCode,
    this.referredBy,
    required this.registrationDate,
    this.lastLogin,
    this.isActive = true,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      customerCode: json['customer_code'] as String,
      authUserId: json['auth_user_id'] as String?,
      fullName: json['full_name'] as String,
      mobileNumber: json['mobile_number'] as String,
      email: json['email'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      membershipTier: MembershipTierX.fromString(
        json['membership_tier'] as String? ?? 'bronze',
      ),
      completedOrders: (json['completed_orders'] as num?)?.toInt() ?? 0,
      rewardPoints: (json['reward_points'] as num?)?.toInt() ?? 0,
      walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0,
      referralCode: json['referral_code'] as String?,
      referredBy: json['referred_by'] as String?,
      registrationDate: DateTime.parse(json['registration_date'] as String),
      lastLogin: json['last_login'] == null
          ? null
          : DateTime.parse(json['last_login'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Fields used for the initial insert. `customer_code`, `referral_code`,
  /// `registration_date`, membership defaults etc. are intentionally
  /// omitted — the database triggers in schema.sql fill those in.
  Map<String, dynamic> toInsertJson() {
    return {
      if (authUserId != null) 'auth_user_id': authUserId,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      if (email != null) 'email': email,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (referredBy != null) 'referred_by': referredBy,
    };
  }

  CustomerModel copyWith({
    String? fullName,
    String? email,
    String? profilePhotoUrl,
    MembershipTier? membershipTier,
    int? completedOrders,
    int? rewardPoints,
    double? walletBalance,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return CustomerModel(
      id: id,
      customerCode: customerCode,
      authUserId: authUserId,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      membershipTier: membershipTier ?? this.membershipTier,
      completedOrders: completedOrders ?? this.completedOrders,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      walletBalance: walletBalance ?? this.walletBalance,
      referralCode: referralCode,
      referredBy: referredBy,
      registrationDate: registrationDate,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}
