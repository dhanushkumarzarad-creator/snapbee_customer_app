import 'package:flutter/material.dart';
import 'package:snapbee_customer_app/core/constants/app_colors.dart';

/// White rounded search bar shown below [HomeHeader], with a leading
/// search icon, placeholder copy, and a trailing "scan" (viewfinder)
/// icon for barcode / visual search.
class SearchBarWidget extends StatelessWidget {
  final String hintText;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onScanTap;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.hintText = 'Search for "Grocery, Food, Meat, more..."',
    this.readOnly = false,
    this.onChanged,
    this.onTap,
    this.onScanTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.creamBackground,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Material(
        elevation: 1.5,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: readOnly,
                onTap: onTap,
                onChanged: onChanged,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            InkWell(
              onTap: onScanTap,
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Icon(
                  Icons.crop_free_rounded,
                  color: AppColors.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
