// lib/features/receipts/domain/repositories/receipt_repository.dart
// Abstract receipt repository interface

import '../../data/models/receipt_model.dart';

abstract class ReceiptRepository {
  /// Create a new receipt (auto-generates receipt number)
  Future<ReceiptModel> createReceipt(ReceiptModel receipt);

  /// Get receipt by Firestore document ID
  Future<ReceiptModel?> getReceiptById(String id);

  /// Get receipt by verificationId (for QR verification)
  Future<ReceiptModel?> getReceiptByVerificationId(String verificationId);

  /// Stream of all receipts (admin) or user's receipts (staff)
  Stream<List<ReceiptModel>> getReceiptsStream({
    String? userId,
    bool isAdmin = false,
  });

  /// Get receipts for bulk operations (list, not stream)
  Future<List<ReceiptModel>> getReceiptsList({
    String? userId,
    bool isAdmin = false,
    Map<String, dynamic>? filters,
  });

  /// Search receipts by text query
  Future<List<ReceiptModel>> searchReceipts({
    required String query,
    String? userId,
    bool isAdmin = false,
  });

  /// Update an existing receipt (limited fields)
  Future<ReceiptModel> updateReceipt(
    String id,
    Map<String, dynamic> updates,
  );

  /// Revoke a receipt
  Future<void> revokeReceipt(String id, String revokedBy);

  /// Permanently delete a receipt
  Future<void> deleteReceipt(String id);

  /// Generate the next sequential receipt number safely
  Future<String> generateReceiptNumber();

  /// Update the PDF URL of a receipt
  Future<void> updatePdfUrl(String receiptId, String pdfUrl);

  /// Get dashboard statistics
  Future<Map<String, dynamic>> getDashboardStats({
    required String userId,
    required bool isAdmin,
  });
}
