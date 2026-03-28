import 'package:flutter/material.dart';
import '../constants/constants.dart';

class UploadTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isUploaded;
  final VoidCallback? onUploadTap;
  final VoidCallback? onViewTap;
  final VoidCallback? onRemoveTap;

  const UploadTile({
    super.key,
    required this.title,
    this.subtitle,
    this.isUploaded = false,
    this.onUploadTap,
    this.onViewTap,
    this.onRemoveTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.inputBorder,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Row(
        children: [
          if (isUploaded) ...[
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: AppColors.buttonText,
                size: 16,
              ),
            ),
            AppSpacing.w12,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium,
                ),
                if (subtitle != null) ...[
                  AppSpacing.h4,
                  Text(
                    subtitle!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isUploaded) ...[
            TextButton(
              onPressed: onViewTap,
              child: Text(
                'View',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
            TextButton(
              onPressed: onRemoveTap,
              child: Text(
                'Remove',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ] else ...[
            if (subtitle == null)
              Text(
                'Re-upload',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.primaryGreen,
                ),
              ),
            AppSpacing.w8,
            InkWell(
              onTap: onUploadTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryGreen,
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_upward,
                  color: AppColors.primaryGreen,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ImageUploadTile extends StatelessWidget {
  final String title;
  final List<String> uploadedFiles;
  final VoidCallback? onUploadTap;
  final Function(int)? onViewTap;
  final Function(int)? onRemoveTap;
  final String? hint1;
  final String? hint2;

  const ImageUploadTile({
    super.key,
    required this.title,
    this.uploadedFiles = const [],
    this.onUploadTap,
    this.onViewTap,
    this.onRemoveTap,
    this.hint1,
    this.hint2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.inputLabel,
        ),
        AppSpacing.h8,
        InkWell(
          onTap: onUploadTap,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.inputBorder,
                width: AppDimensions.borderWidth,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    uploadedFiles.isEmpty
                        ? 'Upload Display Image(s)'
                        : 'Upload Display Image(s)',
                    style: AppTextStyles.inputHint,
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryGreen,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (uploadedFiles.isNotEmpty) ...[
          AppSpacing.h8,
          ...uploadedFiles.asMap().entries.map((entry) {
            final index = entry.key;
            final fileName = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.paddingS),
              child: Row(
                children: [
                  const Icon(
                    Icons.check,
                    color: AppColors.primaryGreen,
                    size: 16,
                  ),
                  AppSpacing.w8,
                  Expanded(
                    child: Text(
                      fileName,
                      style: AppTextStyles.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onViewTap?.call(index),
                    child: Text(
                      'View',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onRemoveTap?.call(index),
                    child: Text(
                      'Remove',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        if (hint1 != null || hint2 != null) ...[
          AppSpacing.h8,
          if (hint1 != null)
            Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.w8,
                Text(
                  hint1!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          if (hint2 != null) ...[
            AppSpacing.h4,
            Row(
              children: [
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                AppSpacing.w8,
                Text(
                  hint2!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
