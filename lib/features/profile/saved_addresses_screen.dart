import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../data/repositories/address_repository.dart';
import '../../screens/checkout/add_address_screen.dart';

/// Saved Addresses (reference 17 / 34) — the customer's real, persisted
/// address book (`customer_addresses`, via [AddressRepository]). Add / Edit
/// open the structured [AddAddressScreen] which persists through the
/// `save_customer_address` RPC; Set-Default and Delete go through their own
/// RPCs so the "one default per customer" invariant always holds.
class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _repo = AddressRepository(Supabase.instance.client);
  bool _loading = true;
  List<CustomerAddress> _addresses = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _repo.fetchMyAddresses();
    if (!mounted) return;
    setState(() {
      _addresses = list;
      _loading = false;
    });
  }

  Future<void> _addOrEdit([CustomerAddress? existing]) async {
    final saved = await Navigator.push<AddressResult?>(
      context,
      MaterialPageRoute(builder: (_) => AddAddressScreen(editing: existing)),
    );
    if (saved != null) _load();
  }

  Future<void> _setDefault(CustomerAddress a) async {
    try {
      await _repo.setDefault(a.id);
      await _load();
    } on AddressException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(CustomerAddress a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove "${a.label}" from your saved addresses?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: SnapBeeColors.danger),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteAddress(a.id);
      await _load();
    } on AddressException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  IconData _iconFor(String tag) {
    switch (tag) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'parents':
        return Icons.favorite_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: SnapBeeAppBar(
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SnapBeePillButton(label: 'Add New', icon: Icons.add_rounded, onTap: _addOrEdit),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                const SnapBeePageHeader(
                  icon: Icons.location_on_rounded,
                  title: 'Saved Addresses',
                  subtitle: 'Manage your delivery addresses',
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 6, SnapBeeSpacing.gutter, 6),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: SnapBeeColors.cream, borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivering Happiness Closer to You!', style: SnapBeeText.h2),
                            const SizedBox(height: 6),
                            Text('Save your addresses for a quicker checkout.', style: SnapBeeText.body.copyWith(fontSize: 12.5)),
                          ],
                        ),
                      ),
                      const SnapBeeMascotImage(asset: SnapBeeMascots.location, height: 78),
                    ],
                  ),
                ),
                if (_addresses.isEmpty)
                  Container(
                    margin: SnapBeeSpacing.screenH,
                    padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
                    decoration: BoxDecoration(
                      color: SnapBeeColors.surface,
                      borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
                      boxShadow: SnapBeeShadows.soft,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.map_outlined, size: 36, color: SnapBeeColors.inkFaint),
                        const SizedBox(height: 12),
                        Text('No saved addresses yet', style: SnapBeeText.title),
                        const SizedBox(height: 4),
                        Text('Add a delivery address to check out faster next time.',
                            textAlign: TextAlign.center, style: SnapBeeText.caption),
                      ],
                    ),
                  )
                else
                  for (final a in _addresses) _addressCard(a),
                const SnapBeePromoFooter(
                  title: 'We Deliver Closer to You!',
                  subtitle: 'Add your frequently used addresses for a seamless experience.',
                  scriptAccent: 'Same Day Delivery\nHappier You!',
                ),
              ],
            ),
      bottomNavigationBar: SnapBeeBottomBar(
        actions: [
          SnapBeePrimaryButton(label: 'Add New Address', icon: Icons.add_rounded, onPressed: _addOrEdit),
        ],
      ),
    );
  }

  Widget _addressCard(CustomerAddress a) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: SnapBeeSpacing.gutter, vertical: 5),
      decoration: BoxDecoration(
        color: a.isDefault ? SnapBeeColors.orangeTint.withValues(alpha: 0.5) : SnapBeeColors.surface,
        borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile),
        border: Border.all(color: a.isDefault ? SnapBeeColors.orange : SnapBeeColors.hairline),
        boxShadow: a.isDefault ? null : SnapBeeShadows.soft,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: SnapBeeColors.orange.withValues(alpha: 0.14), shape: BoxShape.circle),
                child: Icon(_iconFor(a.tag), color: SnapBeeColors.orange, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(child: Text(a.label, style: SnapBeeText.title, overflow: TextOverflow.ellipsis)),
                    if (a.isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: SnapBeeColors.orange, borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill)),
                        child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: SnapBeeColors.inkFaint),
                onSelected: (v) {
                  if (v == 'edit') _addOrEdit(a);
                  if (v == 'default') _setDefault(a);
                  if (v == 'delete') _delete(a);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (!a.isDefault) const PopupMenuItem(value: 'default', child: Text('Set as default')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(a.formattedAddress, style: SnapBeeText.caption),
          if ((a.phone ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 13, color: SnapBeeColors.inkFaint),
                const SizedBox(width: 5),
                Text(a.phone!, style: SnapBeeText.caption),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
