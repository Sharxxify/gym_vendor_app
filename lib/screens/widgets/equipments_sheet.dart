import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';
import '../../providers/business_provider.dart';

class EquipmentsSheet extends StatefulWidget {
  final Equipment? equipment;
  final Function(Equipment) onSave;

  const EquipmentsSheet({
    super.key,
    this.equipment,
    required this.onSave,
  });

  @override
  State<EquipmentsSheet> createState() => _EquipmentsSheetState();
}

class _EquipmentsSheetState extends State<EquipmentsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  List<String> _imageUrls = []; // S3 URLs
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.equipment != null) {
      _nameController.text = widget.equipment!.name;
      _imageUrls = List.from(widget.equipment!.images);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 80);
      if (files.isNotEmpty && mounted) {
        setState(() => _isUploading = true);
        
        final provider = context.read<BusinessProvider>();
        
        for (final xFile in files) {
          // Upload to server immediately
          final viewUrl = await provider.uploadEquipmentImage(File(xFile.path));
          
          if (viewUrl != null && mounted) {
            setState(() {
              _imageUrls.add(viewUrl);
            });
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload ${xFile.name}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
        
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final equipment = Equipment(
        id: widget.equipment?.id,
        name: _nameController.text,
        images: _imageUrls, // S3 URLs
      );
      widget.onSave(equipment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Text('Equipments', style: AppTextStyles.heading4),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(color: AppColors.inputBorder),
                AppSpacing.h16,
                // Equipment Name
                CustomTextField(
                  label: 'Equipments Name',
                  hintText: 'Enter Equipments Name',
                  controller: _nameController,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                AppSpacing.h16,
                // Display Image with upload indicator
                Stack(
                  children: [
                    ImageUploadTile(
                      title: 'Display Image',
                      uploadedFiles: _imageUrls.map((url) => url.split('/').last).toList(),
                      onUploadTap: _isUploading ? null : _pickImages,
                      onRemoveTap: (i) => setState(() => _imageUrls.removeAt(i)),
                    ),
                    if (_isUploading)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.background.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: AppColors.primaryGreen),
                                SizedBox(height: 8),
                                Text('Uploading...', style: TextStyle(color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                AppSpacing.h24,
                // Save Button
                PrimaryButton(
                  text: 'Add Equipments',
                  onPressed: _save,
                  isEnabled: !_isUploading,
                ),
                AppSpacing.h16,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
