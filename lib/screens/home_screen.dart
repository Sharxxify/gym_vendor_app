import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/business_provider.dart';
import '../providers/home_provider.dart';
import 'widgets/earnings_tab.dart';
import 'widgets/customers_tab.dart';
import 'widgets/side_menu_drawer.dart';
import 'elite_plan_screen.dart';
import 'review_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool showEliteSuccessDialog;

  const HomeScreen({super.key, this.showEliteSuccessDialog = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeProvider>().loadData();

      // Show elite success dialog if coming from successful payment
      if (widget.showEliteSuccessDialog) {
        _showEliteSuccessDialog();
      }
    });
  }

  void _showEliteSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        // Auto close after 4 seconds
        Future.delayed(const Duration(seconds: 4), () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.of(dialogContext).pop();
          }
        });

        return Dialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Diamond Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryGreen.withOpacity(0.8),
                        AppColors.primaryGreen,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child:
                      const Icon(Icons.diamond, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 20),
                Text(
                  '🎉 Congratulations!',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: 8),
                Text(
                  'Now you are a Pro Member!',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<BusinessProvider, HomeProvider>(
      builder: (context, businessProvider, homeProvider, child) {
        final business = businessProvider.business;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.background,
          drawer: SideMenuDrawer(
            isElite: homeProvider.isElite,
            isVerified: homeProvider.isVerified,
          ),

          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () => homeProvider.loadData(),
              color: AppColors.primaryGreen,
              backgroundColor: AppColors.cardBackground,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                  child: Column(
                    children: [
                      // App Bar
                      _buildAppBar(context, business, homeProvider),
                      // Elite Membership Banner - Only show if not elite
                      if (!homeProvider.isElite) _buildEliteBanner(context),
                      // Stats Overview
                      _buildStatsOverview(homeProvider),
                      // Tab Content
                      Expanded(
                        child: _buildTabContent(homeProvider),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(
      BuildContext context, business, HomeProvider homeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingH,
        vertical: AppDimensions.paddingM,
      ),
      child: Row(
        children: [
          // Clickable Profile Section - Opens Review Screen
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ReviewScreen()),
              );
            },
            child: Row(
              children: [
                // Business Image
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                    color: AppColors.cardBackground,
                    image: homeProvider.profilePictureUrl != null
                        ? DecorationImage(
                            image:
                                NetworkImage(homeProvider.profilePictureUrl!),
                            fit: BoxFit.cover,
                          )
                        : (business?.images != null &&
                                business!.images.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(business.images.first),
                                fit: BoxFit.cover,
                              )
                            : null),
                  ),
                  child: homeProvider.profilePictureUrl == null &&
                          (business?.images == null || business!.images.isEmpty)
                      ? const Icon(Icons.fitness_center,
                          color: AppColors.primaryGreen)
                      : null,
                ),
                AppSpacing.w12,
                // Business Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      homeProvider.gymName ?? business?.name ?? 'My Business',
                      style: AppTextStyles.labelLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: AppColors.primaryGreen, size: 14),
                        AppSpacing.w4,
                        Text(
                          '${homeProvider.gymRating ?? business?.rating ?? 0}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.primaryGreen),
                        ),
                        AppSpacing.w4,
                        Text(
                          '(${_formatCount(homeProvider.reviewCount ?? business?.reviewCount ?? 0)})',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          // Menu button only (notification bell removed)
          _buildIconButton(
              Icons.menu, () => _scaffoldKey.currentState?.openDrawer()),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }

  Widget _buildEliteBanner(BuildContext context) {
    final homeProvider = context.watch<HomeProvider>();
    final isVerified = homeProvider.isVerified;
    final status = homeProvider.gymStatus?.toLowerCase() ?? '';

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppDimensions.screenPaddingH),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.paddingM),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.cardBackground,
              isVerified
                  ? AppColors.primaryOlive.withOpacity(0.3)
                  : Colors.orange.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: isVerified ? AppColors.inputBorder : Colors.orange.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isVerified ? AppColors.primaryGreen : Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVerified ? Icons.diamond : Icons.pending_actions,
                color: Colors.white,
                size: 18,
              ),
            ),
            AppSpacing.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVerified ? 'Become a Pro Member' : 'KYC Verification Pending',
                    style: AppTextStyles.labelMedium,
                  ),
                  Text(
                    isVerified
                        ? 'More visibility = More bookings'
                        : 'Upgrade to Elite after your gym is verified.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isVerified)
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ElitePlanScreen()),
                  );
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.primaryGreen),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    'Get Now',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                ),
                child: Text(
                  status == 'rejected' ? 'Rejected' : 'Pending',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(HomeProvider provider) {
    final stats = provider.stats;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Overview', style: AppTextStyles.labelLarge),
              Row(
                children: [
                  Text(stats?.dateRange ?? '',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  AppSpacing.w8,
                  _buildPeriodDropdown(provider),
                ],
              ),
            ],
          ),
          AppSpacing.h12,
          // Stat Cards - Only 2 tabs: Earnings and Customers
          Row(
            children: [
              _buildStatCard(
                'Earnings',
                '₹ ${_formatNumber(provider.totalEarningsForPeriod.toInt())}',
                '${stats?.earningsChange ?? 0}%',
                (stats?.earningsChange ?? 0) >= 0,
                Icons.currency_rupee,
                provider.selectedTab == HomeTab.earnings,
                () => provider.setSelectedTab(HomeTab.earnings),
              ),
              AppSpacing.w12,
              _buildStatCard(
                'Customers',
                '${stats?.totalCustomers ?? 0}',
                '+ ${stats?.customersChange ?? 0}%',
                (stats?.customersChange ?? 0) >= 0,
                Icons.people_outline,
                provider.selectedTab == HomeTab.customers,
                () => provider.setSelectedTab(HomeTab.customers),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String change,
      bool isPositive, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.paddingM),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? AppColors.selectedCardGradient
                    : AppColors.cardGradient,
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                border: Border.all(
                    color: isSelected
                        ? AppColors.primaryGreen
                        : AppColors.inputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 14, color: AppColors.textSecondary),
                      AppSpacing.w4,
                      Flexible(
                        child: Text(
                          title,
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.h8,
                  Text(value, style: AppTextStyles.heading4),
                  AppSpacing.h4,
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isPositive
                              ? AppColors.primaryGreen
                              : AppColors.primaryRed)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      change,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isPositive
                            ? AppColors.primaryGreen
                            : AppColors.primaryRed,
                      ),
                    ),
                  ),
                  // Add spacing for the arrow when selected
                  if (isSelected) const SizedBox(height: 16),
                ],
              ),
            ),
            // Dropdown arrow positioned at the bottom, touching the border
            if (isSelected)
              Positioned(
                bottom: -10,
                left: 0,
                right: 0,
                child: Center(
                  child: CustomPaint(
                    size: const Size(20, 12),
                    painter: _DropdownArrowPainter(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodDropdown(HomeProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: provider.selectedPeriod,
          isDense: true,
          dropdownColor: AppColors.cardBackground,
          items: ['Today', 'This Week', 'This Month', 'This Year']
              .map((e) => DropdownMenuItem(
                  value: e, child: Text(e, style: AppTextStyles.bodySmall)))
              .toList(),
          onChanged: (v) => provider.setSelectedPeriod(v!),
        ),
      ),
    );
  }

  Widget _buildTabContent(HomeProvider provider) {
    switch (provider.selectedTab) {
      case HomeTab.earnings:
        return EarningsTab(transactions: provider.filteredTransactions);
      case HomeTab.customers:
        return CustomersTab(
            customers: provider.filteredCustomers,
            onSearch: provider.setSearchQuery);
      case HomeTab.attendance:
        // Redirect to customers if attendance is somehow selected
        return CustomersTab(
            customers: provider.filteredCustomers,
            onSearch: provider.setSearchQuery);
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  String _formatNumber(int number) {
    if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(1)}L';
    } else if (number >= 1000) {
      // Use integer division to prevent rounding up the thousands place
      return '${number ~/ 1000},${(number % 1000).toString().padLeft(3, '0')}';
    }
    return number.toString();
  }
}

/// Custom painter for the dropdown arrow indicator
class _DropdownArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.fill;

    final path = Path();
    // Draw a downward pointing triangle/arrow
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
