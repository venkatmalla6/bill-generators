// lib/core/constants/app_constants.dart
// Application-wide constants for the AKTS Receipt Management System

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'AKTS Receipt Management';
  static const String organizationNameTelugu = 'అను కల్పాక్కం తెలుగు సమితి';
  static const String organizationNameEnglish = 'ANU KALPAKKAM TELUGU SAMITHI';
  static const String organizationShort = 'AKTS';
  static const String receiptTitleTelugu = 'వార్షిక సభ్యత్వ చెల్లింపు రసీదు';
  static const String receiptTitleEnglish = 'Annual Membership Payment Slip';
  static const String receiptTitleFull =
      'వార్షిక సభ్యత్వ చెల్లింపు రసీదు\n(Annual Membership Payment Slip)';

  // Firestore Collection Names
  static const String usersCollection = 'users';
  static const String receiptsCollection = 'receipts';
  static const String paymentsDoneCollection = 'payments_done';
  static const String settingsCollection = 'settings';
  static const String countersCollection = 'counters';
  static const String applicationSettingsDoc = 'application';

  // Receipt Number Format
  static const String receiptNumberPrefix = 'AKTS';
  static const int receiptNumberPadding = 3;

  // Receipt Status Values
  static const String statusValid = 'valid';
  static const String statusRevoked = 'revoked';
  static const String statusCancelled = 'cancelled';
  static const String statusDeleted = 'deleted';

  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleStaff = 'staff';

  // Payment Modes
  static const List<String> paymentModes = [
    'Cash',
    'Online',
    'UPI',
    'Bank Transfer',
    'Other',
  ];

  // Payment modes that require transaction ID
  static const List<String> paymentModesRequiringTransactionId = [
    'Online',
    'UPI',
    'Bank Transfer',
  ];

  // Verification URL path
  static const String verificationPath = '/verify/';

  // Bulk Print
  static const int receiptsPerA4Page = 10;
  static const int receiptsPerRow = 2;
  static const int rowsPerPage = 5;

  // Default verification domain (fallback)
  static const String defaultVerificationDomain = 'https://akts.org.in';

  // Sample Membership Years
  static List<String> get membershipYears {
    final currentYear = DateTime.now().year;
    return List.generate(5, (i) => (currentYear - 2 + i).toString());
  }

  // Date Format
  static const String displayDateFormat = 'dd-MM-yyyy';
  static const String storageDateFormat = 'yyyy-MM-dd';

  // Minimum amount
  static const double minimumAmount = 1.0;

  // Firestore field names
  static const String fieldReceiptNumber = 'receiptNumber';
  static const String fieldDate = 'date';
  static const String fieldMemberName = 'memberName';
  static const String fieldAktsNumber = 'aktsNumber';
  static const String fieldMembershipYear = 'membershipYear';
  static const String fieldAmount = 'amount';
  static const String fieldAmountInWords = 'amountInWords';
  static const String fieldPaymentMode = 'paymentMode';
  static const String fieldTransactionId = 'transactionId';
  static const String fieldRemarks = 'remarks';
  static const String fieldVerificationId = 'verificationId';
  static const String fieldVerificationUrl = 'verificationUrl';
  static const String fieldStatus = 'status';
  static const String fieldCreatedBy = 'createdBy';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldPdfUrl = 'pdfUrl';
  static const String fieldRole = 'role';
  static const String fieldCount = 'count';
}
