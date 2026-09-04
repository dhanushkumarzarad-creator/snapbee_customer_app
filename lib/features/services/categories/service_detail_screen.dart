import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../booking/booking_form_screen.dart';
import '../data/services_catalog_repository.dart';
import '../models/service.dart';
import '../models/service_method.dart';
import '../models/service_review.dart';
import '../models/service_vendor.dart';
import '../models/vendor_method_group.dart';
import '../theme/service_colors.dart';
import 'vendor_profile_screen.dart';
import 'widgets/service_method_card.dart';

class ServiceDetailScreen extends StatefulWidget {
  final ServiceRow service;

  const ServiceDetailScreen({super.key, required this.service});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  final _repo = ServicesCatalogRepository(Supabase.instance.client);
  bool _isLoadingProviders = true;
  bool _isLoadingMethods = true;
  List<ServiceVendorListing> _providers = const [];
  List<ServiceMethodRow> _methods = const [];
  List<ServiceReview> _reviews = const [];

  @override
  void initState() {
    super.initState();
    _loadMethods();
    _loadProviders();
    _loadReviews();
  }

  /// NEW Services Master Method architecture — the primary "how do I book
  /// this" surface. When at least one provider has a live, in-coverage
  /// method configured, the per-method cards (grouped by provider) replace
  /// the legacy flat provider list. Until then (most services, mid-
  /// migration) this is simply empty and the legacy list stays.
  Future<void> _loadMethods() async {
    final methods = await _repo.fetchServiceMethods(
      serviceId: widget.service.id,
      categoryId: widget.service.categoryId,
    );
    if (!mounted) return;
    setState(() {
      _methods = methods;
      _isLoadingMethods = false;
    });
  }

  Future<void> _loadProviders() async {
    final providers = await _repo.fetchVerifiedProviders(widget.service.id);
    if (!mounted) return;
    setState(() {
      _providers = providers;
      _isLoadingProviders = false;
    });
  }

  Future<void> _loadReviews() async {
    final reviews = await _repo.fetchServiceReviews(widget.service.id);
    if (!mounted) return;
    setState(() => _reviews = reviews);
  }

  void _bookWithMethod(ServiceMethodRow method) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingFormScreen(service: widget.service, method: method)),
    );
  }

  void _openVendorProfile(VendorMethodGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VendorProfileScreen(
          vendorId: group.vendorId,
          vendorName: group.vendorName,
          ratingAvg: group.ratingAvg,
          ratingCount: group.ratingCount,
          categoryId: widget.service.categoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.service;
    final hasMethods = _methods.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(service.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(service.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (!_isLoadingProviders && _providers.isNotEmpty) ...[
            const SizedBox(height: 6),
            _RatingSummary(providers: _providers),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _InfoChip(icon: Icons.schedule, label: '${service.durationMinutes} min'),
              if (service.warrantyDays > 0) _InfoChip(icon: Icons.verified_user_outlined, label: '${service.warrantyDays}-day warranty'),
              if (service.requiresInspection) const _InfoChip(icon: Icons.fact_check_outlined, label: 'Inspection required'),
              if (service.supportsEmergency) const _InfoChip(icon: Icons.warning_amber_rounded, label: 'Emergency available'),
            ],
          ),
          const SizedBox(height: 16),
          if (service.description.isNotEmpty) ...[
            const Text('Details', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(service.description),
            const SizedBox(height: 16),
          ],
          if (service.whatIncluded != null && service.whatIncluded!.isNotEmpty) ...[
            const Text("What's included", style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(service.whatIncluded!),
            const SizedBox(height: 16),
          ],
          if (service.requiresInspection)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This service starts with a paid inspection visit. You will receive a quotation to '
                      'approve before repair work begins.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Starting at ₹${service.basePrice.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFFF9100)),
          ),
          Text('At least ${service.minAdvancePercent.toStringAsFixed(0)}% advance required before work starts',
              style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
          const SizedBox(height: 16),

          // --- NEW: per-provider bookable methods (Master Method architecture) ---
          if (_isLoadingMethods)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
          else if (hasMethods)
            _MethodsSection(
              groups: groupMethodsByVendor(_methods),
              onBook: _bookWithMethod,
              onViewProvider: _openVendorProfile,
            ),

          // --- Legacy flat provider list — only while no method is configured ---
          if (!hasMethods) ...[
            if (!_isLoadingProviders) _AvailabilitySection(providers: _providers),
            const SizedBox(height: 24),
            const Text('Verified Providers', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            if (_isLoadingProviders)
              const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
            else if (_providers.isEmpty)
              const Text('A verified provider will be matched to your booking automatically.',
                  style: TextStyle(color: Colors.grey, fontSize: 12.5))
            else
              for (final provider in _providers)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.verified, color: Colors.green)),
                    title: Text(provider.businessName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text('${provider.ratingAvg.toStringAsFixed(1)} (${provider.ratingCount})'),
                        const SizedBox(width: 10),
                        Text(provider.businessType, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                    trailing: Text('₹${provider.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
          ],

          if (_reviews.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Customer Reviews', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            for (final review in _reviews) _ReviewTile(review: review),
          ],

          const SizedBox(height: 12),
          // A generic "Book Now" only makes sense when there is no explicit
          // method to choose; once methods exist the customer books by
          // tapping a specific method card above.
          if (!hasMethods)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingFormScreen(service: service))),
                child: const Text('Book Now'),
              ),
            ),
        ],
      ),
    );
  }
}

/// A weighted average across every verified provider's own `rating_avg` —
/// a cross-provider rating signal for a service (there is no per-service
/// rating column). The individual review list below it comes from
/// `service_reviews` and only populates once `service_reviews_public_select`
/// RLS (supabase/service_reviews_public_read.sql) is applied — until then
/// this weighted average is the only rating shown. Weighted by each
/// provider's `rating_count` so one provider with 200 reviews isn't diluted
/// by another with 1. Returns null when no provider has any ratings yet,
/// rather than fabricating a 0.0 average.
({double average, int totalCount})? weightedProviderRating(List<ServiceVendorListing> providers) {
  final rated = providers.where((p) => p.ratingCount > 0).toList();
  if (rated.isEmpty) return null;

  final totalCount = rated.fold<int>(0, (sum, p) => sum + p.ratingCount);
  final weightedSum = rated.fold<double>(0, (sum, p) => sum + p.ratingAvg * p.ratingCount);
  return (average: weightedSum / totalCount, totalCount: totalCount);
}

/// "Choose how to book" — the per-provider grouped list of bookable
/// delivery methods. Each provider is a small header (name + rating + how
/// many options), then its method cards. Providers with at least one
/// available method are ordered first (see [groupMethodsByVendor]).
class _MethodsSection extends StatelessWidget {
  final List<VendorMethodGroup> groups;
  final void Function(ServiceMethodRow) onBook;
  final void Function(VendorMethodGroup) onViewProvider;

  const _MethodsSection({
    required this.groups,
    required this.onBook,
    required this.onViewProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose how to book', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        const Text(
          'Each provider offers this service in one or more ways. Pick the one that suits you.',
          style: TextStyle(fontSize: 12.5, color: ServiceColors.textSecondary),
        ),
        const SizedBox(height: 12),
        for (final group in groups) ...[
          InkWell(
            onTap: () => onViewProvider(group),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.verified, size: 16, color: ServiceColors.accentGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      group.vendorName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: ServiceColors.textPrimary),
                    ),
                  ),
                  if (group.ratingCount > 0) ...[
                    const Icon(Icons.star, size: 13, color: ServiceColors.ratingStar),
                    const SizedBox(width: 2),
                    Text(
                      '${group.ratingAvg.toStringAsFixed(1)} (${group.ratingCount})',
                      style: const TextStyle(fontSize: 11.5, color: ServiceColors.textSecondary),
                    ),
                  ],
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, size: 16, color: ServiceColors.textSecondary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final method in group.methods)
            ServiceMethodCard(
              method: method,
              onBook: method.isAvailable ? () => onBook(method) : null,
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final List<ServiceVendorListing> providers;

  const _RatingSummary({required this.providers});

  @override
  Widget build(BuildContext context) {
    final rating = weightedProviderRating(providers);
    if (rating == null) return const SizedBox.shrink();
    final (:average, :totalCount) = rating;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 18, color: Colors.amber),
        const SizedBox(width: 4),
        Text(average.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Text('($totalCount ratings across $totalProviderLabel)', style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
      ],
    );
  }

  String get totalProviderLabel => providers.length == 1 ? '1 provider' : '${providers.length} providers';
}

/// Real availability signal: `fetchVerifiedProviders` already only returns
/// approved+active vendors (via `service_vendors_public_select` /
/// `service_pricing_public_select` RLS), so a non-empty list genuinely means
/// providers are live right now. There's no working-hours/schedule column
/// anywhere in this schema, so this deliberately doesn't fabricate one.
class _AvailabilitySection extends StatelessWidget {
  final List<ServiceVendorListing> providers;

  const _AvailabilitySection({required this.providers});

  @override
  Widget build(BuildContext context) {
    final available = providers.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: available ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            available ? Icons.check_circle : Icons.schedule,
            size: 18,
            color: available ? Colors.green.shade700 : Colors.orange.shade800,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              available
                  ? 'Available now — ${providers.length} verified provider${providers.length == 1 ? '' : 's'} ready to accept this booking'
                  : 'No dedicated provider live yet — a verified provider will be matched automatically once you book',
              style: TextStyle(
                fontSize: 12.5,
                color: available ? Colors.green.shade900 : Colors.orange.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ServiceReview review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(i <= review.rating ? Icons.star : Icons.star_border, size: 15, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${review.reviewerName ?? 'Customer'} · ${review.createdAt.day}/${review.createdAt.month}/${review.createdAt.year}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            if (review.reviewText != null) ...[
              const SizedBox(height: 4),
              Text(review.reviewText!, style: const TextStyle(fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12.5)),
      ],
    );
  }
}
