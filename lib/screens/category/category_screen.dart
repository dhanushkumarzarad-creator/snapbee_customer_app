import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/design/snapbee_design.dart';
import '../../data/cart/cart_store.dart';
import '../../data/repositories/category_repository.dart';
import '../../widgets/customer_home_header.dart';
import '../../widgets/customer_search_bar.dart';
import '../cart/cart_screen.dart';
import '../notification/notification_screen.dart';
import '../products/product_list_screen.dart';
import '../search/search_screen.dart';
import '../../features/services/services_main_screen.dart';
import '../../features/travel/home/travel_main_screen.dart';
import '../../features/entertainment/home/entertainment_main_screen.dart';
import '../../features/ecommerce/home/ecommerce_main_screen.dart';
import 'widgets/category_selector.dart';
import 'widgets/category_grid_card.dart';

/// Customer Categories screen — reference `02_Categories.png`.
///
/// Top chip selector: ALL | FOOD | GROCERY | MEAT | SERVICES | TRAVEL |
/// ENTERTAINMENT | E-COMMERCE.
///  * ALL              → Daily Essentials main categories.
///  * FOOD/GROCERY/MEAT → the matching Daily Essentials main category + its
///                        sub categories.
///  * the four vertical chips → that vertical's main categories + their sub
///                        categories, from that vertical's own Admin-managed
///                        tables (`service_categories`/`service_subcategories`,
///                        `ecommerce_categories`, `categories` tagged with the
///                        vertical for Travel/Entertainment).
///
/// Every card image is the Admin-uploaded `image_url` from the backend — no
/// hardcoded production images, no fabricated counts. Missing image → a
/// clean category-appropriate icon.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _repo = CategoryRepository(Supabase.instance.client);

  String _chipKey = 'all';
  bool _loading = true;
  String? _error;

  /// Daily Essentials mains, cached (drives ALL + the food/grocery/meat
  /// filters).
  List<CategoryRow>? _deMains;

  /// Current grid contents.
  List<CategoryRow> _items = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
    CartStore.instance.addListener(_onCart);
  }

  @override
  void dispose() {
    CartStore.instance.removeListener(_onCart);
    super.dispose();
  }

  void _onCart() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    try {
      final mains = await _repo.fetchMains();
      if (!mounted) return;
      setState(() => _deMains = mains);
      await _applyChip('all');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  void _selectChip(CategoryChipSpec spec) {
    if (spec.key == _chipKey) return;
    setState(() => _chipKey = spec.key);
    _applyChip(spec.key);
  }

  Future<void> _applyChip(String key) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _loadItems(key);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<List<CategoryRow>> _loadItems(String key) async {
    switch (key) {
      case 'all':
        return _deMains ?? await _repo.fetchMains();

      case 'food':
      case 'grocery':
      case 'meat':
        final mains = _deMains ?? await _repo.fetchMains();
        final main = resolveMainForChip(mains, key);
        if (main == null) return const [];
        final subs = await _repo.fetchSubcategories(main.id);
        return [main, ...subs];

      case 'services':
        final cats = await _repo.fetchServiceCategories();
        final out = <CategoryRow>[...cats];
        for (final c in cats) {
          out.addAll(await _repo.fetchServiceSubcategories(c.id));
        }
        return out;

      case 'travel':
      case 'entertainment':
        final mains = await _repo.fetchMains(vertical: key);
        final out = <CategoryRow>[...mains];
        for (final m in mains) {
          out.addAll(await _repo.fetchSubcategories(m.id));
        }
        return out;

      case 'ecommerce':
        return _repo.fetchEcommerceCategories();

      default:
        return const [];
    }
  }

  void _openCategory(CategoryRow row) {
    final vertical = row.vertical ?? 'daily_essentials';
    Widget target;
    switch (vertical) {
      case 'services':
        target = const ServicesMainScreen();
        break;
      case 'travel':
        target = const TravelMainScreen();
        break;
      case 'entertainment':
        target = const EntertainmentMainScreen();
        break;
      case 'ecommerce':
        target = const EcommerceMainScreen();
        break;
      case 'daily_essentials':
      default:
        target = ProductListScreen(categoryName: row.name);
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => target));
  }

  String get _chipLabel =>
      kCategoryChips.firstWhere((c) => c.key == _chipKey).label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomerHomeHeader(
                    backgroundColor: AppColors.creamBackground,
                    textPrimaryColor: AppColors.textPrimary,
                    textSecondaryColor: AppColors.textSecondary,
                    iconColor: const Color.fromARGB(255, 219, 128, 0),
                    onLocationTap: () {},
                    centerWidget: const SnapBeeWordmark(
                      size: 21,
                      subtitle: 'Local Needs  •  Faster Life',
                    ),
                    actions: [
                      HeaderAction(
                        icon: Icons.notifications_none_rounded,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationScreen()),
                        ),
                      ),
                      HeaderAction(
                        icon: Icons.shopping_cart_outlined,
                        badgeCount: CartStore.instance.activeItemCount,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        ),
                      ),
                    ],
                  ),

                  CustomerSearchBar(
                    backgroundColor: AppColors.creamBackground,
                    textPrimaryColor: AppColors.textPrimary,
                    textSecondaryColor: AppColors.textSecondary,
                    readOnly: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    ),
                    onScanTap: () {},
                  ),

                  const SnapBeeHeroCard(
                    titleTop: 'Explore',
                    titleAccent: 'All Categories',
                    subtitle: 'Everything you need in one place',
                    mascot: SnapBeeMascots.shopping,
                    scriptAccent: 'Local Choices\nHappier Lives!',
                    margin: EdgeInsets.fromLTRB(
                        SnapBeeSpacing.gutter, 0, SnapBeeSpacing.gutter, 8),
                  ),

                  CategorySelector(
                    selectedKey: _chipKey,
                    onSelected: _selectChip,
                  ),

                  const SizedBox(height: 4),

                  _content(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 44, color: SnapBeeColors.inkFaint),
            const SizedBox(height: 12),
            Text('Could not load categories.\n$_error',
                textAlign: TextAlign.center, style: SnapBeeText.caption),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _applyChip(_chipKey),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return _EmptyState(label: _chipLabel);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 3 columns, ~20px page padding, ~10px gap — reference proportions.
        const pad = 20.0;
        const gap = 10.0;
        final cellW = (constraints.maxWidth - pad * 2 - gap * 2) / 3;
        // Near-square card (reference ratio ~0.95): a wide image area plus a
        // fixed name/arrow row.
        final cellH = cellW * 1.06;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(pad, 4, pad, 4),
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
            mainAxisExtent: cellH,
          ),
          itemBuilder: (context, i) {
            final row = _items[i];
            return CategoryGridCard(
              category: row,
              tintIndex: i,
              onTap: () => _openCategory(row),
            );
          },
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: SnapBeeColors.surface,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
        border: Border.all(color: SnapBeeColors.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: SnapBeeColors.orangeTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.grid_view_rounded,
                color: SnapBeeColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No $label categories yet', style: SnapBeeText.title),
                const SizedBox(height: 2),
                Text(
                  'Categories added by the SnapBee team will appear here.',
                  style: SnapBeeText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
