import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/cart/cart_store.dart';
import '../../data/repositories/wishlist_repository.dart';
import '../../widgets/catalog_image.dart';
import '../home/widgets/product_model.dart';
import '../cart/cart_screen.dart';

/// Full-detail view for a single product — opened from any product card
/// across the app (trending, category, search, product list). Renders
/// only fields the catalog actually has ([ProductModel]); no fabricated
/// description/specs since the live `products` table doesn't carry them
/// yet (see product_repository.dart's column notes).
class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;

  final WishlistSource _wishlist = WishlistRepository(Supabase.instance.client);

  /// null until the initial check resolves; false when signed out (the
  /// toggle then prompts to sign in).
  bool? _wishlisted;
  bool _wishlistBusy = false;

  @override
  void initState() {
    super.initState();
    _loadWishlistState();
  }

  Future<void> _loadWishlistState() async {
    try {
      final ids = await _wishlist.fetchWishlistedProductIds();
      if (!mounted) return;
      setState(() => _wishlisted = ids.contains(widget.product.id));
    } catch (_) {
      if (!mounted) return;
      setState(() => _wishlisted = false);
    }
  }

  Future<void> _toggleWishlist() async {
    if (_wishlistBusy) return;
    final current = _wishlisted ?? false;
    setState(() {
      _wishlistBusy = true;
      _wishlisted = !current;
    });
    try {
      if (current) {
        await _wishlist.remove(widget.product.id);
      } else {
        await _wishlist.add(widget.product.id);
      }
      _showSnack(current ? 'Removed from wishlist' : 'Added to wishlist');
    } on WishlistUnavailableException {
      if (!mounted) return;
      setState(() => _wishlisted = current);
      _showSnack('Sign in to use your wishlist.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _wishlisted = current);
      _showSnack('Could not update your wishlist: $error');
    } finally {
      if (mounted) setState(() => _wishlistBusy = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _changeQuantity(int delta) {
    setState(() {
      _quantity = (_quantity + delta).clamp(1, 20);
    });
  }

  void _addToCart() {
    final product = widget.product;
    if (product.vendorId.isEmpty) {
      // Real `products.vendor_id` is required to resolve a delivery
      // branch at checkout — a product missing it can't usefully reach
      // the cart, so this is refused up front rather than failing later.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item is not available for delivery right now.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final result = CartStore.instance.addItem(
      productId: product.id,
      name: product.name,
      imageUrl: product.imageAssetPath,
      unit: product.unit,
      price: product.currentPrice,
      originalPrice: product.oldPrice,
      vendorId: product.vendorId,
      quantity: _quantity,
    );

    if (result == CartAddResult.vendorConflict) {
      _confirmReplaceCart(product);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_quantity x ${product.name} added to cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Real checkout is single-vendor (`place_customer_order` resolves one
  /// branch for the whole order), so `CartStore` refuses to mix vendors.
  /// Matches Blinkit/Zepto/Instamart's own "start a new cart?" prompt
  /// rather than silently dropping the conflicting item or the existing
  /// cart.
  Future<void> _confirmReplaceCart(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start a new cart?'),
        content: const Text(
          'Your cart has items from a different store. Adding this item '
          'will clear your current cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear cart & add'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    CartStore.instance.replaceWithItem(
      productId: product.id,
      name: product.name,
      imageUrl: product.imageAssetPath,
      unit: product.unit,
      price: product.currentPrice,
      originalPrice: product.oldPrice,
      vendorId: product.vendorId,
      quantity: _quantity,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$_quantity x ${product.name} added to cart'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProductHeroImage(
                      product: product,
                      isWishlisted: _wishlisted,
                      onToggleWishlist: _toggleWishlist,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (product.unit.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              product.unit,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (product.rating > 0)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E7D32),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        product.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 3),
                                      const Icon(
                                        Icons.star_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                                if (product.ratingCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    '${product.ratingCount} ratings',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.end,
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              Text(
                                '₹${product.currentPrice.toStringAsFixed(0)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryOrange,
                                ),
                              ),
                              if (product.hasDiscount) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    '₹${product.oldPrice!.toStringAsFixed(0)}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '${product.discountPercent}% OFF',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF2E7D32),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (!product.inStock) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'Currently out of stock',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (product.inStock)
              _AddToCartBar(
                quantity: _quantity,
                unitPrice: product.currentPrice,
                onIncrement: () => _changeQuantity(1),
                onDecrement: () => _changeQuantity(-1),
                onAddToCart: _addToCart,
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductHeroImage extends StatelessWidget {
  final ProductModel product;
  final bool? isWishlisted;
  final VoidCallback onToggleWishlist;

  const _ProductHeroImage({
    required this.product,
    required this.isWishlisted,
    required this.onToggleWishlist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.1,
          child: ColoredBox(
            color: theme.colorScheme.surfaceContainerHigh,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CatalogImage(
                    source: product.imageAssetPath,
                    placeholderIcon: Icons.image_not_supported_outlined,
                  ),
                ),
                if (product.hasDiscount)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${product.discountPercent}% OFF',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onError,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          left: 8,
          child: _CircleIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _CircleIconButton(
                icon: isWishlisted == true
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                iconColor: isWishlisted == true ? theme.colorScheme.error : null,
                onTap: onToggleWishlist,
              ),
              const SizedBox(width: 8),
              _CircleIconButton(
                icon: Icons.shopping_cart_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }
}

class _AddToCartBar extends StatelessWidget {
  final int quantity;
  final double unitPrice;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onAddToCart;

  const _AddToCartBar({
    required this.quantity,
    required this.unitPrice,
    required this.onIncrement,
    required this.onDecrement,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = unitPrice * quantity;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryOrange),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StepperButton(icon: Icons.remove, onTap: onDecrement),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  _StepperButton(icon: Icons.add, onTap: onIncrement),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onAddToCart,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add to Cart • ₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18, color: AppColors.primaryOrange),
      ),
    );
  }
}
