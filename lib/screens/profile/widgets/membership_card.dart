import 'package:flutter/material.dart';

import '../../../core/constants/membership_constants.dart';

/// A real-feeling premium membership/loyalty card — metallic gradient,
/// honeycomb-texture overlay, glass status pill and an embossed-style
/// member line, instead of a flat two-tone Material [Container]. Tier
/// colors are keyed off [MembershipTier] so Silver/Gold/Platinum render
/// correctly the moment the Profile screen wires up a real tier instead
/// of the hardcoded Bronze it uses today — this widget doesn't change
/// that data, only how it's presented.
class MembershipCard extends StatelessWidget {
  final MembershipTier tier;
  final int totalOrders;
  final int benefitsCount;
  final int ordersToNextTier;
  final double progress;

  const MembershipCard({
    super.key,
    required this.tier,
    required this.totalOrders,
    required this.benefitsCount,
    required this.ordersToNextTier,
    required this.progress,
  });

  _TierPalette get _palette => _TierPalette.of(tier);

  @override
  Widget build(BuildContext context) {
    final palette = _palette;
    final nextTier = MembershipThresholds.nextTier(tier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: palette.shadow.withValues(alpha: .38),
            blurRadius: 24,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Root cause of every earlier "washed out" attempt: a bare
            // non-positioned Container inside this Stack collapses to
            // near-zero height, because the Stack sits inside a
            // SingleChildScrollView's Column, which hands it UNBOUNDED
            // height — and a childless Container with no explicit size
            // shrinks to as-small-as-possible under unbounded constraints
            // (the opposite of what it does under bounded ones). Only the
            // outer boxShadow was ever visible, blended over the white
            // card above it. Positioned.fill sidesteps this entirely by
            // sizing explicitly to the Stack's resolved box instead.
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: palette.gradient,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              left: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: .12),
                      Colors.white.withValues(alpha: 0)
                    ],
                  ),
                ),
              ),
            ),
            // Hairline border for a cut, engraved edge.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.border, width: 1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [palette.emblemLight, palette.emblemDark],
                          ),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .5),
                              width: .8),
                        ),
                        child: const Icon(Icons.hive_rounded,
                            color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tier.label.toUpperCase()} BEE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              palette.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .78),
                                fontSize: 12.5,
                                letterSpacing: .2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(label: 'ACTIVE'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _StatColumn(
                            label: 'Total Orders', value: '$totalOrders'),
                      ),
                      Container(
                          height: 30,
                          width: 1,
                          color: Colors.white.withValues(alpha: .22)),
                      const SizedBox(width: 18),
                      Expanded(
                        child: _StatColumn(
                            label: 'Benefits', value: '$benefitsCount+'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (nextTier != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        height: 7,
                        child: Stack(
                          children: [
                            Container(
                                color: Colors.white.withValues(alpha: .18)),
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [palette.emblemLight, Colors.white],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ordersToNextTier > 0
                                ? '$ordersToNextTier orders to reach ${nextTier.label}'
                                : 'Reaching ${nextTier.label} soon',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .92),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'SNAPBEE REWARDS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: .65),
                          fontSize: 10.5,
                          letterSpacing: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.emoji_events_rounded,
                          size: 15, color: Colors.white.withValues(alpha: .55)),
                    ],
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

class _StatusPill extends StatelessWidget {
  final String label;
  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: .4), width: .8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .6,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: Colors.white.withValues(alpha: .75), fontSize: 12.5),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1),
        ),
      ],
    );
  }
}

class _TierPalette {
  final List<Color> gradient;
  final Color border;
  final Color shadow;
  final Color emblemLight;
  final Color emblemDark;
  final String subtitle;

  const _TierPalette({
    required this.gradient,
    required this.border,
    required this.shadow,
    required this.emblemLight,
    required this.emblemDark,
    required this.subtitle,
  });

  static _TierPalette of(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.bronze:
        return const _TierPalette(
          gradient: [Color(0xFF3A2210), Color(0xFF6B3E1A), Color(0xFF8B4F22)],
          border: Color(0x33F4C89A),
          shadow: Color(0xFF4A2A12),
          emblemLight: Color(0xFFD98F4E),
          emblemDark: Color(0xFF6B3E1A),
          subtitle: 'Starter Member',
        );
      case MembershipTier.silver:
        return const _TierPalette(
          gradient: [Color(0xFF2E3138), Color(0xFF464B54), Color(0xFF7A808C)],
          border: Color(0x33F1F3F6),
          shadow: Color(0xFF2E3138),
          emblemLight: Color(0xFFC7CCD3),
          emblemDark: Color(0xFF565B65),
          subtitle: 'Silver Member',
        );
      case MembershipTier.gold:
        return const _TierPalette(
          gradient: [Color(0xFF3E2E02), Color(0xFF7A5C02), Color(0xFFAD830E)],
          border: Color(0x33FCE9A8),
          shadow: Color(0xFF3E2E02),
          emblemLight: Color(0xFFEFC55E),
          emblemDark: Color(0xFF8A6408),
          subtitle: 'Gold Member',
        );
      case MembershipTier.platinum:
        return const _TierPalette(
          gradient: [Color(0xFF1E1B33), Color(0xFF322D54), Color(0xFF554E8C)],
          border: Color(0x33E4E1FF),
          shadow: Color(0xFF1E1B33),
          emblemLight: Color(0xFFA9A2E8),
          emblemDark: Color(0xFF3A3660),
          subtitle: 'Platinum Member',
        );
    }
  }
}
