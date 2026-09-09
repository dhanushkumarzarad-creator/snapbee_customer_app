import 'package:flutter/material.dart';

import '../../../core/design/snapbee_design.dart';

/// "Join SnapBee Club" promo banner near the bottom of Home — a light-blue
/// card with the mascot, a headline, one line of copy and a "Join Now" pill.
/// Presentation only; the CTA routes to the real SnapBee Club screen.
class ClubJoinBannerWidget extends StatelessWidget {
  final VoidCallback? onJoin;

  const ClubJoinBannerWidget({super.key, this.onJoin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 14, SnapBeeSpacing.gutter, 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: SnapBeeColors.skyCard,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard),
        boxShadow: SnapBeeShadows.soft,
      ),
      child: Row(
        children: [
          const SnapBeeMascotImage(asset: SnapBeeMascots.club, height: 66),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Join SnapBee Club',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SnapBeeColors.brandBlue,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Get exclusive offers, rewards and more!',
                  style: SnapBeeText.caption.copyWith(color: SnapBeeColors.inkSoft),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onJoin,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      color: SnapBeeColors.brandBlue,
                      borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Join Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
