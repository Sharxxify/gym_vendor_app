import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/kyc_provider.dart';
import '../providers/business_provider.dart';
import 'business_details_screen.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;

  Future<void> _pickDocument(String documentType) async {
    try {
      // Show options dialog
      final result = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.cardBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Document', style: AppTextStyles.heading4),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.image, color: AppColors.primaryGreen),
                title: Text('From Gallery', style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(context, 'gallery'),
              ),
              ListTile(
                leading:
                    const Icon(Icons.camera_alt, color: AppColors.primaryGreen),
                title: Text('Take Photo', style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(context, 'camera'),
              ),
              ListTile(
                leading: const Icon(Icons.file_present,
                    color: AppColors.primaryGreen),
                title: Text('PDF Document', style: AppTextStyles.bodyMedium),
                onTap: () => Navigator.pop(context, 'pdf'),
              ),
            ],
          ),
        ),
      );

      if (result == null || !mounted) return;

      dynamic file; // Use dynamic to accept both File and XFile

      if (result == 'gallery') {
        final XFile? picked = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 80);
        if (picked != null) {
          if (kIsWeb) {
            // For web, use bytes instead of path
            file = picked;
          } else {
            // For mobile, use File
            file = File(picked.path);
          }
        }
      } else if (result == 'camera') {
        final XFile? picked = await _picker.pickImage(
            source: ImageSource.camera, imageQuality: 80);
        if (picked != null) {
          if (kIsWeb) {
            // For web, use bytes instead of path
            file = picked;
          } else {
            // For mobile, use File
            file = File(picked.path);
          }
        }
      } else if (result == 'pdf') {
        final FilePickerResult? picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
        if (picked != null) {
          if (kIsWeb) {
            // For web, use XFile from bytes
            final bytes = picked.files.single.bytes;
            if (bytes != null) {
              file = XFile.fromData(
                bytes,
                name: picked.files.single.name,
                mimeType: 'application/pdf',
              );
            }
          } else {
            // For mobile, use File
            if (picked.files.single.path != null) {
              file = File(picked.files.single.path!);
            }
          }
        }
      }

      if (file != null && mounted) {
        final kycProvider = context.read<KycProvider>();
        final businessProvider = context.read<BusinessProvider>();

        // Upload immediately to server
        final success =
            await businessProvider.uploadKycDocument(documentType, file);

        if (success && mounted) {
          // Update KYC provider for UI state
          switch (documentType) {
            case 'business_document':
              kycProvider.setBusinessDocument(file);
              kycProvider.setBusinessDocumentUrl(businessProvider.kycDocumentUrls['business_document']);
              break;
            case 'trade_license':
              kycProvider.setTradeLicense(file);
              kycProvider.setTradeLicenseUrl(businessProvider.kycDocumentUrls['trade_license']);
              break;
            case 'owner_id_proof':
              kycProvider.setOwnerIdProof(file);
              kycProvider.setOwnerIdProofUrl(businessProvider.kycDocumentUrls['owner_id_proof']);
              break;
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload $documentType'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error picking file: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _onSubmit() async {
    final kycProvider = context.read<KycProvider>();
    final businessProvider = context.read<BusinessProvider>();

    // Check if required documents are uploaded
    if (!kycProvider.canEnableButton()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both business document and trade license'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigate to Business Details screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BusinessDetailsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'KYC Verification',
        showBackButton: false, // First screen after login, no back
      ),
      body: Consumer2<KycProvider, BusinessProvider>(
        builder: (context, kycProvider, businessProvider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
                  child: Column(
                    children: [
                      AppSpacing.h16,
                      // Verification Icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Container(
                                width: 80,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB8E0F3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.verified_user,
                                  color: Color(0xFF5A9BBD),
                                  size: 30,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 8,
                              bottom: 8,
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.h24,
                      Text('Verify Business', style: AppTextStyles.heading3),
                      AppSpacing.h8,
                      Text(
                        'Upload your business documents for verification',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      AppSpacing.h32,

                      // Upload Section
                      CustomCard(
                        padding: const EdgeInsets.all(AppDimensions.paddingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Upload Business Docs',
                                style: AppTextStyles.labelLarge),
                            AppSpacing.h16,

                            // Business Document
                            _buildUploadTile(
                              title: 'Business Document',
                              subtitle: 'Registration certificate, GST, etc.',
                              file: kycProvider.businessDocument,
                              documentType: 'business_document',
                              onUpload: () =>
                                  _pickDocument('business_document'),
                              onRemove: () {
                                kycProvider.setBusinessDocument(null);
                                kycProvider.setBusinessDocumentUrl(null);
                                context
                                    .read<BusinessProvider>()
                                    .removeKycDocument('business_document');
                              },
                            ),
                            AppSpacing.h12,

                            // Trade License
                            _buildUploadTile(
                              title: 'Trade License',
                              subtitle: 'Business trade license',
                              file: kycProvider.tradeLicense,
                              documentType: 'trade_license',
                              onUpload: () => _pickDocument('trade_license'),
                              onRemove: () {
                                kycProvider.setTradeLicense(null);
                                kycProvider.setTradeLicenseUrl(null);
                                context
                                    .read<BusinessProvider>()
                                    .removeKycDocument('trade_license');
                              },
                            ),
                            AppSpacing.h12,

                            // Owner ID Proof (Optional)
                            _buildUploadTile(
                              title: 'Owner ID Proof (Optional)',
                              subtitle: 'Aadhar, PAN, Passport, etc.',
                              file: kycProvider.ownerIdProof,
                              documentType: 'owner_id_proof',
                              onUpload: () => _pickDocument('owner_id_proof'),
                              onRemove: () {
                                kycProvider.setOwnerIdProof(null);
                                kycProvider.setOwnerIdProofUrl(null);
                                context
                                    .read<BusinessProvider>()
                                    .removeKycDocument('owner_id_proof');
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Padding(
                padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
                child: Consumer<KycProvider>(
                  builder: (context, kycProvider, child) {
                    return PrimaryButton(
                      text: 'Continue to Business Details',
                      isEnabled: kycProvider.canEnableButton(),
                      onPressed: kycProvider.canEnableButton() ? _onSubmit : null,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required dynamic file,
    required String documentType,
    required VoidCallback onUpload,
    required VoidCallback onRemove,
  }) {
    final businessProvider = context.watch<BusinessProvider>();
    final isUploadingThis = businessProvider.isUploading &&
        businessProvider.uploadingPurpose == documentType;
    final uploadedUrl = businessProvider.kycDocumentUrls[documentType];
    final bool isUploaded = uploadedUrl != null;
    final String? fileName =
        isUploaded ? uploadedUrl.split('/').last : file?.path.split('/').last;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isUploaded
              ? AppColors.primaryGreen.withOpacity(0.5)
              : AppColors.inputBorder,
          width: AppDimensions.borderWidth,
        ),
      ),
      child: Row(
        children: [
          if (isUploadingThis) ...[
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryGreen,
              ),
            ),
            AppSpacing.w12,
          ] else if (isUploaded) ...[
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check,
                  color: AppColors.buttonText, size: 16),
            ),
            AppSpacing.w12,
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyMedium),
                AppSpacing.h4,
                Text(
                  isUploadingThis
                      ? 'Uploading...'
                      : (isUploaded ? fileName! : subtitle),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isUploaded
                        ? AppColors.primaryGreen
                        : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isUploaded) ...[
            IconButton(
              icon: const Icon(Icons.close,
                  size: 20, color: AppColors.textSecondary),
              onPressed: onRemove,
            ),
            InkWell(
              onTap: isUploadingThis ? null : onUpload,
              child: _buildUploadIcon(),
            ),
          ] else if (!isUploadingThis) ...[
            InkWell(
              onTap: onUpload,
              child: _buildUploadIcon(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadIcon() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primaryGreen, width: 1.5),
      ),
      child: const Icon(Icons.arrow_upward,
          color: AppColors.primaryGreen, size: 16),
    );
  }
}
