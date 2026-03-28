import 'package:flutter/foundation.dart';
import '../core/network/api_client.dart';
import '../models/models.dart';

class ReviewService {
  /// Get all reviews for the gym
  /// GET /api/v1/gym/reviews
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> getReviews() async {
    debugPrint('⭐ Fetching reviews...');

    final response = await ApiClient.get('/api/v1/gym/reviews');

    debugPrint('📥 Get Reviews Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'data': response.data,
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to fetch reviews',
      };
    }
  }

  /// Reply to a review
  /// POST /api/v1/gym/reviews/{review_id}/reply
  /// Auth: Authorization: Bearer <jwt token>
  Future<Map<String, dynamic>> replyToReview(
      String reviewId, String replyText) async {
    debugPrint('💬 Replying to review: $reviewId');

    final response = await ApiClient.post(
      '/api/v1/gym/reviews/$reviewId/reply',
      body: {'text': replyText},
    );

    debugPrint('📥 Reply to Review Response: ${response.data}');

    if (response.success && response.data != null) {
      return {
        'success': true,
        'message': response.data!['message'] ?? 'Reply added successfully',
        'reply': response.data!['reply'],
      };
    } else {
      return {
        'success': false,
        'message': response.message ?? 'Failed to add reply',
      };
    }
  }

  /// Parse reviews from API response
  List<Review> parseReviews(Map<String, dynamic> data) {
    if (data['reviews'] == null) return [];

    return (data['reviews'] as List)
        .map((r) => Review(
              id: r['review_id'] ?? '',
              customerName: r['reviewer_name'] ?? '',
              customerImage: r['reviewer_image_url'],
              rating: (r['rating'] ?? 0).toDouble(),
              comment: r['review_text'] ?? '',
              dateTime:
                  DateTime.tryParse(r['created_at'] ?? '') ?? DateTime.now(),
              reply: r['reply']?['text'],
            ))
        .toList();
  }

  /// Parse review summary from API response
  ReviewSummary? parseSummary(Map<String, dynamic> data) {
    if (data['summary'] == null) return null;

    final summary = data['summary'];
    final distribution = summary['rating_distribution'] ?? {};

    return ReviewSummary(
      averageRating: (summary['average_rating'] ?? 0).toDouble(),
      totalReviews: summary['total_reviews'] ?? 0,
      fiveStarCount: distribution['5'] ?? 0,
      fourStarCount: distribution['4'] ?? 0,
      threeStarCount: distribution['3'] ?? 0,
      twoStarCount: distribution['2'] ?? 0,
      oneStarCount: distribution['1'] ?? 0,
    );
  }
}

/// Review summary model
class ReviewSummary {
  final double averageRating;
  final int totalReviews;
  final int fiveStarCount;
  final int fourStarCount;
  final int threeStarCount;
  final int twoStarCount;
  final int oneStarCount;

  ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.fiveStarCount,
    required this.fourStarCount,
    required this.threeStarCount,
    required this.twoStarCount,
    required this.oneStarCount,
  });

  int getCount(int stars) {
    switch (stars) {
      case 5:
        return fiveStarCount;
      case 4:
        return fourStarCount;
      case 3:
        return threeStarCount;
      case 2:
        return twoStarCount;
      case 1:
        return oneStarCount;
      default:
        return 0;
    }
  }

  double getPercentage(int stars) {
    if (totalReviews == 0) return 0;
    return (getCount(stars) / totalReviews) * 100;
  }
}
