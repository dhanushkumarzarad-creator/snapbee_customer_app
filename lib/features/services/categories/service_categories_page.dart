import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services_catalog_repository.dart';
import '../models/service_category.dart';
import '../theme/service_colors.dart';
import 'service_list_screen.dart';
import 'service_subcategory_list_screen.dart';

/// Dedicated Services Category page (section 3 of the Services spec) — a
/// bottom-nav destination in its own right, not just the compact rail
/// shown on Home. Mirrors Daily Essentials' `CategoryScreen` header
/// pattern (colored header + search) blue-themed; the content area is a
/// full grid rather than DE's sidebar+subcategory layout since this
/// schema's categories don't yet have DE's subcategory/featured-product
/// richness to browse — admin-managed, never hardcoded.
class ServiceCategoriesPage extends StatefulWidget {
  const ServiceCategoriesPage({super.key});

  @override
  State<ServiceCategoriesPage> createState() => _ServiceCategoriesPageState();
}

class _ServiceCategoriesPageState extends State<ServiceCategoriesPage> {
  final _repo = ServicesCatalogRepository(Supabase.instance.client);
  bool _isLoading = true;
  List<ServiceCategoryRow> _categories = const [];
  String _query = '';

  static const Map<String, IconData> _iconByName = {
    'ac_unit': Icons.ac_unit,
    'water_drop': Icons.water_drop,
    'electrical_services': Icons.electrical_services,
    'plumbing': Icons.plumbing,
    'cleaning_services': Icons.cleaning_services,
    'handyman': Icons.handyman,
    'more_horiz': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categories = await _repo.fetchCategories();
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  bool _openingCategory = false;

  /// Category tap: if the category has active subcategories, go through the
  /// Subcategory level first (Category -> Subcategory -> Service);
  /// otherwise straight to the service list. A brief guard prevents a
  /// double-push while the subcategory lookup is in flight.
  Future<void> _openCategory(ServiceCategoryRow category) async {
    if (_openingCategory) return;
    setState(() => _openingCategory = true);
    final subcategories = await _repo.fetchSubcategories(category.id);
    if (!mounted) return;
    setState(() => _openingCategory = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => subcategories.isEmpty
            ? ServiceListScreen(category: category)
            : ServiceSubcategoryListScreen(category: category, subcategories: subcategories),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty ? _categories : _categories.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: ServiceColors.headerBackground,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Categories', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ServiceColors.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Material(
                    elevation: 1.5,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 14, color: ServiceColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search service categories',
                        hintStyle: TextStyle(color: ServiceColors.textSecondary, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: ServiceColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text('No service categories available yet.'))
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filtered.length,
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.3,
                            ),
                            itemBuilder: (context, index) {
                              final category = filtered[index];
                              return _CategoryCard(
                                category: category,
                                icon: _iconByName[category.iconName ?? ''] ?? Icons.build_outlined,
                                onTap: () => _openCategory(category),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final ServiceCategoryRow category;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ServiceColors.primaryBlueLight,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: ServiceColors.primaryBlue),
              const SizedBox(height: 10),
              Text(category.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }
}
