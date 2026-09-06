// lib/core/config/app_config.dart
// Application configuration loaded from environment variables

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';

class AppConfig {
  AppConfig._();

  /// Call during app startup before accessing any env values
  static void initialize() {
    // dotenv is already loaded in main.dart before this is called.
    // This method is a hook for any future initialization logic.
  }

  static String get cloudinaryCloudName =>
      dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';

  static String get cloudinaryUploadPreset =>
      dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? 'akts_receipts';

  static String get cloudinaryApiKey =>
      dotenv.env['CLOUDINARY_API_KEY'] ?? '';

  static String get cloudinaryApiSecret =>
      dotenv.env['CLOUDINARY_API_SECRET'] ?? '';

  static String get verificationDomain =>
      dotenv.env['VERIFICATION_DOMAIN'] ?? AppConstants.defaultVerificationDomain;

  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  static bool get isProduction => appEnv == 'production';

  static bool get isDevelopment => appEnv == 'development';

  /// Build the full verification URL for a given verificationId
  static String buildVerificationUrl(String verificationId) {
    final domain = verificationDomain.trimRight().replaceAll(RegExp(r'/$'), '');
    return '$domain${AppConstants.verificationPath}$verificationId';
  }

  /// Cloudinary upload URL
  static String get cloudinaryUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/upload';

  /// Cloudinary upload URL for raw files
  static String get cloudinaryRawUploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/raw/upload';
}
