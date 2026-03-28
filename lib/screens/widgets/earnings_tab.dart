import 'package:flutter/material.dart';
import '../../core/constants/constants.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';

class EarningsTab extends StatelessWidget {
  final List<Transaction> transactions;

  const EarningsTab({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.screenPaddingH),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Transactions', style: AppTextStyles.labelLarge),
              if (transactions.isNotEmpty)
                Text(
                  'Total: ₹${_formatAmount(_calculateTotal())}',
                  style: AppTextStyles.labelMedium
                      .copyWith(color: AppColors.primaryGreen),
                ),
            ],
          ),
        ),
        AppSpacing.h12,
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(
                horizontal: AppDimensions.screenPaddingH),
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: transactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 48, color: AppColors.textSecondary),
                        AppSpacing.h12,
                        Text(
                          'No transactions found',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        AppSpacing.h4,
                        Text(
                          'Transactions will appear here',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.paddingL),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.inputBorder, height: 24),
                    itemBuilder: (context, index) =>
                        _buildTransactionItem(transactions[index]),
                  ),
          ),
        ),
        AppSpacing.h16,
      ],
    );
  }

  double _calculateTotal() {
    return transactions
        .where((txn) =>
            txn.status != 'cancelled' &&
            txn.status != 'payment_pending' &&
            txn.status != 'failed' &&
            txn.status != 'rejected')
        .fold(0.0, (sum, txn) => sum + txn.amount);
  }

  String _formatAmount(double amount) {
    return amount.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    final statusText = (transaction.description ?? '').isNotEmpty
        ? transaction.description!
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(transaction.type, style: AppTextStyles.labelMedium),
              AppSpacing.h4,
              Text(
                '${transaction.customerName ?? 'Customer'}  •  ${DateFormatter.formatTransactionDate(transaction.dateTime)}',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
                '₹${transaction.amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                style: AppTextStyles.labelLarge),
            if (statusText != null) ...[
              AppSpacing.h4,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusText == 'confirmed'
                      ? AppColors.primaryGreen.withOpacity(0.15)
                      : statusText == 'cancelled'
                          ? AppColors.error.withOpacity(0.15)
                          : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statusText == 'confirmed'
                        ? AppColors.primaryGreen
                        : statusText == 'cancelled'
                            ? AppColors.error
                            : Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
