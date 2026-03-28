import 'package:flutter/material.dart';
import '../constants/constants.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final bool isSelected;
  final double? borderRadius;
  final Color? backgroundColor;
  final bool showBorder;
  final bool showGradient;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.isSelected = false,
    this.borderRadius,
    this.backgroundColor,
    this.showBorder = true,
    this.showGradient = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: showGradient
            ? (isSelected
                ? AppColors.selectedCardGradient
                : AppColors.cardGradient)
            : null,
        color: !showGradient
            ? (backgroundColor ?? AppColors.cardBackground)
            : null,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusM,
        ),
        border: showBorder
            ? Border.all(
                color: isSelected
                    ? AppColors.primaryGreen
                    : AppColors.inputBorder,
                width: AppDimensions.borderWidth,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppDimensions.radiusM,
          ),
          child: Padding(
            padding: padding ??
                const EdgeInsets.all(AppDimensions.paddingL),
            child: child,
          ),
        ),
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? percentage;
  final bool isPositive;
  final bool isSelected;
  final IconData? icon;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.percentage,
    this.isPositive = true,
    this.isSelected = false,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CustomCard(
        onTap: onTap,
        isSelected: isSelected,
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: AppColors.textSecondary,
                    size: AppDimensions.iconXS,
                  ),
                  AppSpacing.w4,
                ],
                Text(
                  title,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            AppSpacing.h8,
            Text(
              value,
              style: AppTextStyles.heading3,
            ),
            if (percentage != null) ...[
              AppSpacing.h4,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingS,
                  vertical: AppDimensions.paddingXS,
                ),
                decoration: BoxDecoration(
                  color: isPositive
                      ? AppColors.primaryGreen.withOpacity(0.2)
                      : AppColors.primaryRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
                ),
                child: Text(
                  percentage!,
                  style: isPositive
                      ? AppTextStyles.percentage
                      : AppTextStyles.percentageNegative,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExpandableCard extends StatelessWidget {
  final String title;
  final bool isExpanded;
  final VoidCallback onTap;
  final Widget? child;
  final Widget? trailing;

  const ExpandableCard({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onTap,
    this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge,
                  ),
                  Row(
                    children: [
                      if (trailing != null) trailing!,
                      AppSpacing.w8,
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && child != null)
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: child,
            ),
        ],
      ),
    );
  }
}
