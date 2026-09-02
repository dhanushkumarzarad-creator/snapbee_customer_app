import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/idempotency.dart';
import '../data/ecommerce_cart_store.dart';
import '../data/ecommerce_repository.dart';
import '../orders/ecommerce_orders_screen.dart';
import '../theme/ecommerce_colors.dart';

class EcommerceCheckoutScreen extends StatefulWidget {
  const EcommerceCheckoutScreen({super.key});

  @override
  State<EcommerceCheckoutScreen> createState() => _EcommerceCheckoutScreenState();
}

class _EcommerceCheckoutScreenState extends State<EcommerceCheckoutScreen> {
  final _repo = EcommerceRepository(Supabase.instance.client);
  final _line1 = TextEditingController();
  final _city = TextEditingController();
  final _pincode = TextEditingController();
  final _idempotencyKey = generateIdempotencyKey();
  bool _placing = false;
  String? _error;

  Future<void> _placeOrder() async {
    if (_line1.text.trim().isEmpty || _city.text.trim().isEmpty) {
      setState(() => _error = 'Enter a delivery address.');
      return;
    }
    final cart = EcommerceCartStore.instance;
    setState(() {
      _placing = true;
      _error = null;
    });
    try {
      final items = cart.items
          .map((i) => {
                'product_id': i.productId,
                if (i.variantId != null) 'variant_id': i.variantId,
                'quantity': i.quantity,
              })
          .toList();
      final orderId = await _repo.createOrder(
        vendorId: cart.vendorId!,
        items: items,
        shippingAddress: {'line1': _line1.text.trim(), 'city': _city.text.trim(), 'pincode': _pincode.text.trim()},
        idempotencyKey: _idempotencyKey,
      );
      // No real payment gateway exists anywhere in this monorepo yet — same
      // posture as every other sector this session: auto-confirm the
      // payment step honestly (a real gateway would plug in exactly here).
      await _repo.confirmOrderPayment(orderId, success: true);
      cart.clear();
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Order placed!'),
          content: Text('Order ID: $orderId'),
          actions: [FilledButton(onPressed: () => Navigator.pop(dialogContext), style: FilledButton.styleFrom(backgroundColor: EcommerceColors.primary), child: const Text('OK'))],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const EcommerceOrdersScreen()), (r) => r.isFirst);
    } catch (e) {
      setState(() => _error = 'Order failed: $e');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = EcommerceCartStore.instance;
    return Scaffold(
      backgroundColor: EcommerceColors.background,
      appBar: AppBar(title: const Text('Checkout'), backgroundColor: EcommerceColors.primary, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Delivery address', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(controller: _line1, decoration: const InputDecoration(labelText: 'Address line', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _city, decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          TextField(controller: _pincode, decoration: const InputDecoration(labelText: 'Pincode', border: OutlineInputBorder())),
          const Divider(height: 32),
          Text('Order summary (${cart.vendorName})', style: Theme.of(context).textTheme.titleMedium),
          ...cart.items.map((i) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${i.productName} x${i.quantity}'),
                subtitle: i.variantLabel != null ? Text(i.variantLabel!) : null,
                trailing: Text('₹${i.lineTotal}'),
              )),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('₹${cart.subtotal}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ]),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.red))],
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EcommerceColors.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: _placing ? null : _placeOrder,
            child: _placing ? const CircularProgressIndicator(color: Colors.white) : const Text('Place order'),
          ),
        ],
      ),
    );
  }
}
