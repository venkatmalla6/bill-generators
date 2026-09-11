// lib/core/utils/image_picker_helper.dart
// Helper utility to pick bill screenshots/photos from gallery or camera

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class PickedImageData {
  final String name;
  final Uint8List bytes;
  final String base64String;

  PickedImageData({
    required this.name,
    required this.bytes,
    required this.base64String,
  });
}

class ImagePickerHelper {
  ImagePickerHelper._();

  static final ImagePicker _picker = ImagePicker();

  /// Pick a single photo from Camera
  static Future<PickedImageData?> pickFromCamera() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 80,
      );
      if (file == null) return null;

      final bytes = await file.readAsBytes();
      final b64 = base64Encode(bytes);
      return PickedImageData(
        name: file.name,
        bytes: bytes,
        base64String: b64,
      );
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }

  /// Pick one or more photos/screenshots from Gallery
  static Future<List<PickedImageData>> pickFromGallery({bool allowMultiple = true}) async {
    try {
      if (allowMultiple) {
        final List<XFile> files = await _picker.pickMultiImage(
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 80,
        );
        if (files.isEmpty) return [];

        final result = <PickedImageData>[];
        for (final file in files) {
          final bytes = await file.readAsBytes();
          final b64 = base64Encode(bytes);
          result.add(PickedImageData(
            name: file.name,
            bytes: bytes,
            base64String: b64,
          ));
        }
        return result;
      } else {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1280,
          maxHeight: 1280,
          imageQuality: 80,
        );
        if (file == null) return [];

        final bytes = await file.readAsBytes();
        final b64 = base64Encode(bytes);
        return [
          PickedImageData(
            name: file.name,
            bytes: bytes,
            base64String: b64,
          )
        ];
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return [];
    }
  }
}
