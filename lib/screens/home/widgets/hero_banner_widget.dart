import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';

/// Full-width promotional hero banner shown below the service tabs
/// ("Everything You Need, Delivered Fast!"). Renders on an orange
/// gradient with decorative hexagon accents, a headline + subtitle, a
/// black "Order Now" pill button, a slot for the SnapBee mascot
/// illustration, and a page-dot indicator (for when this becomes a
/// multi-banner carousel).
class HeroBannerWidget extends StatelessWidget {
  final String headline;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onCtaTap;
  final String? mascotImageUrl;
  final int pageCount;
  final int currentPage;

  const HeroBannerWidget({
    super.key,
    this.headline = 'Everything You Need,\nDelivered Fast!',
    this.subtitle = 'Groceries, Food, Meat & more\nat your doorstep',
    this.ctaLabel = 'Order Now',
    this.onCtaTap,
    this.mascotImageUrl,
    this.pageCount = 3,
    this.currentPage = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 185,
              decoration: const BoxDecoration(gradient: AppColors.heroGradient),
              child: Stack(
                children: [
                  // Decorative hexagon accents scattered in the background.
                  const Positioned(
                    top: 10,
                    left: 10,
                    child: _Hexagon(size: 26, opacity: 0.18),
                  ),
                  const Positioned(
                    top: 60,
                    right: 90,
                    child: _Hexagon(size: 18, opacity: 0.15),
                  ),
                  const Positioned(
                    bottom: 30,
                    right: 40,
                    child: _Hexagon(size: 22, opacity: 0.15),
                  ),
                  const Positioned(
                    top: 100,
                    right: 20,
                    child: _Hexagon(size: 16, opacity: 0.12),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                headline,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 14),
                              InkWell(
                                onTap: onCtaTap,
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        ctaLabel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 5,
                          child: _MascotSlot(imageUrl: mascotImageUrl),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pageCount, (i) {
              final active = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryOrange : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Slot reserved for the SnapBee bee-mascot illustration holding a
/// delivery box. Supply [imageUrl] (or swap this for an Image.asset)
/// to render the actual brand artwork; falls back to a simple icon
/// placeholder so the layout still renders without the asset.
class _MascotSlot extends StatelessWidget {
  final String? imageUrl;

  const _MascotSlot({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return Image.asset(imageUrl!, fit: BoxFit.contain);
    }
    return const Center(
      child: Icon(Icons.emoji_nature_rounded, size: 64, color: Colors.black45),
    );
  }
}

class _Hexagon extends StatelessWidget {
  final double size;
  final double opacity;

  const _Hexagon({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.hexagon_outlined,
      size: size,
      color: Colors.white.withValues(alpha: opacity),
    );
  }
}
