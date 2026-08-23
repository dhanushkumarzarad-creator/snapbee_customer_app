import 'dart:async';
import 'package:flutter/material.dart';
import '../app_colors.dart';
import '../offer_models.dart';

/// Reusable auto-scrolling banner carousel with rounded corners and a
/// page indicator. Used for both the Hero Offer Banner and the
/// Offer Banners section — pass a different [height] for each.
class OfferBannerCarousel extends StatefulWidget {
  final List<OfferBannerModel> banners;
  final double height;
  final Duration autoScrollInterval;
  final ValueChanged<OfferBannerModel>? onBannerTap;

  const OfferBannerCarousel({
    super.key,
    required this.banners,
    this.height = 180,
    this.autoScrollInterval = const Duration(seconds: 4),
    this.onBannerTap,
  });

  @override
  State<OfferBannerCarousel> createState() => _OfferBannerCarouselState();
}

class _OfferBannerCarouselState extends State<OfferBannerCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.94);
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.banners.length <= 1) return;
    _timer = Timer.periodic(widget.autoScrollInterval, (_) {
      if (!_controller.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.banners.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => widget.onBannerTap?.call(banner),
                  child: _BannerCard(banner: banner),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        _PageIndicator(count: widget.banners.length, current: _currentPage),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final OfferBannerModel banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            banner.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(color: AppColors.lightOrange),
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(color: AppColors.lightOrange);
            },
          ),
          // Dark gradient so white text stays readable over any photo.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                if (banner.ctaText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    banner.ctaText!,
                    style: const TextStyle(
                      color: AppColors.lightOrange,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (banner.discountLabel != null)
            Positioned(
              right: 20,
              top: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  banner.discountLabel!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int count;
  final int current;
  const _PageIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final bool active = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryOrange : AppColors.lightOrange,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
