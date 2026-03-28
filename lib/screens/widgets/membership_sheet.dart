import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../models/models.dart';

class MembershipSheet extends StatefulWidget {
  final MembershipFee? membershipFee;
  final Function(MembershipFee) onSave;

  const MembershipSheet({
    super.key,
    this.membershipFee,
    required this.onSave,
  });

  @override
  State<MembershipSheet> createState() => _MembershipSheetState();
}

class _MembershipSheetState extends State<MembershipSheet> {
  final _dailyFeeController = TextEditingController();
  final _dailyDiscountController = TextEditingController();
  final _weeklyFeeController = TextEditingController();
  final _weeklyDiscountController = TextEditingController();
  final _monthlyFeeController = TextEditingController();
  final _monthlyDiscountController = TextEditingController();
  final _quarterlyFeeController = TextEditingController();
  final _quarterlyDiscountController = TextEditingController();
  final _annualFeeController = TextEditingController();
  final _annualDiscountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final fee = widget.membershipFee;
    if (fee != null) {
      _dailyFeeController.text = fee.dailyFee?.toInt().toString() ?? '';
      _dailyDiscountController.text = fee.dailyDiscount?.toInt().toString() ?? '';
      _weeklyFeeController.text = fee.weeklyFee?.toInt().toString() ?? '';
      _weeklyDiscountController.text = fee.weeklyDiscount?.toInt().toString() ?? '';
      _monthlyFeeController.text = fee.monthlyFee?.toInt().toString() ?? '';
      _monthlyDiscountController.text = fee.monthlyDiscount?.toInt().toString() ?? '';
      _quarterlyFeeController.text = fee.quarterlyFee?.toInt().toString() ?? '';
      _quarterlyDiscountController.text = fee.quarterlyDiscount?.toInt().toString() ?? '';
      _annualFeeController.text = fee.annualFee?.toInt().toString() ?? '';
      _annualDiscountController.text = fee.annualDiscount?.toInt().toString() ?? '';
    }
  }

  @override
  void dispose() {
    _dailyFeeController.dispose();
    _dailyDiscountController.dispose();
    _weeklyFeeController.dispose();
    _weeklyDiscountController.dispose();
    _monthlyFeeController.dispose();
    _monthlyDiscountController.dispose();
    _quarterlyFeeController.dispose();
    _quarterlyDiscountController.dispose();
    _annualFeeController.dispose();
    _annualDiscountController.dispose();
    super.dispose();
  }

  double? _parse(String text) {
    if (text.isEmpty) return null;
    // Remove ₹ prefix if present
    final cleanText = text.replaceAll('₹', '').trim();
    if (cleanText.isEmpty) return null;
    return double.tryParse(cleanText);
  }

  void _save() {
    final fee = MembershipFee(
      dailyFee: _parse(_dailyFeeController.text),
      dailyDiscount: _parse(_dailyDiscountController.text),
      weeklyFee: _parse(_weeklyFeeController.text),
      weeklyDiscount: _parse(_weeklyDiscountController.text),
      monthlyFee: _parse(_monthlyFeeController.text),
      monthlyDiscount: _parse(_monthlyDiscountController.text),
      quarterlyFee: _parse(_quarterlyFeeController.text),
      quarterlyDiscount: _parse(_quarterlyDiscountController.text),
      annualFee: _parse(_annualFeeController.text),
      annualDiscount: _parse(_annualDiscountController.text),
    );
    widget.onSave(fee);
  }

  String _calcDiscounted(String fee, String discount) {
    final f = _parse(fee);
    final d = _parse(discount);
    if (f == null) return '';
    return '₹ ${((f) - (d ?? 0)).toInt()}';
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
              Row(
                children: [
                  Text('Membership Fee', style: AppTextStyles.heading4),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(color: AppColors.inputBorder),
              AppSpacing.h16,
              _buildFeeRow('Daily Fee', 'Discount', _dailyFeeController, _dailyDiscountController, '/day'),
              _buildFeeRow('Weekly Fee', 'Discount', _weeklyFeeController, _weeklyDiscountController, '/week'),
              _buildFeeRow('Monthly Fee', 'Discount', _monthlyFeeController, _monthlyDiscountController, '/month'),
              _buildFeeRow('Quarterly Fee', 'Discount', _quarterlyFeeController, _quarterlyDiscountController, '/Quarter'),
              _buildFeeRow('Annual Fee', 'Discount', _annualFeeController, _annualDiscountController, '/year'),
              AppSpacing.h24,
              PrimaryButton(text: 'Add Membership Fee', onPressed: _save),
              AppSpacing.h16,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeRow(
    String feeLabel,
    String discountLabel,
    TextEditingController feeController,
    TextEditingController discountController,
    String suffix,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(feeLabel, style: AppTextStyles.labelSmall),
                    AppSpacing.h4,
                    _buildField(feeController, feeLabel),
                  ],
                ),
              ),
              AppSpacing.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(discountLabel, style: AppTextStyles.labelSmall),
                    AppSpacing.h4,
                    _buildField(discountController, discountLabel),
                  ],
                ),
              ),
            ],
          ),
          if (feeController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${_calcDiscounted(feeController.text, discountController.text)}$suffix',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryGreen),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: AppTextStyles.inputText,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.inputHint,
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
      ),
    );
  }
}
