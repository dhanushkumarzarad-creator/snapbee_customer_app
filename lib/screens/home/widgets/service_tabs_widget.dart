import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';

/// A single top-level vertical shortcut, e.g. Daily Essentials,
/// Services, Travel.
class ServiceTabItem {
  final String label;
  final String imagePath;
  final bool selected;

  const ServiceTabItem({
    required this.label,
    required this.imagePath,
    this.selected = false,
  });
}

/// Horizontal row of top-level vertical shortcuts shown just below the
/// search bar (Daily Essentials, Services, Travel, Entertainment,
/// E-Commerce). The selected tab gets a light-orange highlighted pill
/// with orange icon/text; the rest render as plain icon + label.
class ServiceTabsWidget extends StatelessWidget {
  final List<ServiceTabItem> items;
  final ValueChanged<int>? onTabTap;

  const ServiceTabsWidget({
    super.key,
    this.items = const [
      ServiceTabItem(
        label: 'Daily Essentials',
        imagePath: 'assets/images/snapbee_slots/daily_essentials.png',
        selected: true,
      ),
      ServiceTabItem(
        label: 'Services',
        imagePath: 'assets/images/snapbee_slots/service_services.png',
      ),
      ServiceTabItem(
        label: 'Travel',
        imagePath: 'assets/images/snapbee_slots/service_travel.png',
      ),
      ServiceTabItem(
        label: 'Entertainment',
        imagePath: 'assets/images/snapbee_slots/service_entertainment.png',
      ),
      ServiceTabItem(
        label: 'E-Commerce',
        imagePath: 'assets/images/snapbee_slots/service_ecommerce.png',
      ),
    ],
    this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: SizedBox(
        height: 110,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            return _ServiceTab(item: item, onTap: () => onTabTap?.call(index));
          },
        ),
      ),
    );
  }
}

class _ServiceTab extends StatelessWidget {
  final ServiceTabItem item;
  final VoidCallback? onTap;

  const _ServiceTab({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: item.selected
              ? AppColors.primaryOrangeLight
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: item.selected
              ? Border.all(
                  color: AppColors.primaryOrange.withValues(alpha: 0.4),
                )
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              item.imagePath,
              width: item.selected ? 69 : 58,
              height: item.selected ? 69 : 58,
              fit: BoxFit.contain,
            ),

            const SizedBox(height: 6),

            Text(
              item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: item.selected ? FontWeight.w700 : FontWeight.w500,
                color: item.selected
                    ? AppColors.primaryOrangeDark
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
