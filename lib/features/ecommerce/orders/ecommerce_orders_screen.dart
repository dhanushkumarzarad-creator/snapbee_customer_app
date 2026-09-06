import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/invoicing/invoice.dart';
import '../../../core/invoicing/invoice_button.dart';
import '../data/ecommerce_repository.dart';
import '../theme/ecommerce_colors.dart';

class EcommerceOrdersScreen extends StatefulWidget {
  const EcommerceOrdersScreen({super.key});

  @override
  State<EcommerceOrdersScreen> createState() => _EcommerceOrdersScreenState();
}

class _EcommerceOrdersScreenState extends State<EcommerceOrdersScreen> {
  final _repo = EcommerceRepository(Supabase.instance.client);
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.myOrders();
  }

  void _reload() => setState(() => _future = _repo.myOrders());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcommerceColors.background,
      appBar: AppBar(title: const Text('My Orders'), backgroundColor: EcommerceColors.primary, foregroundColor: Colors.white),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Failed to load: ${snapshot.error}'));
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) return const Center(child: Text('No orders yet.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, i) {
              final o = orders[i];
              final vendorName = (o['ecommerce_vendors'] as Map?)?['business_name'] ?? '';
              final items = List<Map<String, dynamic>>.from(o['ecommerce_order_items'] as List? ?? []);
              final status = o['status'] as String;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(o['id'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Chip(label: Text(status)),
                      ]),
                      Text(vendorName as String, style: const TextStyle(color: EcommerceColors.textSecondary)),
                      const SizedBox(height: 4),
                      ...items.map((it) => Text('${it['product_name']}${it['variant_label'] != null ? ' (${it['variant_label']})' : ''} x${it['quantity']}')),
                      Text('Total: ₹${o['total_amount']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InvoiceActionButton(
                          vertical: InvoiceVertical.ecommerce,
                          sourceId: o['id'] as String,
                        ),
                      ),
                      if (status == 'pending_payment' || status == 'confirmed' || status == 'packed')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: () => _cancel(o['id'] as String), child: const Text('Cancel', style: TextStyle(color: Colors.red))),
                        ),
                      if (status == 'delivered')
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(onPressed: () => _showReviewSheet(context, o['id'] as String, items), child: const Text('Write a review')),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _cancel(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this order?'),
        content: const Text('A cancellation fee may apply per policy. Refund will be calculated automatically.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Yes, cancel')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final result = await _repo.cancelOrder(orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancelled. Refund: ₹${result['refund_amount']}')));
      _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cancellation failed: $e')));
    }
  }

  void _showReviewSheet(BuildContext context, String orderId, List<Map<String, dynamic>> items) {
    if (items.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _ReviewSheet(repo: _repo, orderId: orderId, items: items),
    );
  }
}

class _ReviewSheet extends StatefulWidget {
  final EcommerceRepository repo;
  final String orderId;
  final List<Map<String, dynamic>> items;
  const _ReviewSheet({required this.repo, required this.orderId, required this.items});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late String _productId = widget.items.first['product_id'] as String;
  double _rating = 5;
  final _text = TextEditingController();
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Write a review', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (widget.items.length > 1)
            DropdownButtonFormField<String>(
              initialValue: _productId,
              decoration: const InputDecoration(labelText: 'Product'),
              items: widget.items.map((it) => DropdownMenuItem(value: it['product_id'] as String, child: Text(it['product_name'] as String))).toList(),
              onChanged: (v) => setState(() => _productId = v!),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => IconButton(
                  icon: Icon(i < _rating ? Icons.star : Icons.star_border, color: EcommerceColors.ratingStar),
                  onPressed: () => setState(() => _rating = (i + 1).toDouble()),
                )),
          ),
          TextField(controller: _text, decoration: const InputDecoration(labelText: 'Review (optional)', border: OutlineInputBorder()), maxLines: 3),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: EcommerceColors.primary),
            onPressed: _submitting
                ? null
                : () async {
                    setState(() => _submitting = true);
                    try {
                      await widget.repo.submitReview(widget.orderId, _productId, rating: _rating, reviewText: _text.text.trim().isEmpty ? null : _text.text.trim());
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                    } finally {
                      if (mounted) setState(() => _submitting = false);
                    }
                  },
            child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit review'),
          ),
        ],
      ),
    );
  }
}
