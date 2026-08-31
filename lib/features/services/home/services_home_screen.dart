import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../screens/home/widgets/service_tabs_widget.dart';
import '../categories/service_list_screen.dart';
import '../data/services_booking_repository.dart';
import '../data/services_catalog_repository.dart';
import '../models/service.dart';
import '../notifications/service_notifications_screen.dart';
import '../models/service_category.dart';
import '../models/service_offer.dart';
import '../models/service_vendor_summary.dart';
import '../theme/service_colors.dart';
import 'widgets/services_category_rail.dart';
import 'widgets/services_header.dart';
import 'widgets/services_hero_banner.dart';
import 'widgets/services_quick_actions.dart';
import 'widgets/services_search_bar.dart';
import 'widgets/trusted_providers_rail.dart';

/// Services sector's Home page — mirrors Daily Essentials' `HomeScreen`
/// structure section-for-section (header, search, sector tabs, hero
/// banner, quick actions, category rail, a "popular/trusted" rail,
/// offers preview), with every section backed by a real repository call,
/// not fabricated content. Lives inside `ServicesMainScreen`'s
/// IndexedStack — [onNavigateToTab] lets its "See All"/quick-action taps
/// switch that shell's tabs instead of pushing a new route, matching how
/// Daily Essentials' own Home always lived inside a single shared shell.
class ServicesHomeScreen extends StatefulWidget {
  final ValueChanged<int>? onNavigateToTab;

  const ServicesHomeScreen({super.key, this.onNavigateToTab});

  @override
  State<ServicesHomeScreen> createState() => _ServicesHomeScreenState();
}

class _ServicesHomeScreenState extends State<ServicesHomeScreen> {
  final _repo = ServicesCatalogRepository(Supabase.instance.client);
  final _bookingRepo = ServicesBookingRepository(Supabase.instance.client);

  bool _isLoading = true;
  List<ServiceCategoryRow> _categories = const [];
  List<ServiceRow> _popularServices = const [];
  List<ServiceOfferRow> _offers = const [];
  List<ServiceVendorSummary> _trustedProviders = const [];
  int _unreadNotifications = 0;
  RealtimeChannel? _notifChannel;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
    _loadUnread();
    _subscribeNotifications();
  }

  @override
  void dispose() {
    if (_notifChannel != null) Supabase.instance.client.removeChannel(_notifChannel!);
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _repo.fetchCategories(),
      _repo.fetchPopularServices(),
      _repo.fetchOffers(),
      _repo.fetchTopRatedVendors(),
    ]);
    if (!mounted) return;
    setState(() {
      _categories = results[0] as List<ServiceCategoryRow>;
      _popularServices = results[1] as List<ServiceRow>;
      _offers = results[2] as List<ServiceOfferRow>;
      _trustedProviders = results[3] as List<ServiceVendorSummary>;
      _isLoading = false;
    });
  }

  Future<void> _loadUnread() async {
    final count = await _bookingRepo.unreadNotificationCount();
    if (mounted) setState(() => _unreadNotifications = count);
  }

  void _subscribeNotifications() {
    _notifChannel = Supabase.instance.client
        .channel('service_notifications:home')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_notifications',
          callback: (_) {
            if (mounted) _loadUnread();
          },
        )
        .subscribe();
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ServiceNotificationsScreen()),
    );
    _loadUnread();
  }

  void _openCategoryServices(ServiceCategoryRow category) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceListScreen(category: category)));
  }

  @override
  Widget build(BuildContext context) {
    final filteredCategories =
        _query.isEmpty ? _categories : _categories.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: ServiceColors.background,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ServicesHeader(
                  notificationCount: _unreadNotifications,
                  onLocationTap: () {},
                  onNotificationTap: _openNotifications,
                ),
                ServicesSearchBar(onChanged: (v) => setState(() => _query = v)),

                // Sector selector — same shared widget Daily Essentials uses,
                // themed blue and with Services flagged as the selected
                // sector (section 1: "Only Services gets the active visual
                // state").
                ServiceTabsWidget(
                  selectedFillColor: ServiceColors.primaryBlueLight,
                  selectedBorderColor: ServiceColors.primaryBlue,
                  selectedTextColor: ServiceColors.primaryBlueDark,
                  items: const [
                    ServiceTabItem(label: 'Daily Essentials', imagePath: 'assets/images/snapbee_slots/daily_essentials.png'),
                    ServiceTabItem(label: 'Services', imagePath: 'assets/images/snapbee_slots/service_services.png', selected: true),
                    ServiceTabItem(label: 'Travel', imagePath: 'assets/images/snapbee_slots/service_travel.png'),
                    ServiceTabItem(label: 'Entertainment', imagePath: 'assets/images/snapbee_slots/service_entertainment.png'),
                    ServiceTabItem(label: 'E-Commerce', imagePath: 'assets/images/snapbee_slots/service_ecommerce.png'),
                  ],
                  onTabTap: (index) {
                    // Index 0 = Daily Essentials — pop this whole Services
                    // shell back to it. Every other non-Services index stays
                    // a no-op, matching Daily Essentials Home's own
                    // not-built-yet behavior for Travel/Entertainment/
                    // E-Commerce.
                    if (index == 0) Navigator.pop(context);
                  },
                ),

                const SizedBox(height: 4),

                ServicesHeroBanner(onCtaTap: () => widget.onNavigateToTab?.call(2)),

                const SizedBox(height: 16),

                ServicesQuickActions(
                  onActionTap: (index) {
                    switch (index) {
                      case 0: // Categories
                        widget.onNavigateToTab?.call(2);
                      case 1: // Offers
                        widget.onNavigateToTab?.call(3);
                      case 2: // My Bookings
                        widget.onNavigateToTab?.call(4);
                      case 3: // Emergency
                        widget.onNavigateToTab?.call(2);
                      default:
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Coming soon.')),
                        );
                    }
                  },
                ),

                const SizedBox(height: 22),

                ServicesCategoryRail(
                  categories: filteredCategories,
                  isLoading: _isLoading,
                  onSeeAll: () => widget.onNavigateToTab?.call(2),
                  onCategoryTap: _openCategoryServices,
                ),

                const SizedBox(height: 22),

                TrustedProvidersRail(providers: _trustedProviders, isLoading: _isLoading),

                if (_popularServices.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Popular Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ServiceColors.textPrimary)),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        for (final service in _popularServices)
                          Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            color: Colors.white,
                            surfaceTintColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: ServiceColors.divider)),
                            child: ListTile(
                              title: Text(service.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${service.durationMinutes} min'),
                              trailing: Text('₹${service.basePrice.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, color: ServiceColors.primaryBlueDark)),
                              onTap: () {
                                final category = _categories.firstWhere(
                                  (c) => c.id == service.categoryId,
                                  orElse: () => ServiceCategoryRow(id: service.categoryId, name: 'Services', description: ''),
                                );
                                _openCategoryServices(category);
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                if (_offers.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ServiceColors.textPrimary)),
                        InkWell(
                          onTap: () => widget.onNavigateToTab?.call(3),
                          child: const Row(children: [
                            Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: ServiceColors.textSecondary)),
                            Icon(Icons.chevron_right, size: 18, color: ServiceColors.textSecondary),
                          ]),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 64,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _offers.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final offer = _offers[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(color: ServiceColors.primaryBlueLight, borderRadius: BorderRadius.circular(12), border: Border.all(color: ServiceColors.primaryBlue.withValues(alpha: 0.3))),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(offer.label, style: const TextStyle(fontWeight: FontWeight.w700, color: ServiceColors.primaryBlueDark)),
                              if (offer.description.isNotEmpty) Text(offer.description, style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
