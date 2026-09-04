import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../booking/booking_form_screen.dart';
import '../data/services_catalog_repository.dart';
import '../models/service_method.dart';
import '../models/vendor_method_group.dart';
import '../theme/service_colors.dart';
import 'widgets/service_method_card.dart';

/// Vendor Profile (spec): a provider's services listed **individually**,
/// each with its own eligible Service Methods. The customer only ever sees
/// methods the `browse_service_methods` RPC returned for them — live +
/// vendor-enabled, inside the method's radius, with a per-method
/// "Currently Unavailable" state for a transiently un-bookable one. A
/// method suspended for this vendor simply isn't in the list; the vendor
/// and their other methods still show.
class VendorProfileScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;
  final double ratingAvg;
  final int ratingCount;

  /// Optional scope — when the customer arrived from a category/service
  /// browse, keep the profile scoped to that category so it doesn't list
  /// unrelated work.
  final String? categoryId;

  const VendorProfileScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    this.categoryId,
  });

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _repo = ServicesCatalogRepository(Supabase.instance.client);
  bool _isLoading = true;
  List<ServiceMethodBucket> _buckets = const [];
  bool _openingBooking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final methods = await _repo.fetchServiceMethods(
      vendorId: widget.vendorId,
      categoryId: widget.categoryId,
    );
    if (!mounted) return;
    setState(() {
      _buckets = groupMethodsByService(methods);
      _isLoading = false;
    });
  }

  Future<void> _book(ServiceMethodRow method) async {
    if (_openingBooking) return;
    final serviceId = method.serviceId;
    if (serviceId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This method is not linked to a specific service yet.')),
      );
      return;
    }
    setState(() => _openingBooking = true);
    final service = await _repo.fetchServiceById(serviceId);
    if (!mounted) return;
    setState(() => _openingBooking = false);
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this service. Please try again.')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingFormScreen(service: service, method: method)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ServiceColors.background,
      appBar: AppBar(
        backgroundColor: ServiceColors.headerBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: ServiceColors.textPrimary),
        title: Text(widget.vendorName,
            style: const TextStyle(color: ServiceColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buckets.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'This provider has no bookable services in your area right now.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: ServiceColors.textSecondary),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: ServiceColors.primaryBlueLight,
                          child: Icon(Icons.verified, color: ServiceColors.primaryBlue),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.vendorName,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                              if (widget.ratingCount > 0)
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: ServiceColors.ratingStar),
                                    const SizedBox(width: 3),
                                    Text('${widget.ratingAvg.toStringAsFixed(1)} (${widget.ratingCount})',
                                        style: const TextStyle(fontSize: 12, color: ServiceColors.textSecondary)),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    for (final bucket in _buckets) ...[
                      Text(bucket.serviceName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: ServiceColors.textPrimary)),
                      if (bucket.availableCount == 0)
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Text('No option available right now',
                              style: TextStyle(fontSize: 11.5, color: ServiceColors.accentRed)),
                        ),
                      const SizedBox(height: 8),
                      for (final method in bucket.methods)
                        ServiceMethodCard(
                          method: method,
                          onBook: method.isAvailable ? () => _book(method) : null,
                        ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
    );
  }
}
