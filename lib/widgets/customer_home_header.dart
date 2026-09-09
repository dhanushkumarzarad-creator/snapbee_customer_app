import 'package:flutter/material.dart';

/// One trailing action icon on [CustomerHomeHeader] (e.g. notifications,
/// cart) — an icon in a white circle with an optional numeric badge.
class HeaderAction {
  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  const HeaderAction({required this.icon, this.badgeCount = 0, this.onTap});
}

/// Shared header shown at the top of a sector's Home screen — a location
/// row (city + short address, tappable), an optional centred brand mark,
/// plus up to two trailing action icons. Fully theme-parameterized
/// (background/text/icon colors) so every sector renders this same
/// structure/spacing/behavior in its own brand color rather than each
/// sector maintaining its own near-identical copy.
///
/// Extracted from Daily Essentials' original `HomeHeader`
/// (lib/screens/home/widgets/home_header.dart) — every value below
/// defaults to that widget's exact original values, so wiring Daily
/// Essentials to this shared component changes zero pixels of its
/// rendering when [centerWidget] is not supplied.
class CustomerHomeHeader extends StatelessWidget {
  final Color backgroundColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color iconColor;
  final String cityLabel;
  final String addressLabel;
  final VoidCallback? onLocationTap;
  final List<HeaderAction> actions;

  /// Optional brand mark shown centred between the location block and the
  /// trailing action icons (the "SnapBee / Local Needs - Faster Life"
  /// wordmark on the Daily Essentials Home reference). When null the header
  /// renders exactly as before — the location block simply expands to fill.
  final Widget? centerWidget;

  const CustomerHomeHeader({
    super.key,
    required this.backgroundColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.iconColor,
    this.cityLabel = 'Dharmapuri',
    this.addressLabel = 'Near Bus Stand, Dharmapuri',
    this.onLocationTap,
    this.actions = const [],
    this.centerWidget,
  });

  @override
  Widget build(BuildContext context) {
    final location = InkWell(
      onTap: onLocationTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, color: textPrimaryColor, size: 20),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  cityLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textPrimaryColor, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, color: textPrimaryColor, size: 20),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Text(
              addressLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textSecondaryColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );

    final trailing = <Widget>[
      for (final action in actions) ...[
        const SizedBox(width: 12),
        _HeaderIconButton(
          icon: action.icon,
          badgeCount: action.badgeCount,
          onTap: action.onTap,
          iconColor: iconColor,
        ),
      ],
    ];

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: centerWidget == null
            ? [Expanded(child: location), ...trailing]
            : [
                Flexible(child: location),
                const SizedBox(width: 8),
                const Spacer(),
                centerWidget!,
                const Spacer(),
                ...trailing,
              ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;
  final Color iconColor;

  const _HeaderIconButton({required this.icon, this.badgeCount = 0, this.onTap, required this.iconColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          if (badgeCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Center(
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
