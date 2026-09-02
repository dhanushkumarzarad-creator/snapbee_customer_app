import 'package:flutter/material.dart';

import '../data/ecommerce_cart_store.dart';
import '../checkout/ecommerce_checkout_screen.dart';
import '../theme/ecommerce_colors.dart';

class EcommerceCartScreen extends StatefulWidget {
  const EcommerceCartScreen({super.key});

  @override
  State<EcommerceCartScreen> createState() => _EcommerceCartScreenState();
}

class _EcommerceCartScreenState extends State<EcommerceCartScreen> {
  @override
  void initState() {
    super.initState();
    EcommerceCartStore.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    EcommerceCartStore.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final cart = EcommerceCartStore.instance;
    return Scaffold(
      backgroundColor: EcommerceColors.background,
      appBar: AppBar(title: const Text('Cart'), backgroundColor: EcommerceColors.primary, foregroundColor: Colors.white),
      body: cart.isEmpty
          ? const Center(child: Text('Your cart is empty.'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, i) {
                      final item = cart.items[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.shopping_bag, color: EcommerceColors.primary),
                          title: Text(item.productName),
                          subtitle: Text('${item.variantLabel ?? ''} · ₹${item.unitPrice} each'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.remove), onPressed: () => cart.updateQuantity(item.lineKey, item.quantity - 1)),
                              Text('${item.quantity}'),
                              IconButton(icon: const Icon(Icons.add), onPressed: () => cart.updateQuantity(item.lineKey, item.quantity + 1)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 16)),
                            Text('₹${cart.subtotal}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: EcommerceColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EcommerceCheckoutScreen())),
                          child: const Text('Proceed to checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
