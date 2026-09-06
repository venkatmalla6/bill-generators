// lib/core/errors/app_exceptions.dart
// Custom exception types for the AKTS application

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException({
    required this.message,
    this.code,
    this.details,
  });

  @override
  String toString() => 'AppException[$code]: $message';
}

/// Firebase Authentication exceptions
class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.details,
  });

  factory AuthException.invalidCredentials() => const AuthException(
        message: 'Invalid email or password. Please check and try again.',
        code: 'invalid-credentials',
      );

  factory AuthException.userNotFound() => const AuthException(
        message: 'No account found with this email address.',
        code: 'user-not-found',
      );

  factory AuthException.emailAlreadyInUse() => const AuthException(
        message: 'An account already exists with this email address.',
        code: 'email-already-in-use',
      );

  factory AuthException.weakPassword() => const AuthException(
        message: 'Password is too weak. Please use at least 8 characters.',
        code: 'weak-password',
      );

  factory AuthException.networkError() => const AuthException(
        message: 'Network error. Please check your connection and try again.',
        code: 'network-error',
      );

  factory AuthException.sessionExpired() => const AuthException(
        message: 'Your session has expired. Please log in again.',
        code: 'session-expired',
      );

  factory AuthException.unknown(String message) =>
      AuthException(message: message, code: 'unknown');
}

/// Firestore database exceptions
class FirestoreException extends AppException {
  const FirestoreException({
    required super.message,
    super.code,
    super.details,
  });

  factory FirestoreException.notFound(String entity) => FirestoreException(
        message: '$entity not found.',
        code: 'not-found',
      );

  factory FirestoreException.permissionDenied() => const FirestoreException(
        message: 'You do not have permission to perform this action.',
        code: 'permission-denied',
      );

  factory FirestoreException.networkError() => const FirestoreException(
        message: 'Network error. Please check your connection.',
        code: 'network-error',
      );

  factory FirestoreException.transactionFailed() => const FirestoreException(
        message: 'Transaction failed. Please try again.',
        code: 'transaction-failed',
      );

  factory FirestoreException.unknown(String message) =>
      FirestoreException(message: message, code: 'unknown');
}

/// Receipt-specific exceptions
class ReceiptException extends AppException {
  const ReceiptException({
    required super.message,
    super.code,
    super.details,
  });

  factory ReceiptException.duplicateTransaction() => const ReceiptException(
        message: 'A receipt with this transaction ID already exists.',
        code: 'duplicate-transaction',
      );

  factory ReceiptException.invalidAmount() => const ReceiptException(
        message: 'Invalid amount. Amount must be greater than zero.',
        code: 'invalid-amount',
      );

  factory ReceiptException.numberGenerationFailed() => const ReceiptException(
        message: 'Failed to generate receipt number. Please try again.',
        code: 'number-generation-failed',
      );

  factory ReceiptException.alreadyRevoked() => const ReceiptException(
        message: 'This receipt has already been revoked.',
        code: 'already-revoked',
      );

  factory ReceiptException.notFound() => const ReceiptException(
        message: 'Receipt not found. It may have been deleted or the ID is incorrect.',
        code: 'receipt-not-found',
      );

  factory ReceiptException.revoked() => const ReceiptException(
        message: 'This receipt has been revoked and is no longer valid.',
        code: 'receipt-revoked',
      );
}

/// PDF generation exceptions
class PdfException extends AppException {
  const PdfException({
    required super.message,
    super.code,
    super.details,
  });

  factory PdfException.generationFailed() => const PdfException(
        message: 'Failed to generate PDF. Please try again.',
        code: 'generation-failed',
      );

  factory PdfException.printFailed() => const PdfException(
        message: 'Failed to send to printer.',
        code: 'print-failed',
      );

  factory PdfException.shareFailed() => const PdfException(
        message: 'Failed to share PDF.',
        code: 'share-failed',
      );
}

/// Cloudinary upload exceptions
class CloudinaryException extends AppException {
  const CloudinaryException({
    required super.message,
    super.code,
    super.details,
  });

  factory CloudinaryException.uploadFailed() => const CloudinaryException(
        message: 'Failed to upload file to cloud storage.',
        code: 'upload-failed',
      );

  factory CloudinaryException.notConfigured() => const CloudinaryException(
        message: 'Cloud storage is not configured. Check your settings.',
        code: 'not-configured',
      );
}

/// QR code exceptions
class QrException extends AppException {
  const QrException({
    required super.message,
    super.code,
    super.details,
  });

  factory QrException.invalidQr() => const QrException(
        message: 'Invalid QR code. This QR code is not an AKTS receipt.',
        code: 'invalid-qr',
      );

  factory QrException.scanFailed() => const QrException(
        message: 'Failed to scan QR code. Please try again.',
        code: 'scan-failed',
      );
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.details,
  });

  factory ValidationException.requiredField(String fieldName) =>
      ValidationException(
        message: '$fieldName is required.',
        code: 'required-field',
        details: fieldName,
      );

  factory ValidationException.invalidEmail() => const ValidationException(
        message: 'Please enter a valid email address.',
        code: 'invalid-email',
      );

  factory ValidationException.invalidAmount() => const ValidationException(
        message: 'Please enter a valid amount.',
        code: 'invalid-amount',
      );
}

/// Maps Firebase error codes to friendly AppExceptions
AppException mapFirebaseAuthError(String code, String message) {
  switch (code) {
    case 'invalid-email':
    case 'invalid-credential':
    case 'wrong-password':
      return AuthException.invalidCredentials();
    case 'user-not-found':
      return AuthException.userNotFound();
    case 'email-already-in-use':
      return AuthException.emailAlreadyInUse();
    case 'weak-password':
      return AuthException.weakPassword();
    case 'network-request-failed':
      return AuthException.networkError();
    case 'user-token-expired':
    case 'requires-recent-login':
      return AuthException.sessionExpired();
    default:
      return AuthException.unknown(message);
  }
}

/// Maps Firestore error codes to friendly AppExceptions
AppException mapFirestoreError(String code, String message) {
  switch (code) {
    case 'not-found':
      return FirestoreException.notFound('Document');
    case 'permission-denied':
      return FirestoreException.permissionDenied();
    case 'unavailable':
    case 'deadline-exceeded':
      return FirestoreException.networkError();
    case 'aborted':
      return FirestoreException.transactionFailed();
    default:
      return FirestoreException.unknown(message);
  }
}
