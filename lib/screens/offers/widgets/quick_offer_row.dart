import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../offer_models.dart';

/// Two large tappable offer tiles side by side — e.g. "Free Delivery"
/// and "Best % Offers" — as seen in the "Offers" section.
class QuickOffersRow extends StatelessWidget {
  final List<QuickOfferModel> offers;
  final ValueChanged<QuickOfferModel>? onTap;

  const QuickOffersRow({super.key, required this.offers, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(offers.length, (index) {
          final offer = offers[index];
          final bool isLast = index == offers.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 12),
              child: _QuickOfferTile(
                offer: offer,
                onTap: () => onTap?.call(offer),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _QuickOfferTile extends StatelessWidget {
  final QuickOfferModel offer;
  final VoidCallback? onTap;

  const _QuickOfferTile({required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadii.large),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: AppShadows.soft,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.lightOrange,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    offer.iconAsset,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    offer.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: -12,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.darkOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  offer.tagText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
