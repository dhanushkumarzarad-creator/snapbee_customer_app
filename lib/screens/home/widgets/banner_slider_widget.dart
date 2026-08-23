import 'dart:async';
import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';

/// Single promotional banner entry.
class BannerItem {
  final String title;
  final String highlight;
  final String subtitle;
  final String discountLabel;
  final String? imageUrl;
  final Color backgroundColor;

  const BannerItem({
    required this.title,
    required this.highlight,
    required this.subtitle,
    required this.discountLabel,
    this.imageUrl,
    this.backgroundColor = const Color(0xFF2B2B2B),
  });
}

/// Full-width auto-playing banner carousel (e.g. "Delicious Burger -
/// Super Discount 50% OFF") shown below the quick-access row. Dots
/// under the banner indicate the current page.
class BannerSliderWidget extends StatefulWidget {
  final List<BannerItem> banners;
  final Duration autoPlayInterval;
  final ValueChanged<int>? onBannerTap;

  const BannerSliderWidget({
    super.key,
    this.banners = const [
      BannerItem(
        title: 'DELICIOUS',
        highlight: 'BURGER',
        subtitle: 'SUPER DISCOUNT',
        discountLabel: '50% OFF',
      ),
    ],
    this.autoPlayInterval = const Duration(seconds: 4),
    this.onBannerTap,
  });

  @override
  State<BannerSliderWidget> createState() => _BannerSliderWidgetState();
}

class _BannerSliderWidgetState extends State<BannerSliderWidget> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    if (widget.banners.length <= 1) return;
    _timer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
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
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.banners.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return GestureDetector(
                onTap: () => widget.onBannerTap?.call(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: _BannerCard(banner: banner),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (i) {
              final active = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryOrange : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerItem banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: banner.backgroundColor,
        child: Stack(
          children: [
            // Decorative image circle on the right (placeholder if no
            // imageUrl is supplied yet).
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              child: Container(
                width: 190,
                alignment: Alignment.center,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primaryOrange.withValues(alpha: 0.25),
                  ),
                  child: banner.imageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            banner.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.fastfood,
                          color: Colors.white54,
                          size: 56,
                        ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 140, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        banner.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        banner.highlight,
                        style: const TextStyle(
                          color: AppColors.primaryOrange,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        banner.subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      banner.discountLabel,
                      style: const TextStyle(
                        color: AppColors.primaryOrangeDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
