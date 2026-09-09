// ============================================================================
// address_repository.dart
// ----------------------------------------------------------------------------
// The Customer app's persisted address book. Reads `customer_addresses`
// directly (RLS scopes every row to the signed-in customer) and mutates it
// through the SECURITY DEFINER RPCs from
// snapbee_admin/supabase/customer_addresses.sql — `save_customer_address`,
// `set_default_customer_address`, `delete_customer_address` — which own the
// "exactly one default per customer" invariant.
//
// The latitude/longitude stored here come straight from the existing OSM
// LocationPickerScreen; this repository adds no geocoding of its own.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerAddress {
  final String id;
  final String label;
  final String tag; // home | work | parents | other
  final String? recipientName;
  final String? phone;
  final String? house;
  final String? street;
  final String? landmark;
  final String? area;
  final String? city;
  final String? district;
  final String? state;
  final String? pincode;
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String? deliveryInstructions;
  final bool isDefault;

  const CustomerAddress({
    required this.id,
    required this.label,
    required this.tag,
    this.recipientName,
    this.phone,
    this.house,
    this.street,
    this.landmark,
    this.area,
    this.city,
    this.district,
    this.state,
    this.pincode,
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    this.deliveryInstructions,
    this.isDefault = false,
  });

  factory CustomerAddress.fromRow(Map<String, dynamic> r) => CustomerAddress(
        id: r['id'] as String,
        label: (r['label'] as String?) ?? 'Home',
        tag: (r['tag'] as String?) ?? 'other',
        recipientName: r['recipient_name'] as String?,
        phone: r['phone'] as String?,
        house: r['house'] as String?,
        street: r['street'] as String?,
        landmark: r['landmark'] as String?,
        area: r['area'] as String?,
        city: r['city'] as String?,
        district: r['district'] as String?,
        state: r['state'] as String?,
        pincode: r['pincode'] as String?,
        latitude: (r['latitude'] as num).toDouble(),
        longitude: (r['longitude'] as num).toDouble(),
        formattedAddress: (r['formatted_address'] as String?) ?? '',
        deliveryInstructions: r['delivery_instructions'] as String?,
        isDefault: (r['is_default'] as bool?) ?? false,
      );
}

class AddressException implements Exception {
  final String message;
  const AddressException(this.message);
  @override
  String toString() => message;
}

class AddressRepository {
  AddressRepository(this._client);

  final SupabaseClient _client;

  /// This customer's saved addresses, default first. Empty list (never an
  /// error) when signed out or nothing saved yet.
  Future<List<CustomerAddress>> fetchMyAddresses() async {
    try {
      final rows = await _client
          .from('customer_addresses')
          .select()
          .order('is_default', ascending: false)
          .order('updated_at', ascending: false, nullsFirst: false)
          .order('created_at', ascending: false);
      return [for (final r in rows) CustomerAddress.fromRow(Map<String, dynamic>.from(r))];
    } catch (_) {
      return const [];
    }
  }

  /// Insert (when [addressId] is null) or update an address. Returns the id.
  Future<String> saveAddress({
    String? addressId,
    required String label,
    required String tag,
    String? recipientName,
    String? phone,
    String? house,
    String? street,
    String? landmark,
    String? area,
    String? city,
    String? district,
    String? state,
    String? pincode,
    required double latitude,
    required double longitude,
    required String formattedAddress,
    String? deliveryInstructions,
    bool isDefault = false,
  }) async {
    try {
      final id = await _client.rpc('save_customer_address', params: {
        'p_label': label,
        'p_tag': tag,
        'p_recipient_name': recipientName,
        'p_phone': phone,
        'p_house': house,
        'p_street': street,
        'p_landmark': landmark,
        'p_area': area,
        'p_city': city,
        'p_district': district,
        'p_state': state,
        'p_pincode': pincode,
        'p_latitude': latitude,
        'p_longitude': longitude,
        'p_formatted_address': formattedAddress,
        'p_delivery_instructions': deliveryInstructions,
        'p_is_default': isDefault,
        'p_address_id': addressId,
      });
      return id as String;
    } on PostgrestException catch (e) {
      final m = e.message.toLowerCase();
      if (m.contains('map location')) throw const AddressException('Please set your location on the map.');
      if (m.contains('address cannot be empty')) throw const AddressException('Please fill in the address.');
      if (m.contains('no customer profile')) throw const AddressException('Your account is not fully set up yet.');
      throw const AddressException('Could not save this address. Please try again.');
    } catch (_) {
      throw const AddressException('Could not save this address. Please check your connection.');
    }
  }

  Future<void> setDefault(String addressId) async {
    try {
      await _client.rpc('set_default_customer_address', params: {'p_address_id': addressId});
    } catch (_) {
      throw const AddressException('Could not update your default address.');
    }
  }

  Future<void> deleteAddress(String addressId) async {
    try {
      await _client.rpc('delete_customer_address', params: {'p_address_id': addressId});
    } catch (_) {
      throw const AddressException('Could not delete this address.');
    }
  }
}
