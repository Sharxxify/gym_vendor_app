import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/formatters.dart';
import '../models/models.dart';
import '../providers/home_provider.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Customer customer;
  const ClientDetailsScreen({super.key, required this.customer});

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _selectedYear;
  late int _selectedMonth;

  // API Data
  List<Transaction> _transactions = [];
  List<int> _attendanceData = [];
  bool _isLoadingTransactions = true;
  bool _isLoadingAttendance = true;
  String? _errorTransactions;
  String? _errorAttendance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Generate list of years for dropdown (5 years back to 2 years forward)
  List<int> get _yearsList {
    final currentYear = DateTime.now().year;
    final years = List.generate(8, (index) => currentYear - 5 + index);

    // Ensure selected year is always in the list
    if (!years.contains(_selectedYear)) {
      years.add(_selectedYear);
      years.sort();
    }

    return years;
  }

  /// Load customer transactions and attendance from API
  Future<void> _loadData() async {
    final homeProvider = context.read<HomeProvider>();

    // Load transactions
    setState(() {
      _isLoadingTransactions = true;
      _errorTransactions = null;
    });

    try {
      final transactions =
          await homeProvider.loadCustomerTransactions(widget.customer.id);
      setState(() {
        _transactions = transactions;
        _isLoadingTransactions = false;
      });
    } catch (e) {
      setState(() {
        _errorTransactions = e.toString();
        _isLoadingTransactions = false;
      });
    }

    // Load attendance
    _loadAttendanceForMonth();
  }

  /// Load attendance for a specific month
  Future<void> _loadAttendanceForMonth() async {
    setState(() {
      _isLoadingAttendance = true;
      _errorAttendance = null;
    });

    try {
      final homeProvider = context.read<HomeProvider>();
      final attendance = await homeProvider.loadCustomerAttendance(
        widget.customer.id,
        month: _selectedMonth,
        year: _selectedYear,
      );
      setState(() {
        _attendanceData = attendance;
        _isLoadingAttendance = false;
      });
    } catch (e) {
      setState(() {
        _errorAttendance = e.toString();
        _isLoadingAttendance = false;
      });
    }
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
    _loadAttendanceForMonth();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(),
          AppSpacing.h16,
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionsTab(),
                _buildAttendanceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final c = widget.customer;
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.inputBackground,
                child: Text(c.name[0], style: AppTextStyles.heading3),
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name, style: AppTextStyles.heading4),
                    Text(
                      c.phoneNumber,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primaryGreen),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  c.status,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: AppColors.primaryGreen),
                ),
              ),
            ],
          ),
          AppSpacing.h16,
          const Divider(color: AppColors.inputBorder),
          AppSpacing.h12,
          Row(
            children: [
              _info('Since', DateFormatter.formatDate(c.memberSince)),
              _info('Membership', c.membershipType),
              _info(
                  'Ends in',
                  c.membershipEndDate != null
                      ? DateFormatter.formatShortDate(c.membershipEndDate!)
                      : '-'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            AppSpacing.h4,
            Text(value, style: AppTextStyles.labelMedium),
          ],
        ),
      );

  Widget _buildTabBar() => Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppDimensions.screenPaddingH),
        decoration: BoxDecoration(
          border: Border(
              bottom:
                  BorderSide(color: AppColors.inputBorder.withOpacity(0.3))),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryGreen,
          labelColor: AppColors.primaryGreen,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Transactions'),
            Tab(text: 'Attendance'),
          ],
        ),
      );

  Widget _buildTransactionsTab() {
    if (_isLoadingTransactions) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (_errorTransactions != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.primaryRed, size: 48),
            AppSpacing.h16,
            Text('Failed to load transactions',
                style: AppTextStyles.labelMedium),
            AppSpacing.h8,
            Text(
              _errorTransactions!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.h16,
            PrimaryButton(
              text: 'Retry',
              onPressed: _loadData,
              width: 120,
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined,
                color: AppColors.textSecondary, size: 48),
            AppSpacing.h16,
            Text('No transactions yet', style: AppTextStyles.labelMedium),
            AppSpacing.h8,
            Text(
              'Transaction history will appear here',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppDimensions.screenPaddingH),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        separatorBuilder: (_, __) =>
            const Divider(color: AppColors.inputBorder, height: 24),
        itemBuilder: (_, i) => Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_transactions[i].type, style: AppTextStyles.labelMedium),
                  AppSpacing.h4,
                  Text(
                    DateFormatter.formatTransactionDate(
                        _transactions[i].dateTime),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Text(
              '₹${_transactions[i].amount.toInt()}',
              style: AppTextStyles.labelLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceTab() {
    if (_isLoadingAttendance) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
        ),
      );
    }

    if (_errorAttendance != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: AppColors.primaryRed, size: 48),
            AppSpacing.h16,
            Text('Failed to load attendance', style: AppTextStyles.labelMedium),
            AppSpacing.h8,
            Text(
              _errorAttendance!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            AppSpacing.h16,
            PrimaryButton(
              text: 'Retry',
              onPressed: _loadData,
              width: 120,
            ),
          ],
        ),
      );
    }

    // Calculate attendance stats from real data
    final totalDays = _attendanceData.length;
    final presentDays = _attendanceData.where((d) => d == 1).length;
    final absentDays = totalDays - presentDays;
    final attendancePercent =
        totalDays > 0 ? ((presentDays / totalDays) * 100).toInt() : 0;

    // Format date range
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);
    final dateRangeText =
        '1 ${_getShortMonthName(_selectedMonth).toLowerCase()} - $daysInMonth ${_getShortMonthName(_selectedMonth).toLowerCase()}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month & Year selectors row
          Row(
            children: [
              // Month dropdown
              GestureDetector(
                onTap: _showMonthPicker,
                child: Row(
                  children: [
                    Text(_getFullMonthName(_selectedMonth),
                        style: AppTextStyles.labelMedium),
                    const Icon(Icons.keyboard_arrow_down, size: 20),
                  ],
                ),
              ),
              AppSpacing.w16,
              // Year dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.inputBorder),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isDense: true,
                    dropdownColor: AppColors.cardBackground,
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary, size: 18),
                    items: _yearsList
                        .map((year) => DropdownMenuItem(
                              value: year,
                              child:
                                  Text('$year', style: AppTextStyles.bodySmall),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedYear = value);
                        _loadAttendanceForMonth();
                      }
                    },
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateRangeText,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          AppSpacing.h16,
          // Stats card
          CustomCard(
            padding: const EdgeInsets.all(16),
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
                    Text('$attendancePercent%', style: AppTextStyles.heading4),
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
                    Text('$presentDays', style: AppTextStyles.heading4),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Absent',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    Text(
                      '$absentDays',
                      style: AppTextStyles.heading4
                          .copyWith(color: AppColors.primaryRed),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.h16,
          _buildCalendar(),
        ],
      ),
    );
  }

  /// Show month picker dialog
  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            AppSpacing.h16,
            Text('Select Month', style: AppTextStyles.heading4),
            AppSpacing.h16,
            // Scrollable month list
            Expanded(
              child: ListView.builder(
                itemCount: 12,
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final isSelected = month == _selectedMonth;
                  return ListTile(
                    title: Text(
                      _getFullMonthName(month),
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected
                            ? AppColors.primaryGreen
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check,
                            color: AppColors.primaryGreen, size: 20)
                        : null,
                    selected: isSelected,
                    selectedTileColor: AppColors.primaryGreen.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _selectedMonth = month);
                      _loadAttendanceForMonth();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    // Get first day of the selected month
    final firstDayOfMonth = DateTime(_selectedYear, _selectedMonth, 1);

    // Get number of days in selected month
    final daysInMonth = DateUtils.getDaysInMonth(_selectedYear, _selectedMonth);

    // Get weekday of first day (1 = Monday, 7 = Sunday)
    final firstWeekday = firstDayOfMonth.weekday;

    // Get previous month's last day
    final prevMonthLastDay = DateTime(_selectedYear, _selectedMonth, 0).day;

    List<Widget> cells = [];

    // Add previous month's trailing days (greyed out)
    for (int i = 1; i < firstWeekday; i++) {
      final day = prevMonthLastDay - (firstWeekday - 1) + i;
      cells.add(_cell(day, false, 0));
    }

    // Add current month's days with real attendance data
    final now = DateTime.now();
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedYear, _selectedMonth, day);
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      // Get attendance for this day from API data (1-indexed day, 0-indexed array)
      int attendance = 0;
      if (day <= _attendanceData.length) {
        attendance = _attendanceData[day - 1];
      }
      cells.add(_cell(day, true, attendance, isToday: isToday));
    }

    // Add next month's leading days (greyed out) - fill to 42 cells (6 rows)
    int nextMonthDay = 1;
    while (cells.length < 42) {
      cells.add(_cell(nextMonthDay++, false, 0));
    }

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation with year
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous month
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
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              // Current month & year
              Column(
                children: [
                  Text(
                    _getFullMonthName(_selectedMonth),
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.primaryGreen),
                  ),
                  Text(
                    '$_selectedYear',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              // Next month
              GestureDetector(
                onTap: () => _changeMonth(1),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Text(
                        _nextMonthName,
                        style: AppTextStyles.bodySmall
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
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                .map((d) => SizedBox(
                      width: 36,
                      child: Center(
                        child: Text(
                          d,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          AppSpacing.h8,
          // Calendar grid
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: cells,
          ),
          AppSpacing.h12,
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legend(AppColors.primaryGreen, 'Present'),
              AppSpacing.w16,
              _legend(AppColors.primaryRed, 'Absent'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cell(int day, bool isCurrentMonth, int attendance,
      {bool isToday = false}) {
    Color bgColor = Colors.transparent;
    Color textColor =
        isCurrentMonth ? AppColors.textPrimary : AppColors.textHint;
    BoxBorder? border;

    // Highlight today
    if (isToday) {
      border = Border.all(color: AppColors.primaryGreen, width: 2);
    }

    // Color based on attendance (only for current month days)
    if (isCurrentMonth) {
      // att = 1 means present (green), att = 0 means absent (red)
      bgColor = attendance == 1
          ? AppColors.primaryGreen.withOpacity(0.6)
          : AppColors.primaryRed.withOpacity(0.7);
      textColor = Colors.white;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: border,
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppTextStyles.bodySmall.copyWith(color: textColor),
        ),
      ),
    );
  }

  Widget _legend(Color color, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          AppSpacing.w4,
          Text(text, style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
        ],
      );

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
