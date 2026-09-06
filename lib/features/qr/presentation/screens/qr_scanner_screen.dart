// lib/features/qr/presentation/screens/qr_scanner_screen.dart
// QR scanner screen using mobile_scanner package

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/qr_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';

class QrScannerScreen extends ConsumerStatefulWidget {
  const QrScannerScreen({super.key});

  @override
  ConsumerState<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  MobileScannerController? _scannerController;
  bool _hasScanned = false;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;

      final verificationId = QrService.extractVerificationId(rawValue);
      if (verificationId != null) {
        setState(() => _hasScanned = true);
        _scannerController?.stop();

        // Navigate to verification screen
        if (mounted) {
          context.push(AppRoutes.verifyPath(verificationId));
        }
        return;
      }
    }

    // Invalid QR — show brief feedback
    if (!_hasScanned) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Invalid QR code. This is not an AKTS receipt QR code.'),
          backgroundColor: AppColors.warning,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _toggleTorch() {
    setState(() => _torchEnabled = !_torchEnabled);
    _scannerController?.toggleTorch();
  }

  void _resetScanner() {
    setState(() => _hasScanned = false);
    _scannerController?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Receipt QR'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _torchEnabled ? Icons.flash_on : Icons.flash_off,
              color: _torchEnabled ? AppColors.gold : Colors.white,
            ),
            onPressed: _toggleTorch,
            tooltip: 'Toggle flashlight',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: _scannerController!,
            onDetect: _onDetect,
            errorBuilder: (context, error, child) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Camera not available.\n${error.errorDetails?.message ?? 'Unknown error'}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),

          // Overlay with scan frame
          _buildScanOverlay(),

          // Instructions at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildInstructionsPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final scanAreaSize = size.width * 0.7;
        final centerX = (size.width - scanAreaSize) / 2;
        final centerY = (size.height - scanAreaSize) / 2 - 60;

        return Stack(
          children: [
            // Semi-transparent overlay
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: centerX,
                    top: centerY,
                    child: Container(
                      width: scanAreaSize,
                      height: scanAreaSize,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scan frame corners
            Positioned(
              left: centerX,
              top: centerY,
              child: _buildScanFrame(scanAreaSize),
            ),

            // Scan indicator
            Positioned(
              left: centerX + scanAreaSize / 2 - 60,
              top: centerY + scanAreaSize + 16,
              child: Text(
                'Point camera at QR code',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScanFrame(double size) {
    const cornerSize = 24.0;
    const cornerWidth = 3.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Top-left
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: cornerSize,
              height: cornerWidth,
              color: AppColors.gold,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              width: cornerWidth,
              height: cornerSize,
              color: AppColors.gold,
            ),
          ),
          // Top-right
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: cornerSize,
              height: cornerWidth,
              color: AppColors.gold,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: cornerWidth,
              height: cornerSize,
              color: AppColors.gold,
            ),
          ),
          // Bottom-left
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: cornerSize,
              height: cornerWidth,
              color: AppColors.gold,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: cornerWidth,
              height: cornerSize,
              color: AppColors.gold,
            ),
          ),
          // Bottom-right
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: cornerSize,
              height: cornerWidth,
              color: AppColors.gold,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: cornerWidth,
              height: cornerSize,
              color: AppColors.gold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.9),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'AKTS Receipt Verification',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Scan the QR code on any AKTS receipt to verify its authenticity',
            style: GoogleFonts.lato(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          if (_hasScanned) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetScanner,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Scan Another'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navyPrimary,
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
