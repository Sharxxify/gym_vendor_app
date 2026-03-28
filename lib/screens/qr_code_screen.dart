import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import '../core/utils/web_downloader.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../core/utils/utils.dart';
import '../providers/home_provider.dart';

class QRCodeScreen extends StatefulWidget {
  const QRCodeScreen({super.key});

  @override
  State<QRCodeScreen> createState() => _QRCodeScreenState();
}

class _QRCodeScreenState extends State<QRCodeScreen> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isDownloading = false;

  /// Download QR code to gallery/browser
  Future<void> _downloadQRCode(String? gymId) async {
    if (gymId == null) {
      _showSnackbar('Unable to generate QR code. Gym ID not found.',
          isError: true);
      return;
    }

    setState(() => _isDownloading = true);

    try {
      // Small delay to ensure any layout/spinner state is settled
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        _showSnackbar('Internal error: Capture area not found.', isError: true);
        setState(() => _isDownloading = false);
        return;
      }

      // Convert boundary to image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        _showSnackbar('Failed to process image data.', isError: true);
        setState(() => _isDownloading = false);
        return;
      }

      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final fileName = 'BookMyFit_QR_${gymId.substring(0, 5)}';

      if (kIsWeb) {
        // WEB DOWNLOAD LOGIC
        downloadWeb(pngBytes, fileName);
        _showSnackbar('QR Poster downloaded to your browser!', isError: false);
      } else {
        // MOBILE DOWNLOAD LOGIC (gal)
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          final granted = await Gal.requestAccess();
          if (!granted) {
            _showSnackbar('Gallery permission denied.', isError: true);
            setState(() => _isDownloading = false);
            return;
          }
        }

        final tempDir = await getTemporaryDirectory();
        final String filePath =
            '${tempDir.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(pngBytes);

        await Gal.putImage(file.path, album: 'BookMyFit');

        if (await file.exists()) {
          await file.delete();
        }
        _showSnackbar('QR Poster saved to gallery!', isError: false);
      }
    } catch (e) {
      debugPrint('❌ QR Download Error: $e');
      _showSnackbar('Download failed: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ResponsiveHelper.init(context);
    final screenWidth = ResponsiveHelper.screenWidth;
    final screenHeight = ResponsiveHelper.screenHeight;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Gym QR Code'),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, child) {
          final gymId = homeProvider.gymProfileData?['gym_id']?.toString();
          final gymName = homeProvider.gymName ?? 'BookMyFit Partner';

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.02),
                  // The Poster to capture (Dark Theme)
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      width: screenWidth * 0.85,
                      padding: EdgeInsets.all(screenWidth * 0.06),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212), // Deep Black/Charcoal
                        borderRadius: BorderRadius.circular(screenWidth * 0.04),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Branding
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.fitness_center,
                                  color: AppColors.primaryGreen,
                                  size: screenWidth * 0.06),
                              const SizedBox(width: 8),
                              Text(
                                'BookMyFit.in',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.primaryGreen,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.03),
                          // QR Code Container (Keep White for scannability)
                          Container(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(screenWidth * 0.04),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryGreen.withOpacity(0.2),
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: gymId != null
                                ? QrImageView(
                                    data: gymId,
                                    version: QrVersions.auto,
                                    size: screenWidth * 0.5,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Colors.black,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Colors.black,
                                    ),
                                  )
                                : Icon(Icons.qr_code_2,
                                    size: screenWidth * 0.5,
                                    color: Colors.grey),
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          // "Scan to Check-in"
                          Text(
                            'SCAN TO CHECK-IN',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Gym Name (Branded)
                          Text(
                            gymName.toUpperCase(),
                            style: AppTextStyles.heading4.copyWith(
                              color: AppColors.primaryGreen,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          // Footer tag
                          Text(
                            'OFFICIAL PARTNER',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white38,
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.06),
                  Text(
                    'Display this QR code at your gym entrance\nfor customers to check-in easily.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  // Download Button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                    child: PrimaryButton(
                      text: 'Download Poster',
                      isLoading: _isDownloading,
                      isEnabled: gymId != null && !_isDownloading,
                      onPressed: () => _downloadQRCode(gymId),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
