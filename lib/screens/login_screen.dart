import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/utils.dart';
import '../providers/auth_provider.dart';
import 'kyc_verification_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (_formKey.currentState?.validate() ?? false) {
      final authProvider = context.read<AuthProvider>();
      final phoneNumber = '+91${_phoneController.text.replaceAll(' ', '')}';

      final success = await authProvider.sendOtp(phoneNumber);

          if (success && mounted) {
            _showOtpBottomSheet(phoneNumber);
          } else if (mounted && authProvider.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
    }
  }

  void _showOtpBottomSheet(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) => OtpBottomSheet(
        phoneNumber: phoneNumber,
        onSuccess: (bool isNewUser) {
          Navigator.of(context).pop();
          if (isNewUser) {
            debugPrint('🆕 New user detected, showing KYC verification screen');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
              (route) => false,
            );
          } else {
            debugPrint('👤 Existing user, going to home screen');
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenHeight = ResponsiveHelper.screenHeight;
    final screenWidth = ResponsiveHelper.screenWidth;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Image - tries multiple paths/extensions
          Positioned.fill(
            child: _BackgroundImage(),
          ),

          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.background.withOpacity(0.3),
                    AppColors.background.withOpacity(0.7),
                    AppColors.background,
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.6, 0.75],
                ),
              ),
            ),
          ),

          // Logo at top
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.04),
              child: Center(
                child: Column(
                  children: [
                    // Logo Image
                    _LogoImage(height: screenHeight * 0.13),
                  ],
                ),
              ),
            ),
          ),

          // Login Form at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.025,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cardBackground.withOpacity(0.95),
                    AppColors.primaryOlive.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(screenWidth * 0.08),
                ),
                border: Border.all(
                  color: AppColors.inputBorder,
                  width: 1,
                ),
              ),
              child: SafeArea(
                top: false,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Login/Sign Up',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: ResponsiveHelper.sp(18),
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      Container(
                        height: 1,
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.15,
                        ),
                        color: AppColors.inputBorder,
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      CustomTextField(
                        label: 'Phone Number',
                        hintText: 'Enter Phone Number',
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: Validators.validatePhone,
                        onFieldSubmitted: (_) => _onContinue(),
                      ),
                      SizedBox(height: screenHeight * 0.025),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return PrimaryButton(
                            text: 'Continue',
                            isLoading: authProvider.isLoading,
                            onPressed: _onContinue,
                          );
                        },
                      ),
                      SizedBox(height: screenHeight * 0.015),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// OTP Bottom Sheet Widget
class OtpBottomSheet extends StatefulWidget {
  final String phoneNumber;
  final Function(bool isNewUser) onSuccess;

  const OtpBottomSheet({
    super.key,
    required this.phoneNumber,
    required this.onSuccess,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (_) => FocusNode(),
  );

  int _resendTimer = 0;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _otp => _otpControllers.map((c) => c.text).join();

  Future<void> _onLogin() async {
    if (_otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete OTP'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(_otp);

    if (success && mounted) {
      widget.onSuccess(authProvider.isNewUser);
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
      _clearOtpFields();
    }
  }

  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  Future<void> _onResendOtp() async {
    if (!_canResend) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendOtp(widget.phoneNumber);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      _startResendTimer();
    } else if (mounted && authProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _resendTimer = 30;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) {
          _canResend = true;
        }
      });
      return _resendTimer > 0;
    });
  }

  void _onOtpChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenHeight = ResponsiveHelper.screenHeight;
    final screenWidth = ResponsiveHelper.screenWidth;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomPadding),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.025,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(screenWidth * 0.06),
        ),
        border: Border.all(
          color: AppColors.inputBorder,
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: screenWidth * 0.1,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: screenHeight * 0.025),

            // Title
            Text(
              'Enter OTP',
              style: AppTextStyles.heading2.copyWith(
                fontSize: ResponsiveHelper.sp(22),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Phone number info
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.05,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cardBackground,
                    AppColors.primaryOlive.withOpacity(0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
              ),
              child: Column(
                children: [
                  Text(
                    "We've sent a verification code to",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: ResponsiveHelper.sp(14),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.005),
                  Text(
                    widget.phoneNumber,
                    style: AppTextStyles.heading4.copyWith(
                      fontSize: ResponsiveHelper.sp(16),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.025),

            // Verification Code Label
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Verification Code',
                style: AppTextStyles.inputLabel.copyWith(
                  color: AppColors.primaryGreen,
                  fontSize: ResponsiveHelper.sp(14),
                ),
              ),
            ),
            SizedBox(height: screenHeight * 0.012),

            // OTP Input Fields with proper backspace handling
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.03,
                vertical: screenHeight * 0.015,
              ),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(
                  color: AppColors.inputBorder,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: screenWidth * 0.1,
                    child: RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: (event) {
                        if (event is RawKeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.backspace) {
                          if (_otpControllers[index].text.isEmpty &&
                              index > 0) {
                            _otpControllers[index - 1].clear();
                            _focusNodes[index - 1].requestFocus();
                            setState(() {});
                          }
                        }
                      },
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: AppTextStyles.heading3.copyWith(
                          letterSpacing: 2,
                          fontSize: ResponsiveHelper.sp(20),
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          filled: false,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onOtpChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: screenHeight * 0.02),

            // Resend OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive code? ",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: ResponsiveHelper.sp(13),
                  ),
                ),
                GestureDetector(
                  onTap: _canResend ? _onResendOtp : null,
                  child: Text(
                    _canResend ? 'Resend OTP' : 'Resend in ${_resendTimer}s',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _canResend
                          ? AppColors.primaryGreen
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: ResponsiveHelper.sp(13),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.03),

            // Login Button
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return PrimaryButton(
                  text: 'Login',
                  isLoading: authProvider.isLoading,
                  isEnabled: _otp.length == 6,
                  onPressed: _onLogin,
                );
              },
            ),
            SizedBox(height: screenHeight * 0.01),
          ],
        ),
      ),
    );
  }
}

/// Background image widget that tries multiple paths
class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage();

  // List of possible background image paths to try
  static const List<String> _backgroundPaths = [
    'assets/images/login_bg.png',
    'assets/images/login_bg.jpg',
    'assets/images/login_bg.jpeg',
    // Reuse the vendor "main icon" SVG for any non-login background.
    'assets/images/bms-n.png',
    'assets/login_bg.png',
    'assets/login_bg.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _findValidAsset(context),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.asset(
            snapshot.data!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          );
        }
        // Fallback gradient
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cardBackground.withOpacity(0.5),
                AppColors.background,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.fitness_center,
              size: MediaQuery.of(context).size.width * 0.25,
              color: AppColors.textHint.withOpacity(0.3),
            ),
          ),
        );
      },
    );
  }

  Future<String?> _findValidAsset(BuildContext context) async {
    for (final path in _backgroundPaths) {
      try {
        await DefaultAssetBundle.of(context).load(path);
        debugPrint('✅ Found background image: $path');
        return path;
      } catch (e) {
        debugPrint('❌ Not found: $path');
      }
    }
    debugPrint('⚠️ No background image found. Tried: $_backgroundPaths');
    return null;
  }
}

/// Logo image widget that tries multiple paths
class _LogoImage extends StatelessWidget {
  final double height;

  const _LogoImage({required this.height});

  // List of possible logo paths to try
  static const List<String> _logoPaths = [
    'assets/images/bms-n.png',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return FutureBuilder<String?>(
      future: _findValidAsset(context),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          final path = snapshot.data!;
          if (path.endsWith('.svg')) {
            return SvgPicture.asset(
              path,
              height: height,
              fit: BoxFit.contain,
            );
          } else {
            return Image.asset(
              path,
              height: height,
              fit: BoxFit.contain,
            );
          }
        }
        // Fallback logo
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
              ),
              child: Icon(
                Icons.fitness_center,
                color: AppColors.buttonText,
                size: screenWidth * 0.05,
              ),
            ),
            SizedBox(width: screenWidth * 0.02),
            Text(
              'BookMyFit',
              style: AppTextStyles.heading2.copyWith(
                color: AppColors.primaryGreen,
                fontSize: screenWidth * 0.065,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _findValidAsset(BuildContext context) async {
    for (final path in _logoPaths) {
      try {
        await DefaultAssetBundle.of(context).load(path);
        debugPrint('✅ Found logo image: $path');
        return path;
      } catch (e) {
        debugPrint('❌ Not found: $path');
      }
    }
    debugPrint('⚠️ No logo image found. Tried: $_logoPaths');
    return null;
  }
}
