import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/utils.dart';
import '../models/models.dart';
import '../providers/business_provider.dart';
import 'home_screen.dart';
import 'widgets/business_hours_section.dart';
import 'widgets/add_service_sheet.dart';
import 'widgets/facilities_sheet.dart';
import 'widgets/equipments_sheet.dart';
import 'widgets/membership_sheet.dart';

enum ExpandedSection {
  none,
  businessHours,
  services,
  facilities,
  equipments,
  membership
}

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  ExpandedSection _expandedSection = ExpandedSection.businessHours;
  bool _isSubmitting = false;

  void _toggleSection(ExpandedSection section) {
    setState(() {
      _expandedSection =
          _expandedSection == section ? ExpandedSection.none : section;
    });
  }

  Future<void> _onSave() async {
    final businessProvider = context.read<BusinessProvider>();

    // Validate business hours
    if (!businessProvider.hasBusinessHours) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set business hours'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create gym profile with all data (including services)
      final success = await businessProvider.createGymProfile();

      if (success && mounted) {
        // Navigate to home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                businessProvider.errorMessage ?? 'Failed to create profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }

    setState(() => _isSubmitting = false);
  }

  void _showAddServiceSheet(BuildContext context, BusinessProvider provider,
      {int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveHelper.screenWidth * 0.06)),
      ),
      builder: (context) => AddServiceSheet(
        service: editIndex != null ? provider.services[editIndex] : null,
        onSave: (service) {
          if (editIndex != null) {
            provider.updateService(editIndex, service);
          } else {
            provider.addService(service);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showFacilitiesSheet(BuildContext context, BusinessProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveHelper.screenWidth * 0.06)),
      ),
      builder: (context) => FacilitiesSheet(
        selectedFacilities: provider.facilities,
        onSave: (facilities) {
          provider.setFacilities(facilities);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showEquipmentsSheet(BuildContext context, BusinessProvider provider,
      {int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveHelper.screenWidth * 0.06)),
      ),
      builder: (context) => EquipmentsSheet(
        equipment: editIndex != null ? provider.equipments[editIndex] : null,
        onSave: (equipment) {
          if (editIndex != null) {
            provider.removeEquipment(editIndex);
          }
          provider.addEquipment(equipment);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showMembershipSheet(BuildContext context, BusinessProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(ResponsiveHelper.screenWidth * 0.06)),
      ),
      builder: (context) => MembershipSheet(
        membershipFee: provider.membershipFee,
        onSave: (fee) {
          provider.setMembershipFee(fee);
          Navigator.pop(context);
        },
      ),
    );
  }

  // Fixed back button navigation
  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenHeight = ResponsiveHelper.screenHeight;
    final screenWidth = ResponsiveHelper.screenWidth;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Services',
        onBackPressed: _handleBack,
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: Column(
                    children: [
                      // Business Hours Section
                      _buildSection(
                        ExpandedSection.businessHours,
                        'Business Hours',
                        screenWidth,
                        screenHeight,
                        child: BusinessHoursSection(
                          businessHours: provider.businessHours,
                          onUpdate: provider.updateDayHours,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      // Services Section
                      _buildSection(
                        ExpandedSection.services,
                        'Services',
                        screenWidth,
                        screenHeight,
                        trailing: _addButton(
                            () => _showAddServiceSheet(context, provider),
                            screenWidth),
                        child: _buildServicesList(provider, screenWidth),
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      // Facilities Section
                      _buildSection(
                        ExpandedSection.facilities,
                        'Facilities',
                        screenWidth,
                        screenHeight,
                        trailing: _addButton(
                            () => _showFacilitiesSheet(context, provider),
                            screenWidth),
                        child: _buildFacilitiesList(provider, screenWidth),
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      // Equipments Section
                      _buildSection(
                        ExpandedSection.equipments,
                        'Equipments Available',
                        screenWidth,
                        screenHeight,
                        trailing: _addButton(
                            () => _showEquipmentsSheet(context, provider),
                            screenWidth),
                        child: _buildEquipmentsList(provider, screenWidth),
                      ),
                      SizedBox(height: screenHeight * 0.015),

                      // Membership Fee Section
                      _buildSection(
                        ExpandedSection.membership,
                        'Membership Fee',
                        screenWidth,
                        screenHeight,
                        trailing: _addButton(
                            () => _showMembershipSheet(context, provider),
                            screenWidth),
                        child: _buildMembershipInfo(provider, screenWidth),
                      ),

                      // Loading indicator when submitting
                      if (_isSubmitting) ...[
                        SizedBox(height: screenHeight * 0.025),
                        CustomCard(
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          child: Column(
                            children: [
                              Text(
                                'Creating gym profile...',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontSize: ResponsiveHelper.sp(14),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Saving your business information',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: ResponsiveHelper.sp(12),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.015),
                              const LinearProgressIndicator(
                                backgroundColor: AppColors.inputBackground,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryGreen),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(screenWidth * 0.04),
                child: SafeArea(
                  top: false,
                  child: PrimaryButton(
                    text: 'Create Gym Profile',
                    isLoading: _isSubmitting,
                    isEnabled: !_isSubmitting,
                    onPressed: _onSave,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(ExpandedSection section, String title,
      double screenWidth, double screenHeight,
      {required Widget child, Widget? trailing}) {
    final isExpanded = _expandedSection == section;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cardBackground,
            AppColors.primaryOlive.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: isExpanded
              ? AppColors.primaryGreen.withOpacity(0.5)
              : AppColors.inputBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleSection(section),
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontSize: ResponsiveHelper.sp(15),
                      ),
                    ),
                  ),
                  if (trailing != null && !isExpanded) ...[
                    trailing,
                    SizedBox(width: screenWidth * 0.02),
                  ],
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textPrimary,
                      size: screenWidth * 0.06,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Container(
              height: 1,
              color: AppColors.inputBorder.withOpacity(0.5),
            ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: child,
            ),
          ],
        ],
      ),
    );
  }

  Widget _addButton(VoidCallback onTap, double screenWidth) => GestureDetector(
        onTap: onTap,
        child: Text(
          '+Add',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.primaryGreen,
            fontSize: ResponsiveHelper.sp(14),
          ),
        ),
      );

  Widget _buildServicesList(BusinessProvider provider, double screenWidth) {
    if (provider.services.isEmpty) {
      return Center(
        child: _addButton(
            () => _showAddServiceSheet(context, provider), screenWidth),
      );
    }
    return Column(
      children: [
        ...provider.services.asMap().entries.map((e) => _serviceItem(
              e.value,
              () => _showAddServiceSheet(context, provider, editIndex: e.key),
              screenWidth,
            )),
        SizedBox(height: screenWidth * 0.02),
        Align(
          alignment: Alignment.centerLeft,
          child: _addButton(
              () => _showAddServiceSheet(context, provider), screenWidth),
        ),
      ],
    );
  }

  Widget _serviceItem(
          Service service, VoidCallback onEdit, double screenWidth) {
    final String timeSlotsText = service.timeSlots.isEmpty
        ? 'No time slots set'
        : service.timeSlots.map((s) => '${s.from} - ${s.to}').join(' & ');

    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: screenWidth * 0.01),
            child: Icon(
              Icons.check,
              color: AppColors.primaryGreen,
              size: screenWidth * 0.04,
            ),
          ),
          SizedBox(width: screenWidth * 0.02),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: ResponsiveHelper.sp(14),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  timeSlotsText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveHelper.sp(12),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.edit, size: screenWidth * 0.045),
            onPressed: onEdit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesList(BusinessProvider provider, double screenWidth) {
    final active = provider.facilities.where((f) => f.isAvailable).toList();
    if (active.isEmpty) {
      return Center(
        child: _addButton(
            () => _showFacilitiesSheet(context, provider), screenWidth),
      );
    }
    return Column(
      children: [
        ...active.map((f) => Padding(
              padding: EdgeInsets.only(bottom: screenWidth * 0.02),
              child: Row(
                children: [
                  Text(
                    '${f.name}  ₹299/hr',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: ResponsiveHelper.sp(14),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit, size: screenWidth * 0.045),
                    onPressed: () => _showFacilitiesSheet(context, provider),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )),
        SizedBox(height: screenWidth * 0.02),
        Align(
          alignment: Alignment.centerLeft,
          child: _addButton(
              () => _showFacilitiesSheet(context, provider), screenWidth),
        ),
      ],
    );
  }

  Widget _buildEquipmentsList(BusinessProvider provider, double screenWidth) {
    if (provider.equipments.isEmpty) {
      return Center(
        child: _addButton(
            () => _showEquipmentsSheet(context, provider), screenWidth),
      );
    }
    return Column(
      children: [
        ...provider.equipments.asMap().entries.map((e) => Padding(
              padding: EdgeInsets.only(bottom: screenWidth * 0.02),
              child: Row(
                children: [
                  Text(
                    e.value.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: ResponsiveHelper.sp(14),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.edit, size: screenWidth * 0.045),
                    onPressed: () => _showEquipmentsSheet(context, provider,
                        editIndex: e.key),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )),
        SizedBox(height: screenWidth * 0.02),
        Align(
          alignment: Alignment.centerLeft,
          child: _addButton(
              () => _showEquipmentsSheet(context, provider), screenWidth),
        ),
      ],
    );
  }

  Widget _buildMembershipInfo(BusinessProvider provider, double screenWidth) {
    final fee = provider.membershipFee;
    if (fee == null) {
      return Center(
        child: _addButton(
            () => _showMembershipSheet(context, provider), screenWidth),
      );
    }
    return Column(
      children: [
        if (fee.dailyFee != null)
          _feeRow('Daily Fee', fee.dailyFee!, fee.dailyDiscount, screenWidth),
        if (fee.weeklyFee != null)
          _feeRow(
              'Weekly Fee', fee.weeklyFee!, fee.weeklyDiscount, screenWidth),
        SizedBox(height: screenWidth * 0.02),
        Align(
          alignment: Alignment.centerLeft,
          child: _addButton(
              () => _showMembershipSheet(context, provider), screenWidth),
        ),
      ],
    );
  }

  Widget _feeRow(
          String label, double fee, double? discount, double screenWidth) =>
      Padding(
        padding: EdgeInsets.only(bottom: screenWidth * 0.02),
        child: Row(
          children: [
            Text(
              '$label ₹${fee.toInt()}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: ResponsiveHelper.sp(14),
              ),
            ),
            if (discount != null)
              Text(
                '  Discount:₹${discount.toInt()}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: ResponsiveHelper.sp(12),
                ),
              ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.edit, size: screenWidth * 0.045),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}
