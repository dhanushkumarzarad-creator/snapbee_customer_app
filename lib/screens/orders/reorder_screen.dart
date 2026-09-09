import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../core/invoicing/invoice.dart';
import '../../core/invoicing/invoice_repository.dart';
import '../../data/cart/cart_store.dart';
import '../../data/repositories/product_repository.dart';
import '../cart/cart_screen.dart';

/// Reorder (reference 32) — lists what was in a past Daily Essentials order
/// (read live from the `get_or_create_invoice` RPC, the only place the
/// customer app can see an order's line items) and re-adds the selected
/// items to the cart by matching each item name back to a live product
/// (`ProductRepository.searchByName`). Items with no current match are
/// skipped and reported honestly — nothing is fabricated.
class ReorderScreen extends StatefulWidget {
  final String orderId;
  final String storeName;

  const ReorderScreen({super.key, required this.orderId, this.storeName = 'this store'});

  @override
  State<ReorderScreen> createState() => _ReorderScreenState();
}

class _ReorderScreenState extends State<ReorderScreen> {
  final _invoiceRepo = InvoiceRepository(Supabase.instance.client);
  final _productRepo = ProductRepository(Supabase.instance.client);

  bool _loading = true;
  String? _error;
  List<InvoiceLine> _lines = const [];
  late List<bool> _selected;
  late List<int> _qty;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invoice = await _invoiceRepo.fetch(
        vertical: InvoiceVertical.dailyEssentials,
        sourceId: widget.orderId,
      );
      if (!mounted) return;
      setState(() {
        _lines = invoice.lines;
        _selected = List<bool>.filled(_lines.length, true);
        _qty = [for (final l in _lines) l.quantity.round().clamp(1, 99)];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  int get _selectedCount => _selected.where((s) => s).length;

  Future<void> _addSelected() async {
    setState(() => _adding = true);
    int added = 0;
    final skipped = <String>[];
    try {
      for (var i = 0; i < _lines.length; i++) {
        if (!_selected[i]) continue;
        final name = _lines[i].description;
        final matches = await _productRepo.searchByName(name, limit: 1);
        if (matches.isEmpty || matches.first.vendorId.isEmpty) {
          skipped.add(name);
          continue;
        }
        final p = matches.first;
        final res = CartStore.instance.addItem(
          productId: p.id,
          name: p.name,
          imageUrl: p.primaryImageUrl ?? '',
          unit: p.unit,
          price: p.price,
          vendorId: p.vendorId,
          quantity: _qty[i],
        );
        if (res == CartAddResult.vendorConflict) {
          skipped.add('$name (different store)');
        } else {
          added++;
        }
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
    if (!mounted) return;
    final msg = added == 0
        ? 'No items could be re-added right now.'
        : 'Added $added item${added == 1 ? '' : 's'} to cart'
            '${skipped.isEmpty ? '' : ' • ${skipped.length} unavailable'}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (added > 0) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: const SnapBeeAppBar(subtitle: 'Daily Essentials'),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView()
                : _content(),
      ),
      bottomNavigationBar: (_loading || _error != null || _lines.isEmpty)
          ? null
          : SnapBeeBottomBar(
              actions: [
                SnapBeePrimaryButton(
                  label: _adding
                      ? 'Adding…'
                      : 'Add ${_selectedCount == 0 ? '' : '$_selectedCount '}to Cart',
                  icon: Icons.shopping_cart_rounded,
                  onPressed: (_adding || _selectedCount == 0) ? null : _addSelected,
                ),
              ],
            ),
    );
  }

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44, color: SnapBeeColors.inkFaint),
              const SizedBox(height: 12),
              Text("Couldn't load this order's items.", style: SnapBeeText.body, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SnapBeeOutlineButton(label: 'Retry', expand: false, onPressed: _load),
            ],
          ),
        ),
      );

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 8, SnapBeeSpacing.gutter, 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: SnapBeeColors.cream, borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard)),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.autorenew_rounded, color: SnapBeeColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reorder', style: SnapBeeText.h2),
                    Text('Quickly add your previous items to cart', style: SnapBeeText.caption),
                  ],
                ),
              ),
              const SnapBeeMascotImage(asset: SnapBeeMascots.shopping, height: 46),
            ],
          ),
        ),

        if (_lines.isEmpty)
          const SnapBeeEmptyState(
            mascot: SnapBeeMascots.orders,
            title: 'No items found for this order',
            message: 'We couldn\'t read the items from this order.',
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 8, SnapBeeSpacing.gutter, 4),
            child: Row(
              children: [
                Expanded(child: Text('Items from this order (${_lines.length})', style: SnapBeeText.h2)),
                GestureDetector(
                  onTap: () {
                    final all = _selected.every((s) => s);
                    setState(() => _selected = List<bool>.filled(_lines.length, !all));
                  },
                  child: Text(
                    _selected.every((s) => s) ? 'Clear all' : 'Select all',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: SnapBeeColors.orange),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < _lines.length; i++) _lineRow(i),
          SnapBeeInfoBanner(
            icon: Icons.info_outline_rounded,
            color: SnapBeeColors.warn,
            fill: SnapBeeColors.warnFill,
            text: 'Prices and availability may vary. Items are matched to the '
                'current catalogue — you can review the cart before checkout.',
          ),
        ],
      ],
    );
  }

  Widget _lineRow(int i) {
    final line = _lines[i];
    return SnapBeeCard(
      margin: const EdgeInsets.symmetric(horizontal: SnapBeeSpacing.gutter, vertical: 5),
      child: Row(
        children: [
          Checkbox(
            value: _selected[i],
            activeColor: SnapBeeColors.orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            onChanged: (v) => setState(() => _selected[i] = v ?? false),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.description, style: SnapBeeText.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('₹${line.unitPrice.toStringAsFixed(0)} each', style: SnapBeeText.caption),
              ],
            ),
          ),
          _stepper(i),
        ],
      ),
    );
  }

  Widget _stepper(int i) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: SnapBeeColors.orange.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _qty[i] = (_qty[i] - 1).clamp(1, 99)),
            child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.remove, size: 15, color: SnapBeeColors.orange)),
          ),
          Text('${_qty[i]}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          InkWell(
            onTap: () => setState(() => _qty[i] = (_qty[i] + 1).clamp(1, 99)),
            child: const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.add, size: 15, color: SnapBeeColors.orange)),
          ),
        ],
      ),
    );
  }
}
