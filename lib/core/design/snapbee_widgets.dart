// ============================================================================
// snapbee_widgets.dart
// ----------------------------------------------------------------------------
// Reusable premium building blocks shared by every Customer-App screen and
// every vertical. Built 1:1 from the approved Daily Essentials reference
// screens: the centred SnapBee wordmark header, the peach hero card with the
// mascot + hand-lettered accent, the tinted quick-action rail, section
// headers, the green leaf promo footer, sectioned menu cards, stat tiles and
// the sticky bottom action bar.
//
// Presentation only — no business logic, no network, no navigation policy.
// ============================================================================

import 'package:flutter/material.dart';

import 'snapbee_ui.dart';

// ---------------------------------------------------------------------------
// Wordmark + app bar
// ---------------------------------------------------------------------------

/// "Snap" (ink) + "Bee" (orange), with an optional small subtitle beneath —
/// e.g. "Daily Essentials" or "Local Needs • Faster Life".
class SnapBeeWordmark extends StatelessWidget {
  final String? subtitle;
  final double size;
  final bool center;

  const SnapBeeWordmark({super.key, this.subtitle, this.size = 22, this.center = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Snap',
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                  color: SnapBeeColors.ink,
                  letterSpacing: -0.5,
                ),
              ),
              TextSpan(
                text: 'Bee',
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w800,
                  color: SnapBeeColors.orange,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: SnapBeeColors.brandBlue,
                letterSpacing: 0.2,
              ),
            ),
          ),
      ],
    );
  }
}

/// Standard screen app bar: back chevron on the left, centred wordmark, an
/// optional trailing widget (a "How it works?" pill, a help icon, …).
class SnapBeeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;
  final VoidCallback? onBack;

  const SnapBeeAppBar({
    super.key,
    this.subtitle = 'Daily Essentials',
    this.trailing,
    this.showBack = true,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              SizedBox(
                width: 48,
                child: showBack
                    ? IconButton(
                        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back, color: SnapBeeColors.ink),
                        splashRadius: 22,
                      )
                    : null,
              ),
              Expanded(child: Center(child: SnapBeeWordmark(subtitle: subtitle))),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48),
                child: Align(alignment: Alignment.centerRight, child: trailing),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded "How it works?" / "Help" style pill for the app-bar trailing
/// slot.
class SnapBeePillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final Color? color;

  const SnapBeePillButton({super.key, required this.label, this.icon, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? SnapBeeColors.orange;
    return Material(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: c),
                const SizedBox(width: 5),
              ],
              Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: c)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Page intro header (circular tinted icon + big title + subtitle)
// ---------------------------------------------------------------------------

class SnapBeePageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? tint;
  final Widget? trailing;

  const SnapBeePageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.tint,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = tint ?? SnapBeeColors.orange;
    return Padding(
      padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 4, SnapBeeSpacing.gutter, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
            child: Icon(icon, color: c, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SnapBeeText.h1),
                const SizedBox(height: 2),
                Text(subtitle, style: SnapBeeText.body),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero card (peach gradient + mascot + hand-lettered accent)
// ---------------------------------------------------------------------------

class SnapBeeHeroCard extends StatelessWidget {
  /// Rich title spans, e.g. ["Everything You Need,", "Delivered Fast!"] where
  /// the second line renders in the brand orange.
  final String titleTop;
  final String? titleAccent;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final String? scriptAccent;
  final String mascot;
  final String? tag;
  final EdgeInsets margin;

  const SnapBeeHeroCard({
    super.key,
    required this.titleTop,
    this.titleAccent,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.scriptAccent,
    this.mascot = SnapBeeMascots.scooter,
    this.tag,
    this.margin = const EdgeInsets.fromLTRB(
      SnapBeeSpacing.gutter,
      4,
      SnapBeeSpacing.gutter,
      4,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.fromLTRB(18, 18, 12, 18),
      decoration: BoxDecoration(
        gradient: SnapBeeColors.heroGradient,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard),
        boxShadow: SnapBeeShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (tag != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SnapBeeColors.orange,
                      borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
                    ),
                    child: Text(
                      tag!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  titleTop,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: SnapBeeColors.ink,
                    height: 1.15,
                  ),
                ),
                if (titleAccent != null)
                  Text(
                    titleAccent!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: SnapBeeColors.orangeDeep,
                      height: 1.15,
                    ),
                  ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: SnapBeeColors.inkSoft,
                      height: 1.35,
                    ),
                  ),
                ],
                if (ctaLabel != null) ...[
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: onCta,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                      decoration: BoxDecoration(
                        color: SnapBeeColors.navy,
                        borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            ctaLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Column(
              children: [
                SnapBeeMascotImage(asset: mascot, height: 96),
                if (scriptAccent != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    scriptAccent!,
                    textAlign: TextAlign.center,
                    style: SnapBeeText.script.copyWith(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Mascot image with a friendly fallback so a missing asset never throws off
/// a layout.
class SnapBeeMascotImage extends StatelessWidget {
  final String asset;
  final double height;
  final BoxFit fit;

  const SnapBeeMascotImage({
    super.key,
    required this.asset,
    this.height = 90,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      height: height,
      fit: fit,
      errorBuilder: (_, _, _) => Icon(
        Icons.emoji_nature_rounded,
        size: height * 0.7,
        color: SnapBeeColors.orange.withValues(alpha: 0.6),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick-action rail (tinted circular icons in a white card)
// ---------------------------------------------------------------------------

class SnapBeeQuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const SnapBeeQuickAction({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });
}

class SnapBeeQuickActionRail extends StatelessWidget {
  final List<SnapBeeQuickAction> actions;
  final bool card;

  const SnapBeeQuickActionRail({super.key, required this.actions, this.card = true});

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        for (final a in actions)
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
              onTap: a.onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.icon, color: a.color, size: 21),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      a.label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SnapBeeColors.ink,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );

    if (!card) return Padding(padding: SnapBeeSpacing.screenH, child: row);

    return Container(
      margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 8, SnapBeeSpacing.gutter, 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: SnapBeeColors.surface,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
        boxShadow: SnapBeeShadows.soft,
      ),
      child: row,
    );
  }
}

// ---------------------------------------------------------------------------
// Section header (bold title + "See All ›")
// ---------------------------------------------------------------------------

class SnapBeeSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  const SnapBeeSectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'See All',
    this.onAction,
    this.padding = const EdgeInsets.fromLTRB(
      SnapBeeSpacing.gutter,
      6,
      SnapBeeSpacing.gutter,
      10,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(title, style: SnapBeeText.h2)),
          if (onAction != null && actionLabel != null)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      actionLabel!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: SnapBeeColors.orange,
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: SnapBeeColors.orange),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Generic white card
// ---------------------------------------------------------------------------

class SnapBeeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const SnapBeeCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SnapBeeSpacing.lg),
    this.margin = const EdgeInsets.symmetric(
      horizontal: SnapBeeSpacing.gutter,
      vertical: 6,
    ),
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? SnapBeeColors.surface,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
        boxShadow: SnapBeeShadows.card,
        border: border,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sectioned menu card (Profile / Settings style rows)
// ---------------------------------------------------------------------------

class SnapBeeMenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingText;
  final Color? color;
  final VoidCallback? onTap;

  const SnapBeeMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.color,
    this.onTap,
  });
}

class SnapBeeMenuCard extends StatelessWidget {
  final String? sectionTitle;
  final List<SnapBeeMenuItem> items;

  const SnapBeeMenuCard({super.key, this.sectionTitle, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sectionTitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 14, SnapBeeSpacing.gutter, 8),
            child: Text(sectionTitle!, style: SnapBeeText.h2),
          ),
        Container(
          margin: SnapBeeSpacing.screenH,
          decoration: BoxDecoration(
            color: SnapBeeColors.surface,
            borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
            boxShadow: SnapBeeShadows.card,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _row(context, items[i]),
                if (i != items.length - 1)
                  const Divider(height: 1, thickness: 1, color: SnapBeeColors.hairline, indent: 60),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(BuildContext context, SnapBeeMenuItem item) {
    final c = item.color ?? SnapBeeColors.orange;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(color: c.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(item.icon, size: 18, color: c),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: SnapBeeText.title),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(item.subtitle!, style: SnapBeeText.caption),
                    ],
                  ],
                ),
              ),
              if (item.trailingText != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(item.trailingText!, style: SnapBeeText.label),
                ),
              const Icon(Icons.chevron_right, color: SnapBeeColors.inkFaint, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stat tiles ("128 / Total Orders" quad row)
// ---------------------------------------------------------------------------

class SnapBeeStat {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const SnapBeeStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
  });
}

class SnapBeeStatRow extends StatelessWidget {
  final List<SnapBeeStat> stats;

  const SnapBeeStatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SnapBeeSpacing.screenH,
      child: Row(
        children: [
          for (int i = 0; i < stats.length; i++) ...[
            if (i != 0) const SizedBox(width: 10),
            Expanded(child: _tile(stats[i])),
          ],
        ],
      ),
    );
  }

  Widget _tile(SnapBeeStat s) {
    return InkWell(
      borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
      onTap: s.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: SnapBeeColors.surface,
          borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
          boxShadow: SnapBeeShadows.soft,
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: s.color.withValues(alpha: 0.14), shape: BoxShape.circle),
              child: Icon(s.icon, size: 17, color: s.color),
            ),
            const SizedBox(height: 8),
            Text(s.value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: SnapBeeColors.ink)),
            const SizedBox(height: 2),
            Text(
              s.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: SnapBeeColors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips (horizontal scroll, single-select)
// ---------------------------------------------------------------------------

class SnapBeeFilterChips extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<IconData?>? icons;
  final Color? accent;

  const SnapBeeFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.icons,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final a = accent ?? SnapBeeColors.orange;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: SnapBeeSpacing.screenH,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final sel = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? a : SnapBeeColors.surface,
                borderRadius: BorderRadius.circular(SnapBeeSpacing.rChip),
                border: Border.all(color: sel ? a : SnapBeeColors.hairline),
                boxShadow: sel ? null : SnapBeeShadows.soft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icons != null && icons![i] != null) ...[
                    Icon(icons![i], size: 15, color: sel ? Colors.white : SnapBeeColors.inkSoft),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : SnapBeeColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Green leaf promo footer
// ---------------------------------------------------------------------------

class SnapBeePromoFooter extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? scriptAccent;
  final String mascot;

  const SnapBeePromoFooter({
    super.key,
    this.title = 'Good Food. Better Life.',
    this.subtitle = 'Thank you for being a part of SnapBee!',
    this.scriptAccent = 'Together for a\nBetter Tomorrow!',
    this.mascot = SnapBeeMascots.club,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 14, SnapBeeSpacing.gutter, 18),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: SnapBeeColors.mintGradient,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard),
      ),
      child: Row(
        children: [
          const Icon(Icons.eco_rounded, color: SnapBeeColors.success, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Color(0xFF1F7A3D))),
                const SizedBox(height: 2),
                Text(subtitle, style: SnapBeeText.caption.copyWith(color: const Color(0xFF3C6B4B))),
              ],
            ),
          ),
          SnapBeeMascotImage(asset: mascot, height: 54),
          if (scriptAccent != null) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 74,
              child: Text(
                scriptAccent!,
                style: SnapBeeText.script.copyWith(fontSize: 10.5, color: const Color(0xFF1F7A3D)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small coloured info strip
// ---------------------------------------------------------------------------

class SnapBeeInfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color fill;
  final Widget? trailing;

  const SnapBeeInfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.color = SnapBeeColors.info,
    this.fill = SnapBeeColors.infoFill,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SnapBeeSpacing.gutter, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: SnapBeeText.body.copyWith(color: color, fontSize: 13))),
          ?trailing,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Buttons
// ---------------------------------------------------------------------------

class SnapBeePrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final Color? color;

  const SnapBeePrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expand = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? SnapBeeColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SnapBeeSpacing.rField)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label),
          if (icon != null) ...[const SizedBox(width: 8), Icon(icon, size: 18)],
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class SnapBeeOutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expand;
  final Color? color;

  const SnapBeeOutlineButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.expand = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? SnapBeeColors.orange;
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: c,
        backgroundColor: c.withValues(alpha: 0.06),
        minimumSize: const Size.fromHeight(52),
        side: BorderSide(color: c.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SnapBeeSpacing.rField)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label),
        ],
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// ---------------------------------------------------------------------------
// Sticky bottom action bar (₹ total + primary CTA)
// ---------------------------------------------------------------------------

class SnapBeeBottomBar extends StatelessWidget {
  final Widget? leading;
  final List<Widget> actions;

  const SnapBeeBottomBar({super.key, this.leading, required this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: SnapBeeColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          ?leading,
          if (leading != null) const SizedBox(width: 12),
          for (int i = 0; i < actions.length; i++) ...[
            if (i != 0) const SizedBox(width: 10),
            Expanded(child: actions[i]),
          ],
        ],
      ),
    );
  }
}

class SnapBeeTotalLabel extends StatelessWidget {
  final String amount;
  final String? caption;

  const SnapBeeTotalLabel({super.key, required this.amount, this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: SnapBeeColors.ink)),
        if (caption != null) Text(caption!, style: SnapBeeText.caption),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class SnapBeeEmptyState extends StatelessWidget {
  final String mascot;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SnapBeeEmptyState({
    super.key,
    this.mascot = SnapBeeMascots.search,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SnapBeeMascotImage(asset: mascot, height: 120),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center, style: SnapBeeText.h2),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: SnapBeeText.body),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              SnapBeePrimaryButton(label: actionLabel!, onPressed: onAction, expand: false),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar (tier / rewards / free-delivery threshold)
// ---------------------------------------------------------------------------

class SnapBeeProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  final double height;

  const SnapBeeProgressBar({
    super.key,
    required this.value,
    this.color = SnapBeeColors.success,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: color.withValues(alpha: 0.16),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
