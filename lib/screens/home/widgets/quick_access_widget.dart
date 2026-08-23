import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';

/// A single quick-access entry, e.g. Daily Essentials, Services, Travel.
class QuickAccessItem {
  final String label;
  final IconData icon;
  final bool highlighted;

  const QuickAccessItem({
    required this.label,
    required this.icon,
    this.highlighted = false,
  });
}

/// Horizontally scrollable row of top-level vertical shortcuts shown
/// right under the search bar (Daily Essentials, Services, Travel,
/// Entertainment, E-commerce, ...). The first item is visually
/// highlighted in orange to match the "sale" quick-access card.
class QuickAccessWidget extends StatelessWidget {
  final List<QuickAccessItem> items;
  final ValueChanged<int>? onItemTap;

  const QuickAccessWidget({
    super.key,
    this.items = const [
      QuickAccessItem(
        label: 'Daily Essentials',
        icon: Icons.shopping_cart,
        highlighted: true,
      ),
      QuickAccessItem(label: 'Services', icon: Icons.build_circle_outlined),
      QuickAccessItem(
        label: 'Travel',
        icon: Icons.directions_bus_filled_outlined,
      ),
      QuickAccessItem(label: 'Entertainment', icon: Icons.theaters_outlined),
      QuickAccessItem(label: 'E-Commerce', icon: Icons.shopping_bag_outlined),
    ],
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _QuickAccessCard(
            item: item,
            onTap: () => onItemTap?.call(index),
          );
        },
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  final QuickAccessItem item;
  final VoidCallback? onTap;

  const _QuickAccessCard({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool highlighted = item.highlighted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primaryOrange : AppColors.chipGrey,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              size: 34,
              color: highlighted ? Colors.white : AppColors.textPrimary,
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: highlighted ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
