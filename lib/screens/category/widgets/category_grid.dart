import 'package:flutter/material.dart';
import '../models/category_model.dart';
import 'category_card.dart';

class CategoryGrid extends StatelessWidget {
  final ValueChanged<CategoryModel>? onCategoryTap;

  const CategoryGrid({super.key, this.onCategoryTap});

  @override
  Widget build(BuildContext context) {
    final categories = CategoryModel.categories;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final category = categories[index];

        return CategoryCard(
          category: category,
          onTap: () => onCategoryTap?.call(category),
        );
      },
    );
  }
}
