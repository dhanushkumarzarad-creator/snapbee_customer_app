import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../data/repositories/product_repository.dart';
import '../home/widgets/product_card_widget.dart';
import '../home/widgets/product_model.dart';
import '../products/product_details_screen.dart';

/// Full-catalog product search — opened from the Home search bar and the
/// Category screen's search field. Debounces keystrokes before querying
/// [ProductRepository.searchByName] against the live `products` table.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _productRepo = ProductRepository(Supabase.instance.client);
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  bool _isLoading = false;
  String? _errorMessage;
  String _query = '';
  List<ProductModel> _results = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value);
    if (value.trim().isEmpty) {
      setState(() {
        _results = const [];
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(value));
  }

  Future<void> _search(String value) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final rows = await _productRepo.searchByName(value);
      if (!mounted || value != _query) return;
      setState(() {
        _results = [for (final row in rows) ProductModel.fromRow(row)];
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted || value != _query) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  static const _suggestions = ['Milk', 'Bread', 'Eggs', 'Rice', 'Atta', 'Tomato', 'Onion', 'Bananas', 'Curd', 'Oil'];

  void _applySuggestion(String s) {
    _controller.text = s;
    _controller.selection = TextSelection.collapsed(offset: s.length);
    _onChanged(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // Header row: back + wordmark
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, SnapBeeSpacing.gutter, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: SnapBeeColors.ink),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Expanded(child: SnapBeeWordmark(subtitle: 'Search fresh products near you', center: false)),
                ],
              ),
            ),
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 8, SnapBeeSpacing.gutter, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: SnapBeeColors.surface,
                  borderRadius: BorderRadius.circular(SnapBeeSpacing.rField),
                  boxShadow: SnapBeeShadows.soft,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onChanged,
                  textInputAction: TextInputAction.search,
                  style: const TextStyle(fontSize: 15, color: SnapBeeColors.ink),
                  decoration: InputDecoration(
                    hintText: 'Search for groceries, food, meat…',
                    hintStyle: const TextStyle(color: SnapBeeColors.inkFaint, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: SnapBeeColors.inkFaint),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, color: SnapBeeColors.inkFaint, size: 20),
                            onPressed: () {
                              _controller.clear();
                              _onChanged('');
                            },
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_query.trim().isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 4, SnapBeeSpacing.gutter, 24),
        children: [
          Text('Popular searches', style: SnapBeeText.label),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in _suggestions)
                GestureDetector(
                  onTap: () => _applySuggestion(s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: SnapBeeColors.surface,
                      borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
                      border: Border.all(color: SnapBeeColors.hairline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.search, size: 14, color: SnapBeeColors.inkFaint),
                        const SizedBox(width: 6),
                        Text(s, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SnapBeeColors.inkSoft)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            decoration: BoxDecoration(gradient: SnapBeeColors.mintGradient, borderRadius: BorderRadius.circular(SnapBeeSpacing.rCard)),
            child: Row(
              children: [
                const SnapBeeMascotImage(asset: SnapBeeMascots.search, height: 56),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Fresh for a Healthier You!', style: SnapBeeText.h2.copyWith(color: const Color(0xFF1F7A3D), fontSize: 15)),
                      Text('Pure • Nutritious • From trusted stores', style: SnapBeeText.caption.copyWith(color: const Color(0xFF3C6B4B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44, color: SnapBeeColors.inkFaint),
              const SizedBox(height: 12),
              Text('Could not search products.', style: SnapBeeText.body, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SnapBeeOutlineButton(label: 'Retry', expand: false, onPressed: () => _search(_query)),
            ],
          ),
        ),
      );
    }
    if (_results.isEmpty) {
      return SnapBeeEmptyState(
        mascot: SnapBeeMascots.search,
        title: 'No results for "$_query"',
        message: 'Try a different product name or check nearby stores.',
      );
    }
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 4, SnapBeeSpacing.gutter, 8),
            child: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Showing results for  ', style: SnapBeeText.label),
              TextSpan(text: '"$_query"', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: SnapBeeColors.orange)),
            ])),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 0, SnapBeeSpacing.gutter, 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.66,
            ),
            itemCount: _results.length,
            itemBuilder: (context, index) => ProductCardWidget(
              product: _results[index],
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProductDetailsScreen(product: _results[index])),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
