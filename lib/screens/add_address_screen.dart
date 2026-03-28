import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/utils.dart';
import '../models/models.dart';
import '../providers/business_provider.dart';

class AddAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? locationData;

  const AddAddressScreen({
    super.key,
    this.locationData,
  });

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buildingNameController = TextEditingController();
  final _roadAreaController = TextEditingController();
  final _streetCityController = TextEditingController();

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFromLocationData();
    });
  }

  void _initializeFromLocationData() {
    if (widget.locationData != null) {
      // Pre-fill from location picker data
      final data = widget.locationData!;
      setState(() {
        _latitude = data['latitude'];
        _longitude = data['longitude'];
        _buildingNameController.text = data['placeName'] ?? '';
        _roadAreaController.text = data['street'] ?? data['locality'] ?? '';
        
        // Combine locality, city for street and city field
        final parts = <String>[];
        if (data['locality'] != null && data['locality'].toString().isNotEmpty) {
          parts.add(data['locality']);
        }
        if (data['city'] != null && data['city'].toString().isNotEmpty) {
          parts.add(data['city']);
        }
        _streetCityController.text = parts.join(', ');
      });
    } else {
      // Check if provider has existing data
      final provider = context.read<BusinessProvider>();
      if (provider.address != null) {
        _buildingNameController.text = provider.address!.buildingName;
        _roadAreaController.text = provider.address!.street;
        _streetCityController.text = provider.address!.locality;
        _latitude = provider.latitude;
        _longitude = provider.longitude;
      }
    }
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _roadAreaController.dispose();
    _streetCityController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (!_formKey.currentState!.validate()) return;

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates missing. Please go back and select location again.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final address = Address(
      buildingName: _buildingNameController.text,
      street: _roadAreaController.text,
      locality: _streetCityController.text,
      city: _streetCityController.text.split(', ').last,
      state: widget.locationData?['state'] ?? '',
      pincode: widget.locationData?['pincode'] ?? '',
    );

    final provider = context.read<BusinessProvider>();
    provider.setAddress(address);
    provider.setLocation(
      _latitude!,
      _longitude!,
      '${_buildingNameController.text}, ${_roadAreaController.text}, ${_streetCityController.text}',
    );

    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenHeight = ResponsiveHelper.screenHeight;
    final screenWidth = ResponsiveHelper.screenWidth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Add Address',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Form(
                key: _formKey,
                child: CustomCard(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Location Pin Icon (display only, already selected)
                      Center(
                        child: Container(
                          width: screenWidth * 0.15,
                          height: screenWidth * 0.15,
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            border: Border.all(
                              color: _latitude != null 
                                  ? AppColors.primaryGreen 
                                  : AppColors.inputBorder,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: _latitude != null 
                                ? AppColors.primaryGreen 
                                : AppColors.textPrimary,
                            size: screenWidth * 0.07,
                          ),
                        ),
                      ),
                      if (_latitude != null && _longitude != null) ...[
                        SizedBox(height: screenHeight * 0.01),
                        Center(
                          child: Text(
                            'Location selected ✓',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primaryGreen,
                              fontSize: ResponsiveHelper.sp(12),
                            ),
                          ),
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.025),
                      
                      // Building Name
                      CustomTextField(
                        label: 'Building Name',
                        hintText: 'Enter building name',
                        controller: _buildingNameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Building name is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Road/Area
                      CustomTextField(
                        label: 'Road/Area',
                        hintText: 'Enter road/area',
                        controller: _roadAreaController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Road/Area is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),
                      
                      // Street and City
                      CustomTextField(
                        label: 'Street and City',
                        hintText: 'Enter street and city',
                        controller: _streetCityController,
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Street and city is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Save Button
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: SafeArea(
              top: false,
              child: PrimaryButton(
                text: 'Save Address',
                onPressed: _saveAddress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
