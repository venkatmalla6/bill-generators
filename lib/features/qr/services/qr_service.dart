// lib/features/qr/services/qr_service.dart
// QR code parsing and verification URL handling

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';

class QrService {
  QrService._();

  /// Parse a scanned QR code string and extract verificationId
  /// Returns null if the QR code is not a valid AKTS receipt QR
  static String? extractVerificationId(String qrData) {
    try {
      // Try to parse as URL
      final uri = Uri.tryParse(qrData);
      if (uri == null) return null;

      // Check if path contains /verify/
      final path = uri.path;
      if (!path.contains(AppConstants.verificationPath)) return null;

      final verificationId = path
          .split(AppConstants.verificationPath)
          .last
          .trim();

      if (verificationId.isEmpty) return null;

      // Basic UUID format validation
      final uuidPattern = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      if (!uuidPattern.hasMatch(verificationId)) return null;

      return verificationId;
    } catch (_) {
      return null;
    }
  }

  /// Generate QR data string for a given verification ID
  static String generateQrData(String verificationId) {
    return AppConfig.buildVerificationUrl(verificationId);
  }

  /// Check if a QR scan result is a valid AKTS receipt QR code
  static bool isValidAktsQr(String qrData) {
    return extractVerificationId(qrData) != null;
  }
}
