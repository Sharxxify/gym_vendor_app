import 'package:flutter/material.dart';
import '../constants/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final List<Widget>? actions;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final double? elevation;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.actions,
    this.onBackPressed,
    this.backgroundColor,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor ?? AppColors.background,
      elevation: elevation ?? 0,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              onPressed: onBackPressed ?? () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
              ),
            )
          : null,
      title: titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.appBarTitle,
                )
              : null),
      centerTitle: false,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppDimensions.appBarHeight);
}

class HomeAppBar extends StatelessWidget {
  final String businessName;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;

  const HomeAppBar({
    super.key,
    required this.businessName,
    this.imageUrl,
    required this.rating,
    required this.reviewCount,
    this.onNotificationTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.screenPaddingH,
          vertical: AppDimensions.paddingM,
        ),
        child: Row(
          children: [
            // Business Image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                color: AppColors.cardBackground,
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            AppSpacing.w12,
            // Business Name & Rating
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    businessName,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AppSpacing.h4,
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: AppColors.primaryGreen,
                        size: 14,
                      ),
                      AppSpacing.w4,
                      Text(
                        '$rating',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryGreen,
                        ),
                      ),
                      AppSpacing.w4,
                      Text(
                        '(${_formatCount(reviewCount)})',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Notification Icon
            _buildIconButton(
              icon: Icons.notifications_outlined,
              onTap: onNotificationTap,
            ),
            AppSpacing.w8,
            // Menu Icon
            _buildIconButton(
              icon: Icons.menu,
              onTap: onMenuTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.inputBackground,
      child: const Icon(
        Icons.fitness_center,
        color: AppColors.textHint,
        size: 24,
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        border: Border.all(
          color: AppColors.inputBorder,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          child: Icon(
            icon,
            color: AppColors.textPrimary,
            size: AppDimensions.iconS,
          ),
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return count.toString();
  }
}
