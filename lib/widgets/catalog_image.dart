import 'package:flutter/material.dart';

/// Renders a product/category image regardless of source: a real
/// vendor/admin-uploaded Supabase Storage URL (network), one of the
/// app's own bundled placeholder assets (asset path), or nothing at all
/// (falls back to a neutral icon) — a vendor hasn't necessarily uploaded
/// an image yet, and that must never be a hard error.
class CatalogImage extends StatelessWidget {
  final String? source;
  final BoxFit fit;
  final IconData placeholderIcon;

  const CatalogImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final value = source?.trim();
    if (value == null || value.isEmpty) {
      return _placeholder(context);
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return Image.network(
        value,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(context),
      );
    }
    return Image.asset(
      value,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _placeholder(context),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      alignment: Alignment.center,
      child: Icon(placeholderIcon, color: Colors.grey.shade400),
    );
  }
}
