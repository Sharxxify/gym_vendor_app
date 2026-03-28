import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'providers/providers.dart';
import 'screens/login_screen.dart';
import 'screens/kyc_verification_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF05110B),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const BookMyFitApp());
}

class BookMyFitApp extends StatelessWidget {
  const BookMyFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => KycProvider()),
        ChangeNotifierProvider(create: (_) => BusinessProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        title: 'BookMyFit Vendor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Show splash for at least 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Check if user is authenticated
    final isAuthenticated = await ApiClient.isAuthenticated();

    if (!mounted) return;

    if (isAuthenticated) {
      // Check if user is new (needs to complete profile setup)
      final isNewUser = await ApiClient.getIsNewUser();
      final hasGymId = await ApiClient.getGymId();

      if (!mounted) return;

      debugPrint('📱 App reload - Authenticated user');
      debugPrint('🆕 Is New User: $isNewUser');
      debugPrint('🏢 Has Gym ID: $hasGymId');

      if (isNewUser == true) {
        debugPrint('📱 Going to KYC verification screen (new user)');
        // New user - go to KYC verification first
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const KycVerificationScreen()),
        );
      } else if (hasGymId == null) {
        debugPrint('📱 Going to login screen (no gym ID)');
        // User has token but no gym ID - go to login to re-authenticate
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        debugPrint('📱 Going to home screen (existing user with gym)');
        // Existing user with gym - go to home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      debugPrint('📱 App reload - Not authenticated, going to login');
      // Not authenticated - go to login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05110B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFA1E433),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                'assets/images/bms.png',
                width: 48,
                height: 48,
                color: const Color(0xFF05110B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'BookMyFit',
              style: TextStyle(
                color: Color(0xFFA1E433),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gym Management Made Easy',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA1E433)),
            ),
          ],
        ),
      ),
    );
  }
}
