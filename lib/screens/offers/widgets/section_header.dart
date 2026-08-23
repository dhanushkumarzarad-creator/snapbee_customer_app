import 'package:flutter/material.dart';
import '../app_colors.dart';

/// Reusable "Heading ... View All" row used by Special Offers,
/// Store Offers and Offer Banners sections.
class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAllTap;

  const SectionHeader({super.key, required this.title, this.onViewAllTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyles.sectionTitle),
          InkWell(
            onTap: onViewAllTap,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                children: const [
                  Icon(
                    Icons.grid_view_rounded,
                    size: 14,
                    color: AppColors.primaryOrange,
                  ),
                  SizedBox(width: 4),
                  Text('View All', style: AppTextStyles.viewAll),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
