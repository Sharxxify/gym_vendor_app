import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';
import '../../providers/business_provider.dart';

class AddServiceSheet extends StatefulWidget {
  final Service? service;
  final Function(Service) onSave;

  const AddServiceSheet({
    super.key,
    this.service,
    required this.onSave,
  });

  @override
  State<AddServiceSheet> createState() => _AddServiceSheetState();
}

class _AddServiceSheetState extends State<AddServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _feeController = TextEditingController();
  String _feeType = 'hr';
  List<String> _imageUrls = []; // S3 URLs
  List<TimeSlot> _timeSlots = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (widget.service != null) {
      _nameController.text = widget.service!.name;
      _feeController.text = widget.service!.fee.toInt().toString();
      _feeType = widget.service!.feeType ?? 'hr';
      _imageUrls = List.from(widget.service!.images);
      _timeSlots = List.from(widget.service!.timeSlots);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
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
          final viewUrl = await provider.uploadServiceImage(File(xFile.path));
          
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
      final service = Service(
        id: widget.service?.id,
        name: _nameController.text,
        price: double.tryParse(_feeController.text) ?? 0,
        priceUnit: _feeType,
        images: _imageUrls, // S3 URLs
        timeSlots: _timeSlots,
      );
      widget.onSave(service);
    }
  }

  Future<void> _showTimePicker(String currentTime, Function(String) onSelect) async {
    final parts = currentTime.split(':');
    int hour = int.tryParse(parts[0]) ?? 9;
    final isPM = currentTime.toLowerCase().contains('pm');
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    final int minute = int.tryParse(parts.length > 1 ? parts[1].split(' ')[0] : '0') ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
    );

    if (picked != null) {
      final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final m = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      onSelect('$h:$m $period');
    }
  }

  Widget _buildTimeButton(String time, Function(String) onSelect) {
    return InkWell(
      onTap: () => _showTimePicker(time.isEmpty ? '06:00 AM' : time, onSelect),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.inputBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primaryOlive, width: 1),
        ),
        child: Text(
          time.isEmpty ? 'Select' : time,
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontSize: 12),
        ),
      ),
    );
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
                    Text('Add Service', style: AppTextStyles.heading4),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Divider(color: AppColors.inputBorder),
                AppSpacing.h16,
                // Service Name
                CustomTextField(
                  label: 'Service',
                  hintText: 'Enter service name',
                  controller: _nameController,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                AppSpacing.h16,
                // Fee
                Text('Fee', style: AppTextStyles.inputLabel),
                AppSpacing.h8,
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _feeController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        style: AppTextStyles.inputText,
                        decoration: InputDecoration(
                          hintText: 'Enter Fee',
                          prefixText: '₹ ',
                          prefixStyle: AppTextStyles.inputText,
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusM),
                            borderSide:
                                const BorderSide(color: AppColors.inputBorder),
                          ),
                        ),
                        validator: (v) =>
                            v?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ),
                    AppSpacing.w12,
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusM),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _feeType,
                            isExpanded: true,
                            dropdownColor: AppColors.cardBackground,
                            items: const [
                              DropdownMenuItem(
                                  value: 'hr', child: Text('/ hr')),
                              DropdownMenuItem(
                                  value: 'session', child: Text('/ session')),
                              DropdownMenuItem(
                                  value: 'day', child: Text('/ day')),
                            ],
                            onChanged: (v) => setState(() => _feeType = v!),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                AppSpacing.h16,
                // Time Slots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Time Slots', style: AppTextStyles.inputLabel),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _timeSlots.add(TimeSlot(label: 'Morning', from: '06:00 AM', to: '12:00 PM'));
                        });
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Slot'),
                    ),
                  ],
                ),
                if (_timeSlots.isNotEmpty)
                  Column(
                    children: List.generate(_timeSlots.length, (index) {
                      final slot = _timeSlots[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: slot.label,
                                style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                                decoration: const InputDecoration(isDense: true),
                                onChanged: (val) {
                                  _timeSlots[index] = TimeSlot(label: val, from: slot.from, to: slot.to);
                                },
                              ),
                            ),
                            AppSpacing.w8,
                            _buildTimeButton(slot.from, (time) {
                              setState(() {
                                _timeSlots[index] = TimeSlot(label: slot.label, from: time, to: slot.to);
                              });
                            }),
                            AppSpacing.w8,
                            _buildTimeButton(slot.to, (time) {
                              setState(() {
                                _timeSlots[index] = TimeSlot(label: slot.label, from: slot.from, to: time);
                              });
                            }),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                              onPressed: () {
                                setState(() {
                                  _timeSlots.removeAt(index);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                AppSpacing.h24,
                // Save Button
                PrimaryButton(
                  text: 'Add Service',
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
