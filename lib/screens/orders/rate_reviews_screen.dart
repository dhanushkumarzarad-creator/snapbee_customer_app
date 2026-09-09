import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/design/snapbee_design.dart';
import '../../data/repositories/order_review_repository.dart';

/// Rate & Review (reference 30). Submit persists a real store review via the
/// `submit_de_order_review` RPC (snapbee_admin/supabase/
/// daily_essentials_order_reviews.sql) — one review per delivered order,
/// enforced server-side. If a review already exists it is loaded and the
/// screen shows a read-only "you rated this order" state.
class RateReviewsScreen extends StatefulWidget {
  final String orderId;
  final String storeName;
  final List<String> productNames;

  const RateReviewsScreen({
    super.key,
    required this.orderId,
    this.storeName = 'the store',
    this.productNames = const [],
  });

  @override
  State<RateReviewsScreen> createState() => _RateReviewsScreenState();
}

class _RateReviewsScreenState extends State<RateReviewsScreen> {
  final _repo = OrderReviewRepository(Supabase.instance.client);

  int _storeRating = 0;
  final Set<String> _tags = {};
  final _reviewController = TextEditingController();
  late final Map<String, int> _productRatings = {
    for (final n in widget.productNames) n: 0,
  };

  bool _loading = true;
  bool _submitting = false;
  OrderReview? _existing;

  static const _tagOptions = ['Great Quality', 'On Time Delivery', 'Good Packaging', 'Friendly Service', 'Value for Money'];

  static const _ratingWords = ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final review = await _repo.fetchMyOrderReview(widget.orderId);
    if (!mounted) return;
    setState(() {
      _existing = review;
      if (review != null) {
        _storeRating = review.rating;
        _tags.addAll(review.tags);
        if ((review.reviewText ?? '').isNotEmpty) _reviewController.text = review.reviewText!;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_existing != null) {
      Navigator.of(context).maybePop();
      return;
    }
    if (_storeRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap a star to rate the store first.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repo.submitOrderReview(
        orderId: widget.orderId,
        rating: _storeRating,
        reviewText: _reviewController.text.trim().isEmpty ? null : _reviewController.text.trim(),
        tags: _tags.toList(),
        productRatings: {
          for (final e in _productRatings.entries)
            if (e.value > 0) e.key: e.value,
        },
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.favorite_rounded, color: SnapBeeColors.danger, size: 34),
          title: const Text('Thanks for your feedback!'),
          content: Text('Your $_storeRating-star review for ${widget.storeName} has been submitted.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).maybePop();
    } on OrderReviewException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SnapBeeColors.scaffold,
      appBar: SnapBeeAppBar(
        subtitle: 'Daily Essentials',
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SnapBeePillButton(label: 'Skip', onTap: () => Navigator.of(context).maybePop()),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            if (_existing != null)
              SnapBeeInfoBanner(
                icon: Icons.check_circle_rounded,
                color: SnapBeeColors.success,
                fill: SnapBeeColors.successFill,
                text: 'You reviewed this order on '
                    '${_existing!.createdAt.day.toString().padLeft(2, '0')}/'
                    '${_existing!.createdAt.month.toString().padLeft(2, '0')}/'
                    '${_existing!.createdAt.year}. Thanks for your feedback!',
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(SnapBeeSpacing.gutter, 4, SnapBeeSpacing.gutter, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rate & Review', style: SnapBeeText.h1),
                        const SizedBox(height: 2),
                        Text('Your feedback helps us serve you better', style: SnapBeeText.body),
                      ],
                    ),
                  ),
                  const SnapBeeMascotImage(asset: SnapBeeMascots.club, height: 66),
                ],
              ),
            ),

            SnapBeeCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: SnapBeeColors.orangeTint, shape: BoxShape.circle),
                    child: const Icon(Icons.receipt_long_rounded, color: SnapBeeColors.orange, size: 19),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #${_short(widget.orderId)}', style: SnapBeeText.title),
                        Text(widget.storeName, style: SnapBeeText.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: SnapBeeColors.successFill, borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill)),
                    child: const Text('Delivered', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF1F7A3D))),
                  ),
                ],
              ),
            ),

            // ---- Store rating -----------------------------------------
            SnapBeeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Rate the Store', style: SnapBeeText.h2),
                  const SizedBox(height: 4),
                  Text('How was your overall experience with ${widget.storeName}?', style: SnapBeeText.caption),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 1; i <= 5; i++)
                        GestureDetector(
                          onTap: () => setState(() => _storeRating = i),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Icon(
                              i <= _storeRating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: SnapBeeColors.star,
                              size: 34,
                            ),
                          ),
                        ),
                      if (_storeRating > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: SnapBeeColors.orangeTint, borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill)),
                          child: Text(_ratingWords[_storeRating], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SnapBeeColors.orangeDark)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in _tagOptions)
                        GestureDetector(
                          onTap: () => setState(() => _tags.contains(t) ? _tags.remove(t) : _tags.add(t)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _tags.contains(t) ? SnapBeeColors.orangeTint : SnapBeeColors.surface,
                              borderRadius: BorderRadius.circular(SnapBeeSpacing.rPill),
                              border: Border.all(color: _tags.contains(t) ? SnapBeeColors.orange : SnapBeeColors.hairline),
                            ),
                            child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _tags.contains(t) ? SnapBeeColors.orangeDark : SnapBeeColors.inkSoft)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Share more about your experience (optional)',
                      hintStyle: const TextStyle(color: SnapBeeColors.inkFaint, fontSize: 13),
                      filled: true,
                      fillColor: SnapBeeColors.chipFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(SnapBeeSpacing.rTile), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),

            // ---- Product ratings ------------------------------------
            if (widget.productNames.isNotEmpty)
              SnapBeeCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rate the Products', style: SnapBeeText.h2),
                    const SizedBox(height: 4),
                    Text('Tell us about the items you ordered', style: SnapBeeText.caption),
                    const SizedBox(height: 8),
                    for (final n in widget.productNames)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(child: Text(n, style: SnapBeeText.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                            for (var i = 1; i <= 5; i++)
                              GestureDetector(
                                onTap: () => setState(() => _productRatings[n] = i),
                                child: Icon(
                                  i <= (_productRatings[n] ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
                                  color: SnapBeeColors.star,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
            Padding(
              padding: SnapBeeSpacing.screenH,
              child: SnapBeePrimaryButton(
                label: _existing != null
                    ? 'Done'
                    : (_submitting ? 'Submitting…' : 'Submit Review'),
                onPressed: _submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _short(String id) => id.length > 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();
}
