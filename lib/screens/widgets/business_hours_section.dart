import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/utils.dart';
import '../../models/models.dart';

class BusinessHoursSection extends StatelessWidget {
  final BusinessHours businessHours;
  final Function(int, DayHours) onUpdate;

  const BusinessHoursSection({
    super.key,
    required this.businessHours,
    required this.onUpdate,
  });

  static const List<String> _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenWidth = ResponsiveHelper.screenWidth;

    return Column(
      children: List.generate(7, (index) {
        final dayHours = businessHours.getDayHours(index);
        return _buildDayRow(context, index, _dayNames[index], dayHours, screenWidth);
      }),
    );
  }

  Widget _buildDayRow(BuildContext context, int index, String day, DayHours hours, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Day name
              SizedBox(
                width: screenWidth * 0.1,
                child: Text(
                  day,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: ResponsiveHelper.sp(14),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              
              // Open/Close label
              SizedBox(
                width: screenWidth * 0.12,
                child: Text(
                  hours.isOpen ? 'Open' : 'Close',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: hours.isOpen ? AppColors.textPrimary : AppColors.textSecondary,
                    fontSize: ResponsiveHelper.sp(12),
                  ),
                ),
              ),
              
              // Custom small toggle switch
              _buildCustomSwitch(
                value: hours.isOpen,
                onChanged: (value) {
                  onUpdate(
                    index,
                    hours.copyWith(
                      isOpen: value,
                      slots: value ? [TimeSlot(label: 'Morning', from: '06:00 AM', to: '12:00 PM')] : [],
                    ),
                  );
                },
                screenWidth: screenWidth,
              ),
              
              const Spacer(),
              
              if (hours.isOpen)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryGreen, size: 20),
                  onPressed: () {
                    final newSlots = List<TimeSlot>.from(hours.slots)..add(TimeSlot(label: 'Slot', from: '12:00 PM', to: '04:00 PM'));
                    onUpdate(index, hours.copyWith(slots: newSlots));
                  },
                ),
            ],
          ),
          if (hours.isOpen && hours.slots.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: screenWidth * 0.12, top: 4),
              child: Column(
                children: List.generate(hours.slots.length, (slotIndex) {
                  final slot = hours.slots[slotIndex];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: slot.label,
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 12),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                            ),
                            onChanged: (val) {
                              final newSlots = List<TimeSlot>.from(hours.slots);
                              newSlots[slotIndex] = TimeSlot(label: val, from: slot.from, to: slot.to);
                              onUpdate(index, hours.copyWith(slots: newSlots));
                            },
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        _buildTimeButton(
                          context, 
                          slot.from.isEmpty ? '06:00 AM' : slot.from, 
                          (time) {
                            final newSlots = List<TimeSlot>.from(hours.slots);
                            newSlots[slotIndex] = TimeSlot(label: slot.label, from: time, to: slot.to);
                            onUpdate(index, hours.copyWith(slots: newSlots));
                          },
                          screenWidth,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        _buildTimeButton(
                          context, 
                          slot.to.isEmpty ? '12:00 PM' : slot.to, 
                          (time) {
                            final newSlots = List<TimeSlot>.from(hours.slots);
                            newSlots[slotIndex] = TimeSlot(label: slot.label, from: slot.from, to: time);
                            onUpdate(index, hours.copyWith(slots: newSlots));
                          },
                          screenWidth,
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.error, size: 20),
                          onPressed: () {
                            final newSlots = List<TimeSlot>.from(hours.slots)..removeAt(slotIndex);
                            onUpdate(index, hours.copyWith(slots: newSlots));
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }

  // Custom small toggle switch matching Figma design
  Widget _buildCustomSwitch({
    required bool value,
    required Function(bool) onChanged,
    required double screenWidth,
  }) {
    final switchWidth = screenWidth * 0.11;
    final switchHeight = screenWidth * 0.055;
    final thumbSize = screenWidth * 0.045;
    
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: switchWidth,
        height: switchHeight,
        padding: EdgeInsets.all(screenWidth * 0.005),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(switchHeight / 2),
          color: value ? AppColors.primaryGreen : AppColors.inputBackground,
          border: Border.all(
            color: value ? AppColors.primaryGreen : AppColors.inputBorder,
            width: 1,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.buttonText : AppColors.textSecondary,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeButton(BuildContext context, String time, Function(String) onSelect, double screenWidth) {
    return InkWell(
      onTap: () => _showTimePicker(context, time, onSelect),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.025,
          vertical: screenWidth * 0.015,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputBackground.withOpacity(0.5),
          borderRadius: BorderRadius.circular(screenWidth * 0.015),
          border: Border.all(
            color: AppColors.primaryOlive,
            width: 1,
          ),
        ),
        child: Text(
          time,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: ResponsiveHelper.sp(12),
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    String currentTime,
    Function(String) onSelect,
  ) async {
    final parts = currentTime.split(':');
    int hour = int.tryParse(parts[0]) ?? 9;
    final isPM = currentTime.toLowerCase().contains('pm');
    if (isPM && hour != 12) hour += 12;
    if (!isPM && hour == 12) hour = 0;

    final int minute = int.tryParse(parts[1].split(' ')[0]) ?? 0;

    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: hour, minute: minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryGreen,
              surface: AppColors.cardBackground,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final h = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final m = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      onSelect('$h:$m $period');
    }
  }
}
