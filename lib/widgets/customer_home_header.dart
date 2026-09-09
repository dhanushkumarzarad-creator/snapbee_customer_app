import 'package:flutter/material.dart';

/// One trailing action icon on [CustomerHomeHeader] (e.g. notifications,
/// cart) — an icon in a white circle with an optional numeric badge.
class HeaderAction {
  final IconData icon;
  final int badgeCount;
  final VoidCallback? onTap;

  const HeaderAction({required this.icon, this.badgeCount = 0, this.onTap});
}

/// Shared header shown at the top of a sector's Home / Categories screen — a
/// single-line location row (city + short address, tappable), an optional
/// centred brand mark, plus up to two trailing action icons. Fully
/// theme-parameterized (background/text/icon colors) so every sector renders
/// this same structure/spacing/behavior in its own brand color.
///
/// The location is a **single horizontal line** —
/// `📍 City ˅  •  Short address` — with the address ellipsized rather than
/// wrapping to a second line (reference `01_Home.png` / `02_Categories.png`).
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
  /// trailing action icons. When null the location block expands to fill.
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, color: iconColor, size: 20),
          const SizedBox(width: 4),
          Text(
            cityLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textPrimaryColor,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: textPrimaryColor, size: 18),
          if (addressLabel.trim().isNotEmpty) ...[
            const SizedBox(width: 6),
            Text('•',
                style: TextStyle(
                    color: textSecondaryColor, fontSize: 13, height: 1)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                addressLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textSecondaryColor, fontSize: 12.5),
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: centerWidget == null
            ? [Expanded(child: location), ...trailing]
            : [
                // Location takes the remaining left space and keeps its
                // single line (address ellipsizes); the wordmark sits to
                // its right and the actions pin to the far right.
                Expanded(child: location),
                const SizedBox(width: 10),
                centerWidget!,
                const SizedBox(width: 10),
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
