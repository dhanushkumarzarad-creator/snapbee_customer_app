import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../categories/service_detail_screen.dart';
import '../categories/service_list_screen.dart';
import '../data/services_catalog_repository.dart';
import '../models/service_offer.dart';
import '../theme/service_colors.dart';

/// Dedicated Services Offers page (section 4 of the Services spec) —
/// mirrors Daily Essentials' Offer Zone app-bar pattern (colored header,
/// bold title), blue-themed. Every card here is a real `service_offers`
/// row from `ServicesCatalogRepository` — no fabricated banners/categories
/// this schema has no backing model for.
class ServicesOffersScreen extends StatefulWidget {
  const ServicesOffersScreen({super.key});

  @override
  State<ServicesOffersScreen> createState() => _ServicesOffersScreenState();
}

class _ServicesOffersScreenState extends State<ServicesOffersScreen> {
  final _repo = ServicesCatalogRepository(Supabase.instance.client);
  bool _isLoading = true;
  List<ServiceOfferRow> _offers = const [];
  String? _openingOfferId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final offers = await _repo.fetchOffers();
    if (!mounted) return;
    setState(() {
      _offers = offers;
      _isLoading = false;
    });
  }

  /// Resolves an offer to the real service/category it discounts and
  /// navigates there — `service_id` wins when both are set (it's the more
  /// specific target), falling back to `category_id`, and finally a
  /// storewide-offer notice when neither is set.
  Future<void> _openOffer(ServiceOfferRow offer) async {
    if (_openingOfferId != null) return;
    setState(() => _openingOfferId = offer.id);

    if (offer.serviceId != null) {
      final service = await _repo.fetchServiceById(offer.serviceId!);
      if (!mounted) return;
      setState(() => _openingOfferId = null);
      if (service != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service)));
        return;
      }
    } else if (offer.categoryId != null) {
      final category = await _repo.fetchCategoryById(offer.categoryId!);
      if (!mounted) return;
      setState(() => _openingOfferId = null);
      if (category != null) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceListScreen(category: category)));
        return;
      }
    } else {
      setState(() => _openingOfferId = null);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This offer applies storewide — browse Services categories to use it.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ServiceColors.headerBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: ServiceColors.textPrimary),
        title: const Text('Services Offers', style: TextStyle(color: ServiceColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _offers.isEmpty
                ? const _EmptyOffers()
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _offers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final offer = _offers[index];
                        return _OfferCard(
                          offer: offer,
                          isOpening: _openingOfferId == offer.id,
                          onTap: () => _openOffer(offer),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final ServiceOfferRow offer;
  final bool isOpening;
  final VoidCallback onTap;

  const _OfferCard({required this.offer, required this.isOpening, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ServiceColors.primaryBlueLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isOpening ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ServiceColors.primaryBlue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Icon(Icons.local_offer_rounded, color: ServiceColors.primaryBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ServiceColors.primaryBlueDark)),
                    if (offer.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(offer.description, style: const TextStyle(fontSize: 13, color: ServiceColors.textSecondary)),
                    ],
                    if (offer.code != null) ...[
                      const SizedBox(height: 6),
                      Text('Code: ${offer.code}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: ServiceColors.textPrimary)),
                    ],
                  ],
                ),
              ),
              if (isOpening)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              else
                const Icon(Icons.chevron_right, color: ServiceColors.primaryBlue),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOffers extends StatelessWidget {
  const _EmptyOffers();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined, size: 56, color: ServiceColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text('No offers available right now', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Check back soon for Services discounts.', style: TextStyle(color: ServiceColors.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
