import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/home_provider.dart';
import '../attendance_scanner_screen.dart';

class AttendanceTab extends StatefulWidget {
  final Map<DateTime, int> attendanceData;

  const AttendanceTab({super.key, required this.attendanceData});

  @override
  State<AttendanceTab> createState() => _AttendanceTabState();
}

class _AttendanceTabState extends State<AttendanceTab> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      int newMonth = _selectedMonth + delta;
      int newYear = _selectedYear;

      if (newMonth > 12) {
        newMonth = 1;
        newYear++;
      } else if (newMonth < 1) {
        newMonth = 12;
        newYear--;
      }

      _selectedMonth = newMonth;
      _selectedYear = newYear;
    });
  }

  // Get previous month name
  String get _previousMonthName {
    int prevMonth = _selectedMonth - 1;
    if (prevMonth < 1) prevMonth = 12;
    return _getShortMonthName(prevMonth);
  }

  // Get next month name
  String get _nextMonthName {
    int nextMonth = _selectedMonth + 1;
    if (nextMonth > 12) nextMonth = 1;
    return _getShortMonthName(nextMonth);
  }

  // Generate list of years for dropdown (5 years back to 2 years forward)
  List<int> get _yearsList {
    final currentYear = DateTime.now().year;
    return List.generate(8, (index) => currentYear - 5 + index);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate stats for selected month
    int present = 0;
    int total = 0;
    widget.attendanceData.forEach((date, value) {
      if (date.month == _selectedMonth && date.year == _selectedYear) {
        total++;
        if (value > 0) present++;
      }
    });
    final percentage = total > 0 ? ((present / total) * 100).round() : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH),
          child: Text('Attendance', style: AppTextStyles.labelLarge),
        ),
        AppSpacing.h12,
        // Stats Card
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH),
          child: CustomCard(
            padding: const EdgeInsets.all(AppDimensions.paddingL),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.textSecondary, size: 20),
                AppSpacing.w12,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Attendance %',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    Text('$percentage%', style: AppTextStyles.heading4),
                  ],
                ),
                const Spacer(),
                Container(width: 1, height: 40, color: AppColors.inputBorder),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Present',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.heading4,
                        children: [
                          TextSpan(
                              text: '$present',
                              style: AppTextStyles.heading4
                                  .copyWith(color: AppColors.primaryGreen)),
                          TextSpan(text: ' / $total'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        AppSpacing.h16,
        // Calendar
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH),
            child: CustomCard(
              padding: const EdgeInsets.all(AppDimensions.paddingL),
              child: Column(
                children: [
                  // Year Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.inputBorder),
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusS),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        isDense: true,
                        dropdownColor: AppColors.cardBackground,
                        icon: const Icon(Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary),
                        items: _yearsList
                            .map((year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('$year',
                                      style: AppTextStyles.labelMedium),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedYear = value);
                          }
                        },
                      ),
                    ),
                  ),
                  AppSpacing.h12,
                  // Month Selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Month
                      GestureDetector(
                        onTap: () => _changeMonth(-1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              const Icon(Icons.chevron_left,
                                  color: AppColors.textSecondary, size: 20),
                              Text(
                                _previousMonthName,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Current Month
                      Text(
                        _getFullMonthName(_selectedMonth),
                        style: AppTextStyles.labelLarge
                            .copyWith(color: AppColors.primaryGreen),
                      ),
                      // Next Month
                      GestureDetector(
                        onTap: () => _changeMonth(1),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Text(
                                _nextMonthName,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: AppColors.textSecondary),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.textSecondary, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h16,
                  // Days Header (Mon-Sun)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                        .map((d) => SizedBox(
                              width: 36,
                              child: Center(
                                child: Text(
                                  d,
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.textSecondary),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  AppSpacing.h8,
                  // Calendar Grid
                  Expanded(child: _buildCalendarGrid()),
                  AppSpacing.h12,
                  // Legend
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(AppColors.primaryGreen, '>60%'),
                      AppSpacing.w12,
                      _buildLegend(Colors.amber, '20-60%'),
                      AppSpacing.w12,
                      _buildLegend(AppColors.primaryRed, '<20%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        AppSpacing.h16,
        // Scan QR Code Button
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH),
          child: PrimaryButton(
            text: 'Scan QR Code',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AttendanceScannerScreen(),
                ),
              );
            },
          ),
        ),
        AppSpacing.h16,
      ],
    );
  }

  Widget _buildCalendarGrid() {
    // Get first day of the selected month
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);

    // Get number of days in selected month
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);

    // Get weekday of first day (1 = Monday, 7 = Sunday in Dart)
    final firstWeekday = firstDayOfMonth.weekday;

    // Get previous month's last day
    final prevMonth = DateTime(_selectedYear, _selectedMonth, 0);
    final prevMonthDays = prevMonth.day;

    List<Widget> dayWidgets = [];

    // Add previous month's trailing days
    for (int i = 1; i < firstWeekday; i++) {
      final day = prevMonthDays - (firstWeekday - 1) + i;
      dayWidgets.add(_buildDayCell(day, isCurrentMonth: false));
    }

    // Add current month's days
    final now = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);

      // Check if today
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      // Find attendance for this date
      int? attendance;
      widget.attendanceData.forEach((key, value) {
        if (key.year == date.year &&
            key.month == date.month &&
            key.day == date.day) {
          attendance = value;
        }
      });

      dayWidgets
          .add(_buildDayCell(day, attendance: attendance, isToday: isToday));
    }

    // Add next month's leading days to fill the grid (6 rows = 42 cells)
    final remaining = 42 - dayWidgets.length;
    for (int i = 1; i <= remaining; i++) {
      dayWidgets.add(_buildDayCell(i, isCurrentMonth: false));
    }

    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      childAspectRatio: 1,
      physics: const NeverScrollableScrollPhysics(),
      children: dayWidgets,
    );
  }

  Widget _buildDayCell(int day,
      {bool isCurrentMonth = true, int? attendance, bool isToday = false}) {
    Color bgColor = Colors.transparent;
    Color textColor =
        isCurrentMonth ? AppColors.textPrimary : AppColors.textHint;
    BoxBorder? border;

    // Highlight today with green border
    if (isToday) {
      border = Border.all(color: AppColors.primaryGreen, width: 2);
    }

    // Color based on attendance value
    if (isCurrentMonth && attendance != null) {
      if (attendance == 0) {
        bgColor = AppColors.primaryRed.withOpacity(0.8);
      } else if (attendance == 1) {
        bgColor = AppColors.primaryRed.withOpacity(0.6);
      } else if (attendance == 2) {
        bgColor = Colors.amber.withOpacity(0.6);
      } else {
        bgColor = AppColors.primaryGreen.withOpacity(0.6);
      }
      textColor = AppColors.textPrimary;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: border,
      ),
      child: Center(
        child: Text(
          day.toString(),
          style: AppTextStyles.bodyMedium.copyWith(color: textColor),
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        AppSpacing.w4,
        Text(text, style: AppTextStyles.labelSmall.copyWith(fontSize: 9)),
      ],
    );
  }

  String _getFullMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  String _getShortMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
