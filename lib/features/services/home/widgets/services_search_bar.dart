import 'package:flutter/material.dart';

import '../../theme/service_colors.dart';

/// Structurally identical to Daily Essentials' `SearchBarWidget`
/// (white rounded pill on a colored header background), blue-themed, with
/// the barcode-scan action dropped — service categories aren't scanned.
class ServicesSearchBar extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const ServicesSearchBar({
    super.key,
    this.hintText = 'Search service categories',
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ServiceColors.headerBackground,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Material(
        elevation: 1.5,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: ServiceColors.textPrimary),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: ServiceColors.textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: ServiceColors.textSecondary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
