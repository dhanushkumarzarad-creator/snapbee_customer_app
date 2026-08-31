/// One `service_reviews` row surfaced on the service detail page. Only
/// reachable once `service_reviews_public_select` RLS
/// (supabase/service_reviews_public_read.sql) is applied — until then
/// `ServicesCatalogRepository.fetchServiceReviews` returns an empty list
/// and the detail screen shows only the weighted provider-rating average.
class ServiceReview {
  final int rating;
  final String? reviewText;
  final String? reviewerName;
  final DateTime createdAt;

  const ServiceReview({
    required this.rating,
    required this.reviewText,
    required this.reviewerName,
    required this.createdAt,
  });

  factory ServiceReview.fromJson(Map<String, dynamic> json) {
    final customer = json['customers'] as Map<String, dynamic>?;
    final name = customer?['name'] as String?;
    return ServiceReview(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      reviewText: (json['review_text'] as String?)?.trim().isEmpty ?? true
          ? null
          : (json['review_text'] as String).trim(),
      reviewerName: (name == null || name.trim().isEmpty) ? null : name.trim().split(' ').first,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
