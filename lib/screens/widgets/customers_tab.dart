import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../client_details_screen.dart';

class CustomersTab extends StatelessWidget {
  final List<Customer> customers;
  final Function(String) onSearch;

  const CustomersTab(
      {super.key, required this.customers, required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH),
          child: Text('Customers (${customers.length})',
              style: AppTextStyles.labelLarge),
        ),
        AppSpacing.h12,
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH),
          child: SearchTextField(
            hintText: 'Search Customer name or phone',
            onChanged: onSearch,
          ),
        ),
        AppSpacing.h12,
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH),
            itemCount: customers.length,
            itemBuilder: (context, index) =>
                _buildCustomerCard(context, customers[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerCard(BuildContext context, Customer customer) {
    final daysText = customer.daysRemaining > 0
        ? '${customer.daysRemaining}d left'
        : 'Expired';
    final lastCheckinText = customer.lastCheckin != null
        ? DateFormatter.formatDate(customer.lastCheckin!)
        : 'No check-ins';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.paddingM),
      child: CustomCard(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (_) => ClientDetailsScreen(customer: customer)),
          );
        },
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.inputBackground,
                  backgroundImage: customer.profileImage != null
                      ? NetworkImage(customer.profileImage!)
                      : null,
                  child: customer.profileImage == null
                      ? Text(customer.name[0], style: AppTextStyles.heading4)
                      : null,
                ),
                AppSpacing.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer.name, style: AppTextStyles.labelLarge),
                      Text(customer.phoneNumber,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: customer.daysRemaining > 0
                        ? AppColors.primaryGreen.withOpacity(0.15)
                        : AppColors.error.withOpacity(0.12),
                    border: Border.all(
                      color: customer.daysRemaining > 0
                          ? AppColors.primaryGreen
                          : AppColors.error,
                    ),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                  ),
                  child: Text(
                    customer.status,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: customer.daysRemaining > 0
                          ? AppColors.primaryGreen
                          : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
            AppSpacing.h12,
            const Divider(color: AppColors.inputBorder, height: 1),
            AppSpacing.h12,
            Row(
              children: [
                _buildInfoColumn('Plan', customer.membershipType),
                _buildInfoColumn('Remaining', daysText),
                _buildInfoColumn('Last Check-in', lastCheckinText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Expanded(
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
  }
}
