
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/utils.dart';
import '../providers/business_provider.dart';
import 'location_picker_screen.dart';
import 'services_screen.dart';

class BusinessDetailsScreen extends StatefulWidget {
  const BusinessDetailsScreen({super.key});

  @override
  State<BusinessDetailsScreen> createState() => _BusinessDetailsScreenState();
}

class _BusinessDetailsScreenState extends State<BusinessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _aboutUsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BusinessProvider>();
      _businessNameController.text = provider.businessName;
      _emailController.text = provider.email;
      _aboutUsController.text = provider.aboutUs;
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _aboutUsController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> files = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (files.isNotEmpty && mounted) {
        final provider = context.read<BusinessProvider>();

        for (var file in files) {
          // Upload immediately to server
          final success = await provider.uploadDisplayImage(file);

          if (!success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload ${file.name}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? file = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (file != null && mounted) {
        final provider = context.read<BusinessProvider>();
        final success = await provider.uploadDisplayVideo(file);

        if (!success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload video'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking video: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToLocationPicker() async {
    // Navigate directly to location picker
    // Location picker will then navigate to add address screen
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(navigateToAddAddress: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {});
    }
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BusinessProvider>();
    provider.setBusinessName(_businessNameController.text);
    provider.setEmail(_emailController.text);
    provider.setAboutUs(_aboutUsController.text);

    if (provider.latitude == null || provider.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add business address'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!provider.hasDisplayImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one display image'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Navigate to ServicesScreen screen
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ServicesScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenHeight = ResponsiveHelper.screenHeight;
    final screenWidth = ResponsiveHelper.screenWidth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(
        title: 'Business',
        showBackButton: true,
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Gym Icon Placeholder
                        Container(
                          width: screenWidth * 0.25,
                          height: screenHeight * 0.1,
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius:
                                BorderRadius.circular(screenWidth * 0.03),
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: AppColors.primaryGreen,
                            size: screenWidth * 0.1,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Text(
                          'Business Details',
                          style: AppTextStyles.heading3.copyWith(
                            fontSize: ResponsiveHelper.sp(20),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.025),
                        // Form Card
                        CustomCard(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Business Name
                              CustomTextField(
                                label: 'Business Name',
                                hintText: 'Enter Business Name',
                                controller: _businessNameController,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Business name is required';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              // Email Address
                              CustomTextField(
                                label: 'Email Address',
                                hintText: 'Enter Email Address',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Email address is required';
                                  }
                                  final emailRegex = RegExp(
                                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              // Display Image with upload indicator
                              Stack(
                                children: [
                                  ImageUploadTile(
                                    title: 'Display Image',
                                    uploadedFiles: provider.displayImageUrls
                                        .map((url) => url.split('/').last)
                                        .toList(),
                                    onUploadTap: provider.isUploading
                                        ? null
                                        : _pickImages,
                                    onViewTap: (index) {
                                      // View image
                                    },
                                    onRemoveTap: (index) {
                                      provider.removeDisplayImage(index);
                                    },
                                    hint1:
                                        'You can upload multiple images in one go',
                                    hint2:
                                        'These images will appear in your profile card',
                                  ),
                                  if (provider.isUploading &&
                                      provider.uploadingPurpose ==
                                          'display_image')
                                    Positioned.fill(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.background
                                              .withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(
                                              AppDimensions.radiusM),
                                        ),
                                        child: const Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(
                                                  color:
                                                      AppColors.primaryGreen),
                                              SizedBox(height: 8),
                                              Text('Uploading...',
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .textSecondary)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: screenHeight * 0.02),
                              // Video Upload (Bug 2 Fix)
                              Text('Display Video (Max 30s)',
                                  style: AppTextStyles.inputLabel),
                              SizedBox(height: screenHeight * 0.01),
                              InkWell(
                                onTap: provider.isUploading ? null : _pickVideo,
                                child: Container(
                                  padding: EdgeInsets.all(screenWidth * 0.04),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                                    border: Border.all(color: AppColors.inputBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          provider.displayVideoUrl != null
                                              ? provider.displayVideoUrl!.split('/').last
                                              : 'Upload 30s Intro Video',
                                          style: provider.displayVideoUrl != null
                                              ? AppTextStyles.bodySmall
                                              : AppTextStyles.inputHint,
                                        ),
                                      ),
                                      if (provider.displayVideoUrl != null)
                                        IconButton(
                                          icon: const Icon(Icons.close, color: AppColors.error),
                                          onPressed: () => provider.removeDisplayVideo(),
                                        )
                                      else if (provider.isUploading && provider.uploadingPurpose == 'display_video')
                                        const SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGreen),
                                          ),
                                        )
                                      else
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
                              SizedBox(height: screenHeight * 0.02),
                              // Business Address
                              Text(
                                'Business Address',
                                style: AppTextStyles.inputLabel.copyWith(
                                  fontSize: ResponsiveHelper.sp(14),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              if (provider.formattedAddress != null &&
                                  provider.formattedAddress!.isNotEmpty)
                                _buildAddressCard(
                                    provider, screenWidth, screenHeight)
                              else
                                _buildAddAddressButton(
                                    screenWidth, screenHeight),
                              SizedBox(height: screenHeight * 0.02),
                              // About Us
                              CustomTextField(
                                label: 'About Us',
                                hintText: 'Enter about us',
                                controller: _aboutUsController,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Continue Button
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: SafeArea(
                  top: false,
                  child: PrimaryButton(
                    text: 'Continue',
                    isLoading: provider.isLoading,
                    isEnabled: _businessNameController.text.isNotEmpty,
                    onPressed: _onContinue,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddAddressButton(double screenWidth, double screenHeight) {
    return InkWell(
      onTap: _navigateToLocationPicker,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: AppColors.inputBorder,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              color: AppColors.textPrimary,
              size: screenWidth * 0.05,
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'Add Address',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: ResponsiveHelper.sp(14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(
      BusinessProvider provider, double screenWidth, double screenHeight) {
    return InkWell(
      onTap: _navigateToLocationPicker,
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: AppColors.inputBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: screenWidth * 0.1,
              height: screenWidth * 0.1,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: AppColors.textPrimary,
                size: screenWidth * 0.05,
              ),
            ),
            SizedBox(width: screenWidth * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.address?.buildingName ?? 'Selected Location',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontSize: ResponsiveHelper.sp(14),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    provider.formattedAddress ?? '',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveHelper.sp(12),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textPrimary,
              size: screenWidth * 0.06,
            ),
          ],
        ),
      ),
    );
  }
}
