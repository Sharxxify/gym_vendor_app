import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';

class FacilitiesSheet extends StatefulWidget {
  final List<Facility> selectedFacilities;
  final Function(List<Facility>) onSave;

  const FacilitiesSheet({
    super.key,
    required this.selectedFacilities,
    required this.onSave,
  });

  @override
  State<FacilitiesSheet> createState() => _FacilitiesSheetState();
}

class _FacilitiesSheetState extends State<FacilitiesSheet> {
  static const List<String> _allFacilities = [
    'Trainer',
    'Group Classes',
    'Changing Areas',
    'Washroom',
    'Locker Rooms',
    'Towel Service',
    'Sauna/Steam',
    'Parking Lot',
  ];

  late Map<String, bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = {for (var f in _allFacilities) f: false};
    for (var facility in widget.selectedFacilities) {
      if (facility.isAvailable && _selected.containsKey(facility.name)) {
        _selected[facility.name] = true;
      }
    }
  }

  void _save() {
    final facilities = _allFacilities
        .map((name) => Facility(name: name, isIncluded: _selected[name] == true))
        .toList();
    widget.onSave(facilities);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text('Facilities', style: AppTextStyles.heading4),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(color: AppColors.inputBorder),
              AppSpacing.h16,
              // Facilities List
              CustomCard(
                padding: const EdgeInsets.all(AppDimensions.paddingL),
                child: Column(
                  children: _allFacilities.map((facility) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _selected[facility],
                              onChanged: (v) => setState(
                                  () => _selected[facility] = v ?? false),
                              activeColor: AppColors.primaryGreen,
                              checkColor: AppColors.buttonText,
                              side: BorderSide(
                                color: _selected[facility] == true
                                    ? AppColors.primaryGreen
                                    : AppColors.inputBorder,
                                width: 2,
                              ),
                            ),
                          ),
                          AppSpacing.w12,
                          Text(
                            facility,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: _selected[facility] == true
                                  ? AppColors.primaryGreen
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              AppSpacing.h24,
              // Save Button
              PrimaryButton(text: 'Save', onPressed: _save),
              AppSpacing.h16,
            ],
          ),
        ),
      ),
    );
  }
}
