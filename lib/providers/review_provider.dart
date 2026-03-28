import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/review_service.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewService _reviewService = ReviewService();
  
  bool _isLoading = false;
  String? _errorMessage;
  List<Review> _reviews = [];
  ReviewSummary? _summary;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Review> get reviews => _reviews;
  ReviewSummary? get summary => _summary;

  /// Load all reviews
  Future<void> loadReviews() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _reviewService.getReviews();
      
      if (result['success'] == true && result['data'] != null) {
        _summary = _reviewService.parseSummary(result['data']);
        _reviews = _reviewService.parseReviews(result['data']);
      } else {
        _errorMessage = result['message'];
      }

      _isLoading = false;
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      _errorMessage = e.toString();
      _isLoading = false;
    }
    
    notifyListeners();
  }

  /// Reply to a review
  Future<bool> replyToReview(String reviewId, String replyText) async {
    try {
      final result = await _reviewService.replyToReview(reviewId, replyText);
      
      if (result['success'] == true) {
        // Update local review with reply
        final index = _reviews.indexWhere((r) => r.id == reviewId);
        if (index != -1) {
          _reviews[index] = Review(
            id: _reviews[index].id,
            customerName: _reviews[index].customerName,
            customerImage: _reviews[index].customerImage,
            rating: _reviews[index].rating,
            comment: _reviews[index].comment,
            dateTime: _reviews[index].dateTime,
            reply: replyText,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error replying to review: $e');
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
