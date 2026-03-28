import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../services/payment_service.dart';
import '../providers/home_provider.dart';
import 'home_screen.dart';

// Import webview only for mobile platforms
import 'package:webview_flutter/webview_flutter.dart';

class ElitePlanScreen extends StatefulWidget {
  const ElitePlanScreen({super.key});

  @override
  State<ElitePlanScreen> createState() => _ElitePlanScreenState();
}

class _ElitePlanScreenState extends State<ElitePlanScreen>
    with WidgetsBindingObserver {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  bool _isPaymentInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When app resumes from background and payment was in progress
    if (state == AppLifecycleState.resumed && _isPaymentInProgress) {
      debugPrint('📱 App resumed after payment - refreshing data...');
      _onPaymentComplete();
    }
  }

  Future<void> _onPaymentComplete() async {
    setState(() {
      _isPaymentInProgress = false;
      _isLoading = true;
    });

    // Show loading dialog during processing
    _showProcessingDialog();

    // Wait 5 seconds for payment processing (increased from 3 for Cashfree)
    debugPrint('⏳ Waiting 5 seconds for payment processing...');
    await Future.delayed(const Duration(seconds: 5));

    // Refresh gym profile to check elite status
    debugPrint('🏢 Checking elite status via Get Profile API...');
    await context.read<HomeProvider>().loadData();

    if (mounted) {
      final isElite = context.read<HomeProvider>().isElite;

      // Dismiss loading dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      if (isElite) {
        // Show payment successful message
        _showPaymentSuccessDialog();
      } else {
        // Retry logic: Wait additional 2 seconds and check again
        debugPrint('⏳ First check failed, waiting additional 2 seconds...');
        await Future.delayed(const Duration(seconds: 2));
        
        debugPrint('🏢 Retrying elite status check...');
        await context.read<HomeProvider>().loadData();
        
        final isEliteRetry = context.read<HomeProvider>().isElite;
        
        if (isEliteRetry) {
          debugPrint('✅ Payment successful on retry!');
          _showPaymentSuccessDialog();
        } else {
          debugPrint('❌ Payment failed after retry');
          _showPaymentFailedDialog();
        }
      }
    }
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const CircularProgressIndicator(
                color: AppColors.primaryGreen,
                strokeWidth: 2,
              ),
              AppSpacing.w16,
              Text('Processing Payment...', style: AppTextStyles.heading4),
            ],
          ),
          content: Text(
            'Please wait while we verify your payment status. This may take up to 7 seconds.',
            style: AppTextStyles.bodyMedium,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            TextButton(
              onPressed: () {
                // Allow user to cancel if needed
                Navigator.of(dialogContext).pop();
                // Navigate to home screen anyway
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              },
              child: Text(
                'Cancel',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 32),
              AppSpacing.w12,
              Text('Payment Successful!', style: AppTextStyles.heading4),
            ],
          ),
          content: Text(
            'Congratulations! Your Elite membership has been activated successfully.',
            style: AppTextStyles.bodyMedium,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  // Navigate to home screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: AppColors.primaryGreen,
                ),
                child: Text(
                  'Continue to Home',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPaymentFailedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 32),
              AppSpacing.w12,
              Text('Payment Failed', style: AppTextStyles.heading4),
            ],
          ),
          content: Text(
            'Your payment could not be processed. Please try again or contact support if the issue persists.',
            style: AppTextStyles.bodyMedium,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // Stay on Elite Plan screen
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Try Again',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // Navigate to home screen anyway
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                      child: Text(
                        'Continue',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEliteSuccessDialog(BuildContext context) {
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

  Future<void> _handleUpgrade() async {
    setState(() => _isLoading = true);

    try {
      final result = await _paymentService.createElitePaymentOrder();

      if (result['success'] == true && result['payment_link_url'] != null) {
        final paymentUrl = result['payment_link_url'] as String;
        debugPrint('💳 Payment link: $paymentUrl');

        setState(() {
          _isLoading = false;
          _isPaymentInProgress = true;
        });

        // Handle payment based on platform
        if (kIsWeb) {
          // For web, open payment link in new tab
          if (mounted) {
            await launchUrl(
              Uri.parse(paymentUrl),
              mode: LaunchMode.externalApplication,
            );
            // For web, we can't detect payment completion easily
            // So we'll just show a message and refresh after a delay
            _showWebPaymentDialog();
          }
        } else {
          // For mobile, use WebView
          if (mounted) {
            final paymentCompleted = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => _PaymentWebView(
                  paymentUrl: paymentUrl,
                ),
              ),
            );

            // Payment WebView closed - check status
            if (paymentCompleted == true) {
              _onPaymentComplete();
            } else {
              setState(() => _isPaymentInProgress = false);
            }
          }
        }
      } else {
        setState(() => _isLoading = false);
        _showErrorDialog(result['message'] ?? 'Failed to create payment order');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('❌ Error creating payment order: $e');
      _showErrorDialog('Payment cannot be processed now, try after sometime');
    }
  }

  void _showWebPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Complete Payment', style: AppTextStyles.heading4),
        content: Text(
          'Payment page opened in new tab. Please complete the payment and return here.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Refresh data after a short delay
              Future.delayed(const Duration(seconds: 5), () {
                _onPaymentComplete();
              });
            },
            child: Text(
              'Done',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Payment Error', style: AppTextStyles.heading4),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primaryGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Pro Member Plan'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenPaddingH),
        child: Column(
          children: [
            AppSpacing.h16,
            // Diamond Icon
            Container(
              width: 100,
              height: 100,
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
              child: const Icon(Icons.diamond, color: Colors.white, size: 50),
            ),
            AppSpacing.h32,
            // Benefits Card
            CustomCard(
              padding: const EdgeInsets.all(AppDimensions.paddingXL),
              child: Column(
                children: [
                  Text('Boost Your Business with Pro Member', style: AppTextStyles.heading3),
                  AppSpacing.h8,
                  Text(
                    'Get a featured spot and grow faster',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.h32,
                  // Benefit 1
                  _buildBenefit(
                    icon: Icons.trending_up,
                    iconBgColor: AppColors.primaryGreen.withOpacity(0.2),
                    iconColor: AppColors.primaryGreen,
                    title: 'Increased Visibility',
                    description:
                        'Increase your visibility on our homepage and in search results.',
                  ),
                  AppSpacing.h24,
                  const Divider(color: AppColors.inputBorder),
                  AppSpacing.h24,
                  // Benefit 2
                  _buildBenefit(
                    icon: Icons.monetization_on,
                    iconBgColor: Colors.amber.withOpacity(0.2),
                    iconColor: Colors.amber,
                    title: 'More Orders & Higher Revenue',
                    description:
                        'Drive more customer inquiries and increase your earnings.',
                  ),
                  AppSpacing.h24,
                  const Divider(color: AppColors.inputBorder),
                  AppSpacing.h24,
                  // Benefit 3
                  _buildBenefit(
                    icon: Icons.verified,
                    iconBgColor: Colors.purple.withOpacity(0.2),
                    iconColor: Colors.purple,
                    title: 'Enhanced Credibility',
                    description:
                        'Build a stronger, more professional brand reputation.',
                  ),
                  AppSpacing.h32,
                  // Upgrade Button
                  Container(
                    width: double.infinity,
                    height: AppDimensions.buttonHeightL,
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleUpgrade,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusM),
                        child: _isLoading
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.buttonText,
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Upgrade to Elite',
                                      style: AppTextStyles.buttonLarge),
                                  AppSpacing.w8,
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppColors.buttonText,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  AppSpacing.w8,
                                  Text('₹899 /month',
                                      style: AppTextStyles.buttonLarge),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        AppSpacing.w16,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              AppSpacing.h4,
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// In-app WebView for Razorpay payment (Mobile only)
class _PaymentWebView extends StatefulWidget {
  final String paymentUrl;

  const _PaymentWebView({
    required this.paymentUrl,
  });

  @override
  State<_PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<_PaymentWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Only initialize WebView on mobile platforms
    if (!kIsWeb) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              debugPrint('🌐 Page started: $url');
              setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              debugPrint('🌐 Page finished: $url');
              setState(() => _isLoading = false);
            },
            onNavigationRequest: (NavigationRequest request) {
              debugPrint('🌐 Navigation request: ${request.url}');

              // Detect Razorpay callback URL - payment completed
              if (request.url.contains('/payments/elite/verify') ||
                  request.url.contains('razorpay_payment_id')) {
                debugPrint('✅ Payment callback detected - closing WebView');
                // Close WebView and return true (payment completed)
                Navigator.of(context).pop(true);
                return NavigationDecision.prevent;
              }

              // Allow all other navigation
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.paymentUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return error widget for web platform
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          title: Text('Payment Error', style: AppTextStyles.heading4),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'WebView not available on web platform',
            style: AppTextStyles.bodyMedium,
          ),
        ),
      );
    }

    // Return WebView for mobile platforms
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            // User cancelled - return false
            Navigator.of(context).pop(false);
          },
        ),
        title: Text(
          'Complete Payment',
          style: AppTextStyles.heading4,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryGreen,
              ),
            ),
        ],
      ),
    );
  }
}
