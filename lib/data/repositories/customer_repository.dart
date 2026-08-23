// ============================================================================
// customer_repository.dart
// ----------------------------------------------------------------------------
// The ONLY place in the app that talks to Supabase for customer registration
// and profile reads. Screens call this repository — they never call
// `Supabase.instance.client` directly — so the backend can evolve (e.g. move
// a step server-side into an Edge Function / RPC) without touching UI code.
//
// Registration flow:
//   1) supabase.auth.signUp()               -> creates the auth.users row
//   2) insert into `customers`               -> triggers in schema.sql then
//                                                auto-generate customer_code,
//                                                referral_code, and spin up
//                                                membership_history,
//                                                notification_preferences,
//                                                and customer_statistics rows
//   3) (optional) upload profile photo to Storage, then update the row
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../../models/customer_model.dart';

class CustomerRegistrationException implements Exception {
  final String message;
  CustomerRegistrationException(this.message);

  @override
  String toString() => message;
}

class CustomerRepository {
  CustomerRepository(this._client);

  final SupabaseClient _client;

  static const String _customersTable = 'customers';
  static const String _profilePhotosBucket = 'profile-photos';

  /// Registers a brand-new SnapBee customer end-to-end:
  /// creates the Supabase auth user, then the `customers` profile row
  /// (which cascades into membership/notification/statistics rows via
  /// database triggers — see database/schema.sql).
  Future<CustomerModel> signUp({
    required String fullName,
    required String mobileNumber, // 10 digits, no +91
    required String email,
    required String password,
    String? referralCodeUsed,
    Uint8ListSource? profilePhoto,
  }) async {
    // 1) Create the auth user.
    final authResponse = await _client.auth.signUp(
      email: email,
      password: password,
    );

    final authUser = authResponse.user;
    if (authUser == null) {
      throw CustomerRegistrationException(
        'Could not create account. Please try again.',
      );
    }

    // 2) Resolve an optional referrer's internal customer id from the
    //    human-entered referral code, if one was provided.
    String? referredByCustomerId;
    if (referralCodeUsed != null && referralCodeUsed.trim().isNotEmpty) {
      final referrer = await _client
          .from(_customersTable)
          .select('id')
          .eq('referral_code', referralCodeUsed.trim())
          .maybeSingle();
      referredByCustomerId = referrer?['id'] as String?;
    }

    // 3) Optional profile photo upload (Supabase Storage), BEFORE the
    //    profile insert, so we can store the final URL in one write.
    String? photoUrl;
    if (profilePhoto != null) {
      final path = '${authUser.id}/profile.jpg';
      await _client.storage
          .from(_profilePhotosBucket)
          .uploadBinary(
            path,
            profilePhoto.bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );
      photoUrl = _client.storage.from(_profilePhotosBucket).getPublicUrl(path);
    }

    // 4) Insert the customer profile row. Everything else (customer_code,
    //    referral_code, membership_tier default, initial stats/notification
    //    rows) is handled by the database triggers — the app stays "dumb"
    //    about ID generation so there is never a client/server race.
    final draft = CustomerModel(
      id: '', // ignored — DB generates the primary key
      customerCode: '', // ignored — DB trigger fills this in
      authUserId: authUser.id,
      fullName: fullName.trim(),
      mobileNumber: mobileNumber.trim(),
      email: email.trim(),
      profilePhotoUrl: photoUrl,
      referredBy: referredByCustomerId,
      registrationDate: DateTime.now(),
    );

    final inserted = await _client
        .from(_customersTable)
        .insert(draft.toInsertJson())
        .select()
        .single();

    return CustomerModel.fromJson(inserted);
  }

  Future<CustomerModel?> fetchByAuthUserId(String authUserId) async {
    final row = await _client
        .from(_customersTable)
        .select()
        .eq('auth_user_id', authUserId)
        .maybeSingle();
    if (row == null) return null;
    return CustomerModel.fromJson(row);
  }

  Future<void> touchLastLogin(String customerId) async {
    await _client
        .from(_customersTable)
        .update({'last_login': DateTime.now().toIso8601String()})
        .eq('id', customerId);
  }
}

/// Small wrapper so the repository doesn't need to import `dart:typed_data`
/// consumers directly — pass image bytes picked via `image_picker`.
class Uint8ListSource {
  final Uint8List bytes;
  const Uint8ListSource(this.bytes);
}
