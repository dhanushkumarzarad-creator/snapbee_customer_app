import 'package:flutter/material.dart';
import '../../../widgets/catalog_image.dart';
import '../models/category_model.dart';

class SubCategoryCard extends StatelessWidget {
  final SubCategoryModel subCategory;
  final VoidCallback? onTap;

  const SubCategoryCard({super.key, required this.subCategory, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CatalogImage(
                    source: subCategory.image,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  subCategory.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
