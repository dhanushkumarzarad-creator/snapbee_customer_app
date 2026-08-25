import 'package:flutter/material.dart';

/// Shared white rounded search bar shown below [CustomerHomeHeader], on a
/// colored header background. Theme-parameterized (background/text
/// colors); the trailing scan/viewfinder action only renders when
/// [onScanTap] is provided.
///
/// Extracted from Daily Essentials' original `SearchBarWidget`
/// (lib/screens/home/widgets/search_bar_widget.dart) — every value below
/// defaults to that widget's exact original values, so wiring Daily
/// Essentials to this shared component changes zero pixels of its
/// rendering.
class CustomerSearchBar extends StatelessWidget {
  final Color backgroundColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final String hintText;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final VoidCallback? onScanTap;
  final TextEditingController? controller;

  const CustomerSearchBar({
    super.key,
    required this.backgroundColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
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
      color: backgroundColor,
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
                style: TextStyle(fontSize: 15, color: textPrimaryColor),
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: TextStyle(color: textSecondaryColor, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: textSecondaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (onScanTap != null)
              InkWell(
                onTap: onScanTap,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Icon(Icons.crop_free_rounded, color: textPrimaryColor, size: 22),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
