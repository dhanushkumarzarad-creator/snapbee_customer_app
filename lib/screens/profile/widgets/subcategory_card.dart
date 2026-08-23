import 'package:flutter/material.dart';
import '../category_models.dart';
import '../snapbee_theme.dart';

/// Card used inside the 2-column Sub Categories [GridView].
class SubCategoryCard extends StatelessWidget {
  final SubCategoryModel subCategory;
  final VoidCallback? onTap;

  const SubCategoryCard({super.key, required this.subCategory, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SnapBeeColors.cardBackground,
      borderRadius: BorderRadius.circular(SnapBeeRadii.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(SnapBeeRadii.card),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(SnapBeeRadii.card),
            boxShadow: const [
              BoxShadow(
                color: SnapBeeColors.shadow,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(SnapBeeRadii.card),
                  ),
                  child: Image.network(
                    subCategory.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: SnapBeeColors.unselectedChip,
                      child: const Icon(
                        Icons.image_not_supported,
                        color: SnapBeeColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Text(
                  subCategory.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: SnapBeeColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
