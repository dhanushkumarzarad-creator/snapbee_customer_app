import 'package:flutter/material.dart';

import '../../theme/service_colors.dart';

/// Structurally identical to Daily Essentials' `HeroBannerWidget`
/// (gradient card, hexagon accents, headline/subtitle, pill CTA, mascot
/// slot, page-dot indicator), blue-themed with Services copy.
class ServicesHeroBanner extends StatelessWidget {
  final String headline;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback? onCtaTap;

  const ServicesHeroBanner({
    super.key,
    this.headline = 'Trusted Home Services,\nBooked in Minutes',
    this.subtitle = 'AC repair, plumbing, electrical & more\nat your doorstep',
    this.ctaLabel = 'Book Now',
    this.onCtaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 185,
          decoration: const BoxDecoration(gradient: ServiceColors.heroGradient),
          child: Stack(
            children: [
              const Positioned(top: 10, left: 10, child: _Hexagon(size: 26, opacity: 0.18)),
              const Positioned(top: 60, right: 90, child: _Hexagon(size: 18, opacity: 0.15)),
              const Positioned(bottom: 30, right: 40, child: _Hexagon(size: 22, opacity: 0.15)),
              const Positioned(top: 100, right: 20, child: _Hexagon(size: 16, opacity: 0.12)),
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
                            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.3),
                          ),
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: onCtaTap,
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                              decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(24)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(ctaLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Expanded(
                      flex: 5,
                      child: Center(child: Icon(Icons.handyman_rounded, size: 64, color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hexagon extends StatelessWidget {
  final double size;
  final double opacity;

  const _Hexagon({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.hexagon_outlined, size: size, color: Colors.white.withValues(alpha: opacity));
  }
}
