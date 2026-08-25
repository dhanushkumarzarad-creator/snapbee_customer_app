import 'package:flutter/material.dart';

import '../../models/service_vendor_summary.dart';
import '../../theme/service_colors.dart';

/// Structurally identical to Daily Essentials' `FeaturedStoreWidget`
/// ("Popular Stores Near You" — header + "See All", horizontal rail of
/// cards with a rating line), blue-themed and driven by real
/// `service_vendors` rows (`fetchTopRatedVendors()`) — verified,
/// admin-approved businesses only, never fabricated placeholder providers.
class TrustedProvidersRail extends StatelessWidget {
  final String title;
  final List<ServiceVendorSummary> providers;
  final bool isLoading;

  const TrustedProvidersRail({
    super.key,
    this.title = 'Trusted Providers',
    required this.providers,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading && providers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ServiceColors.textPrimary)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: isLoading
              ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: providers.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) => _ProviderCard(provider: providers[index]),
                ),
        ),
      ],
    );
  }
}

class _ProviderCard extends StatelessWidget {
  final ServiceVendorSummary provider;

  const _ProviderCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 168,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: ServiceColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: ServiceColors.primaryBlueLight,
                child: Icon(Icons.verified, color: ServiceColors.primaryBlue, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.businessName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 15, color: ServiceColors.ratingStar),
              const SizedBox(width: 2),
              Text(provider.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '(${provider.ratingCount})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: ServiceColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            provider.businessType == 'authorized_brand' ? 'Authorized Brand' : provider.businessType == 'service_center' ? 'Service Center' : 'Verified Business',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ServiceColors.primaryBlueDark),
          ),
        ],
      ),
    );
  }
}
