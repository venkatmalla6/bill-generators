// lib/core/services/cloudinary_service.dart
// Cloudinary upload service for PDFs and images

import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../errors/app_exceptions.dart';

class CloudinaryService {
  CloudinaryService._();

  static final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 60),
  ));

  /// Upload PDF bytes to Cloudinary
  /// Returns the secure URL of the uploaded file
  static Future<String> uploadPdfBytes(
    Uint8List bytes, {
    required String fileName,
    String folder = 'akts_receipts',
  }) async {
    if (AppConfig.cloudinaryCloudName.isEmpty ||
        AppConfig.cloudinaryUploadPreset.isEmpty) {
      throw CloudinaryException.notConfigured();
    }

    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
        'upload_preset': AppConfig.cloudinaryUploadPreset,
        'folder': folder,
        'resource_type': 'raw',
        'public_id': fileName.replaceAll('.pdf', ''),
      });

      final response = await _dio.post(
        AppConfig.cloudinaryRawUploadUrl,
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['secure_url'] as String? ?? '';
      } else {
        throw CloudinaryException.uploadFailed();
      }
    } on DioException catch (e) {
      throw CloudinaryException(
        message: 'Upload failed: ${e.message}',
        code: 'upload-failed',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw CloudinaryException.uploadFailed();
    }
  }

  /// Upload an image file to Cloudinary
  static Future<String> uploadImageFile(
    File file, {
    required String fileName,
    String folder = 'akts_assets',
  }) async {
    if (AppConfig.cloudinaryCloudName.isEmpty ||
        AppConfig.cloudinaryUploadPreset.isEmpty) {
      throw CloudinaryException.notConfigured();
    }

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'upload_preset': AppConfig.cloudinaryUploadPreset,
        'folder': folder,
      });

      final response = await _dio.post(
        AppConfig.cloudinaryUploadUrl,
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['secure_url'] as String? ?? '';
      } else {
        throw CloudinaryException.uploadFailed();
      }
    } on DioException catch (e) {
      throw CloudinaryException(
        message: 'Upload failed: ${e.message}',
        code: 'upload-failed',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw CloudinaryException.uploadFailed();
    }
  }

  /// Check if Cloudinary is configured
  static bool get isConfigured =>
      AppConfig.cloudinaryCloudName.isNotEmpty &&
      AppConfig.cloudinaryUploadPreset.isNotEmpty;
}
