import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services_catalog_repository.dart';
import '../models/service.dart';
import '../models/service_category.dart';
import '../theme/service_colors.dart';
import 'service_detail_screen.dart';

/// Sort orders for the services-within-a-category listing. Only fields the
/// real `ServiceRow` model actually carries (price, duration, name) — no
/// popularity/rating sort here since no such column exists on `services`
/// (per-vendor rating only shows up later, on the detail screen).
enum ServiceSort { relevance, priceLowHigh, priceHighLow, durationShort, nameAZ }

extension on ServiceSort {
  String get label => switch (this) {
        ServiceSort.relevance => 'Relevance',
        ServiceSort.priceLowHigh => 'Price: Low to High',
        ServiceSort.priceHighLow => 'Price: High to Low',
        ServiceSort.durationShort => 'Duration: Shortest first',
        ServiceSort.nameAZ => 'Name: A to Z',
      };
}

/// Pure filter+sort over an already-fetched service list — split out of
/// [ServiceListScreen]'s build method so it's unit-testable without a
/// Supabase-backed widget test.
List<ServiceRow> filterAndSortServices(
  List<ServiceRow> services, {
  required String query,
  required ServiceSort sort,
}) {
  var result = query.isEmpty
      ? services
      : services
          .where((s) => s.name.toLowerCase().contains(query.toLowerCase()) || s.description.toLowerCase().contains(query.toLowerCase()))
          .toList();

  switch (sort) {
    case ServiceSort.relevance:
      break;
    case ServiceSort.priceLowHigh:
      result = [...result]..sort((a, b) => a.basePrice.compareTo(b.basePrice));
    case ServiceSort.priceHighLow:
      result = [...result]..sort((a, b) => b.basePrice.compareTo(a.basePrice));
    case ServiceSort.durationShort:
      result = [...result]..sort((a, b) => a.durationMinutes.compareTo(b.durationMinutes));
    case ServiceSort.nameAZ:
      result = [...result]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }
  return result;
}

class ServiceListScreen extends StatefulWidget {
  final ServiceCategoryRow category;

  const ServiceListScreen({super.key, required this.category});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final _repo = ServicesCatalogRepository(Supabase.instance.client);
  bool _isLoading = true;
  List<ServiceRow> _services = const [];
  String _query = '';
  ServiceSort _sort = ServiceSort.relevance;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final services = await _repo.fetchServices(widget.category.id);
    if (!mounted) return;
    setState(() {
      _services = services;
      _isLoading = false;
    });
  }

  List<ServiceRow> get _visibleServices => filterAndSortServices(_services, query: _query, sort: _sort);

  @override
  Widget build(BuildContext context) {
    final visible = _visibleServices;

    return Scaffold(
      backgroundColor: ServiceColors.background,
      appBar: AppBar(
        backgroundColor: ServiceColors.headerBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: ServiceColors.textPrimary),
        title: Text(widget.category.name, style: const TextStyle(color: ServiceColors.textPrimary, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    elevation: 1,
                    shadowColor: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(fontSize: 14, color: ServiceColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'Search services',
                        hintStyle: TextStyle(color: ServiceColors.textSecondary, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: ServiceColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Material(
                  elevation: 1,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                  child: PopupMenuButton<ServiceSort>(
                    tooltip: 'Sort',
                    initialValue: _sort,
                    onSelected: (v) => setState(() => _sort = v),
                    itemBuilder: (context) => [
                      for (final sort in ServiceSort.values) PopupMenuItem(value: sort, child: Text(sort.label)),
                    ],
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Icon(Icons.sort, color: ServiceColors.primaryBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _services.isEmpty
                    ? const Center(child: Text('No services available in this category yet.'))
                    : visible.isEmpty
                        ? const Center(child: Text('No services match your search.'))
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: visible.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final service = visible[index];
                                return Card(
                                  margin: EdgeInsets.zero,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      service.description.isEmpty
                                          ? '${service.durationMinutes} min'
                                          : '${service.description}\n${service.durationMinutes} min',
                                    ),
                                    isThreeLine: service.description.isNotEmpty,
                                    trailing: Text(
                                      '₹${service.basePrice.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                    ),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: service)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
