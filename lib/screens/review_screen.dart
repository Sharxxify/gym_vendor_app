import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/review_provider.dart';
import '../services/review_service.dart';
import '../models/models.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  bool _isLoading = true;
  String? _errorMessage;
  ReviewSummary? _summary;
  List<Review> _reviews = [];
  double _averageRating = 0.0;
  int _totalReviews = 0;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _reviewService.getReviews();
      
      if (result['success'] == true && result['data'] != null) {
        final data = result['data'];
        
        // Parse summary
        _summary = _reviewService.parseSummary(data);
        if (_summary != null) {
          _averageRating = _summary!.averageRating;
          _totalReviews = _summary!.totalReviews;
        }
        
        // Parse reviews
        _reviews = _reviewService.parseReviews(data);
        
        debugPrint('✅ Loaded ${_reviews.length} reviews');
      } else {
        _errorMessage = result['message'] ?? 'Failed to load reviews';
        debugPrint('❌ Failed to load reviews: $_errorMessage');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ Error loading reviews: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildReviewsList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          Text(
            'Ratings & Reviews',
            style: AppTextStyles.labelLarge,
          ),
          AppSpacing.w12,
          Icon(Icons.star, color: AppColors.primaryGreen, size: 16),
          AppSpacing.w4,
          Text(
            _averageRating.toStringAsFixed(1),
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primaryGreen,
            ),
          ),
          AppSpacing.w4,
          Text(
            '(${_formatCount(_totalReviews)})',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.textSecondary,
            ),
            AppSpacing.h12,
            Text(
              'Failed to load reviews',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.h8,
            Text(
              _errorMessage!,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.h16,
            ElevatedButton(
              onPressed: _loadReviews,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    if (_reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            AppSpacing.h16,
            Text(
              'No reviews yet',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.h8,
            Text(
              'Reviews from your customers will appear here',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: AppColors.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingH,
          vertical: AppDimensions.paddingM,
        ),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          return _buildReviewCard(_reviews[index]);
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      padding: const EdgeInsets.all(AppDimensions.paddingL),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.inputBackground,
                backgroundImage: review.customerImage != null
                    ? NetworkImage(review.customerImage!)
                    : null,
                child: review.customerImage == null
                    ? Text(
                        review.customerName.isNotEmpty
                            ? review.customerName[0].toUpperCase()
                            : '?',
                        style: AppTextStyles.labelLarge,
                      )
                    : null,
              ),
              AppSpacing.w12,
              // Name and rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customerName,
                      style: AppTextStyles.labelMedium,
                    ),
                    AppSpacing.h4,
                    Row(
                      children: [
                        Text(
                          review.rating.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.w4,
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating.floor()
                                ? Icons.star
                                : (index < review.rating
                                    ? Icons.star_half
                                    : Icons.star_border),
                            color: AppColors.primaryGreen,
                            size: 14,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.h12,
          // Review text
          Text(
            review.comment,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          AppSpacing.h12,
          // Date
          Text(
            _formatDateTime(review.dateTime),
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          // Reply section
          if (review.reply != null) ...[
            AppSpacing.h12,
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Reply',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                  AppSpacing.h4,
                  Text(
                    review.reply!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Reply button (if no reply yet)
          if (review.reply == null) ...[
            AppSpacing.h8,
            GestureDetector(
              onTap: () => _showReplyDialog(review),
              child: Text(
                'Reply',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showReplyDialog(Review review) {
    final TextEditingController replyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Reply to ${review.customerName}',
          style: AppTextStyles.labelLarge,
        ),
        content: TextField(
          controller: replyController,
          maxLines: 4,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Write your reply...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              borderSide: const BorderSide(color: AppColors.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusS),
              borderSide: const BorderSide(color: AppColors.primaryGreen),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.isNotEmpty) {
                Navigator.pop(context);
                await _submitReply(review.id, replyController.text);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReply(String reviewId, String replyText) async {
    final result = await _reviewService.replyToReview(reviewId, replyText);
    
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply submitted successfully'),
          backgroundColor: AppColors.primaryGreen,
        ),
      );
      // Reload reviews to show the new reply
      _loadReviews();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit reply'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year.toString().substring(2);
    
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$day $month \'$year, $hour12:$minute $period';
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
