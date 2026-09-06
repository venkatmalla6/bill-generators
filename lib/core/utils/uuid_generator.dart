// lib/core/utils/uuid_generator.dart
// Cryptographically random UUID v4 generation for receipt verification IDs

import 'package:uuid/uuid.dart';

class UuidGenerator {
  UuidGenerator._();

  static const Uuid _uuid = Uuid();

  /// Generate a cryptographically random UUID v4.
  /// Example: "1b580b7b-7352-4d9a-883f-8c418b7703e0"
  static String generate() {
    return _uuid.v4();
  }

  /// Generate a short verification code (first 8 chars of UUID)
  static String generateShort() {
    return _uuid.v4().split('-').first.toUpperCase();
  }

  /// Validate that a string is a valid UUID v4 format
  static bool isValid(String uuid) {
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(uuid);
  }
}
