import 'package:flutter/material.dart';

import '../models/service_category.dart';
import '../models/service_subcategory.dart';
import '../theme/service_colors.dart';
import 'service_list_screen.dart';

/// The Subcategory level of the finalized Services hierarchy
/// (Category -> **Subcategory** -> Service -> Vendor -> Method). Only shown
/// when the tapped category actually has active subcategories — the
/// categories page fetches them first and pushes straight to
/// [ServiceListScreen] when there are none, so this screen is never a dead
/// end. The subcategory rows are passed in (already fetched) to avoid a
/// second round trip.
class ServiceSubcategoryListScreen extends StatelessWidget {
  final ServiceCategoryRow category;
  final List<ServiceSubcategoryRow> subcategories;

  const ServiceSubcategoryListScreen({
    super.key,
    required this.category,
    required this.subcategories,
  });

  void _openServices(BuildContext context, {ServiceSubcategoryRow? subcategory}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceListScreen(category: category, subcategory: subcategory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ServiceColors.background,
      appBar: AppBar(
        backgroundColor: ServiceColors.headerBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: ServiceColors.textPrimary),
        title: Text(category.name,
            style: const TextStyle(color: ServiceColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: subcategories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.apps, color: ServiceColors.primaryBlue),
                title: const Text('All services', style: TextStyle(fontWeight: FontWeight.w700)),
                trailing: const Icon(Icons.chevron_right, color: ServiceColors.textSecondary),
                onTap: () => _openServices(context),
              ),
            );
          }
          final sub = subcategories[index - 1];
          return Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: sub.description.isEmpty ? null : Text(sub.description),
              trailing: const Icon(Icons.chevron_right, color: ServiceColors.textSecondary),
              onTap: () => _openServices(context, subcategory: sub),
            ),
          );
        },
      ),
    );
  }
}
