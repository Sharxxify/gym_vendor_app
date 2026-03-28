import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../core/constants/constants.dart';
import '../core/widgets/widgets.dart';
import '../providers/home_provider.dart';

class AttendanceScannerScreen extends StatefulWidget {
  const AttendanceScannerScreen({super.key});

  @override
  State<AttendanceScannerScreen> createState() => _AttendanceScannerScreenState();
}

class _AttendanceScannerScreenState extends State<AttendanceScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late MobileScannerController cameraController;
  bool _isScanning = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _onQRCodeScanned(String qrCode) async {
    if (!_isScanning || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _isScanning = false;
    });

    try {
      debugPrint('📸 QR Code scanned: $qrCode');

      // Get current gym ID from HomeProvider
      final homeProvider = context.read<HomeProvider>();
      final gymId = homeProvider.gymProfileData?['business']?['id'];
      
      if (gymId == null) {
        _showErrorDialog('Gym ID not found. Please ensure gym profile is loaded.');
        return;
      }

      debugPrint('🏢 Gym ID: $gymId');

      // Use new one-time scan system
      final result = await homeProvider.markAttendance(
        qrCode: qrCode,
        gymId: gymId,
      );

      if (result['success'] == true) {
        _showSuccessDialog(result['message'] ?? 'Attendance marked successfully');
      } else {
        _showErrorDialog(result['message'] ?? 'Failed to mark attendance');
      }
    } catch (e) {
      debugPrint('❌ Error processing QR code: $e');
      _showErrorDialog('Error processing QR code: $e');
    } finally {
      setState(() {
        _isProcessing = false;
        _isScanning = true;
      });
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 24),
            SizedBox(width: 12),
            Text('Success', style: AppTextStyles.heading4),
          ],
        ),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue scanning
            },
            child: Text('Continue Scanning', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 24),
            SizedBox(width: 12),
            Text('Error', style: AppTextStyles.heading4),
          ],
        ),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Continue scanning
            },
            child: Text('Try Again', style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Scan QR Code', style: AppTextStyles.heading3),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera Preview
          Container(
            color: Colors.black,
            child: MobileScanner(
              controller: cameraController,
              fit: BoxFit.cover,
              onDetect: (barcode) {
                if (barcode.barcodes.isEmpty) {
                  debugPrint('❌ Failed to scan!');
                } else {
                  final String code = barcode.barcodes.first.rawValue ?? '';
                  if (code.isNotEmpty) {
                    debugPrint('✅ Barcode found! $code');
                    _onQRCodeScanned(code);
                  }
                }
              },
            ),
          ),
          
          // Overlay Frame
          _buildScanOverlay(),
          
          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Scan Customer QR Code',
                  style: AppTextStyles.heading3.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Align the QR code within the frame',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Controls
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Flash Toggle
                IconButton(
                  icon: Icon(
                    Icons.flash_off,
                    color: Colors.white,
                    size: 28,
                  ),
                  onPressed: () {
                    // Flash toggle functionality can be added here if needed
                  },
                ),
                
                SizedBox(width: 20),
                
                // Close Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close Scanner',
                    style: AppTextStyles.labelMedium.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          
          // Processing Overlay
          if (_isProcessing)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.primaryGreen),
                      SizedBox(height: 16),
                      Text(
                        'Processing...',
                        style: AppTextStyles.heading4.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return Container(
      color: Colors.transparent,
      child: CustomPaint(
        painter: _ScanOverlayPainter(),
        child: Container(),
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // Draw dark overlay around the scan area
    canvas.drawRect(Rect.fromLTRB(0, 0, size.width, size.height), paint);

    // Clear center area for scanning
    final centerSize = size.width * 0.7;
    final left = (size.width - centerSize) / 2;
    final top = (size.height - centerSize) / 2;
    final rect = Rect.fromLTWH(left, top, centerSize, centerSize);

    // Draw clear area
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRect(rect, clearPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(rect, borderPaint);

    // Draw corners
    final cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Top-left corner
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerSize),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(left + centerSize - cornerSize, top),
      Offset(left + centerSize, top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + centerSize, top),
      Offset(left + centerSize, top + cornerSize),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + centerSize - cornerSize),
      Offset(left, top + centerSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left, top + centerSize),
      Offset(left + cornerSize, top + centerSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(left + centerSize - cornerSize, top + centerSize),
      Offset(left + centerSize, top + centerSize),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(left + centerSize, top + centerSize),
      Offset(left + centerSize, top + centerSize - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}