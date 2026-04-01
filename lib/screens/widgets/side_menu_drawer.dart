import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/constants.dart';
import '../../core/widgets/widgets.dart';
import '../../providers/auth_provider.dart';
import '../login_screen.dart';
import '../qr_code_screen.dart';
import '../elite_plan_screen.dart';
import '../update_profile_screen.dart';
import '../contact_us_screen.dart';

class SideMenuDrawer extends StatelessWidget {
  final bool isElite;
  final bool isVerified;

  const SideMenuDrawer({
    super.key,
    this.isElite = false,
    this.isVerified = false,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSpacing.h24,
              // My Account Section
              Text('My Account', style: AppTextStyles.heading4),
              AppSpacing.h16,
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.qr_code,
                      title: 'QR Code',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const QRCodeScreen()));
                      },
                    ),
                    const Divider(color: AppColors.inputBorder, height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'My Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UpdateProfileScreen()));
                      },
                    ),
                    // Only show Pro Subscription if verified and not elite
                    if (isVerified && !isElite) ...[
                      const Divider(color: AppColors.inputBorder, height: 1),
                      _buildMenuItem(
                        context,
                        icon: Icons.diamond_outlined,
                        title: 'Pro Member',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ElitePlanScreen()));
                        },
                      ),
                    ],
                  ],
                ),
              ),
              AppSpacing.h24,
              // Settings & Support Section
              Text('Settings & Support', style: AppTextStyles.heading4),
              AppSpacing.h16,
              CustomCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.contact_mail_outlined,
                      title: 'Contact Us',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ContactUsScreen()));
                      },
                    ),
                    const Divider(color: AppColors.inputBorder, height: 1),
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      title: 'Logout',
                      onTap: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textPrimary, size: 20),
            AppSpacing.w12,
            Expanded(child: Text(title, style: AppTextStyles.bodyMedium)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Logout', style: AppTextStyles.heading4),
        content: Text('Are you sure you want to logout?',
            style: AppTextStyles.bodyMedium),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      Navigator.pop(dialogContext);
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Logout',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: const Color(0xFFA1E433),
                      ),
                      textAlign: TextAlign.center,
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
