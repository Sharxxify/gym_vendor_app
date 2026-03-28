import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/utils.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenWidth = ResponsiveHelper.screenWidth;
    final screenHeight = ResponsiveHelper.screenHeight;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Contact Us'),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight * 0.02),
            // Office Address Card
            _buildContactCard(
              context: context,
              screenWidth: screenWidth,
              title: 'Office',
              icon: Icons.location_on_outlined,
              content: 'xyz location,\nBangalore',
              onTap: () {
                // Can open maps if needed
              },
            ),
            SizedBox(height: screenHeight * 0.02),
            // Email Card
            _buildContactCard(
              context: context,
              screenWidth: screenWidth,
              title: 'Email Address',
              icon: Icons.mail_outline,
              content: 'bookMyfit@gmail.com',
              onTap: () => _launchEmail('bookMyfit@gmail.com'),
            ),
            SizedBox(height: screenHeight * 0.02),
            // Phone Card
            _buildContactCard(
              context: context,
              screenWidth: screenWidth,
              title: 'Phone Number',
              icon: Icons.phone_outlined,
              content: '+91 9xxxxxxxx0',
              onTap: () => _launchPhone('+919xxxxxxxx0'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required double screenWidth,
    required String title,
    required IconData icon,
    required String content,
    required VoidCallback onTap,
  }) {
    return CustomCard(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              fontSize: ResponsiveHelper.sp(16),
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppColors.textSecondary,
                  size: screenWidth * 0.06,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontSize: ResponsiveHelper.sp(14),
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
