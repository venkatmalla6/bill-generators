// lib/features/receipts/data/repositories/receipt_repository_impl.dart
// Firestore receipt repository implementation with safe sequential numbering

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../models/receipt_model.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';

class ReceiptRepositoryImpl implements ReceiptRepository {
  final FirebaseFirestore _firestore;

  ReceiptRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _receiptsRef =>
      _firestore.collection(AppConstants.receiptsCollection);

  CollectionReference<Map<String, dynamic>> get _countersRef =>
      _firestore.collection(AppConstants.countersCollection);

  // ─── Create ──────────────────────────────────────────────────────────────

  @override
  Future<ReceiptModel> createReceipt(ReceiptModel receipt) async {
    try {
      final docRef = _receiptsRef.doc();
      final receiptWithId = receipt.copyWith(id: docRef.id);
      await docRef.set(receiptWithId.toFirestore());
      return receiptWithId;
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e.code, e.message ?? 'Create failed');
    } catch (e) {
      if (e is AppException) rethrow;
      throw FirestoreException.unknown(e.toString());
    }
  }

  // ─── Read ────────────────────────────────────────────────────────────────

  @override
  Future<ReceiptModel?> getReceiptById(String id) async {
    try {
      final doc = await _receiptsRef.doc(id).get();
      if (!doc.exists) return null;
      return ReceiptModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e.code, e.message ?? 'Read failed');
    }
  }

  @override
  Future<ReceiptModel?> getReceiptByVerificationId(
      String verificationId) async {
    try {
      final query = await _receiptsRef
          .where(AppConstants.fieldVerificationId, isEqualTo: verificationId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return ReceiptModel.fromFirestore(query.docs.first);
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e.code, e.message ?? 'Verify query failed');
    }
  }

  @override
  Stream<List<ReceiptModel>> getReceiptsStream({
    String? userId,
    bool isAdmin = false,
  }) {
    Query<Map<String, dynamic>> query = _receiptsRef;

    if (!isAdmin && userId != null) {
      query = query.where(AppConstants.fieldCreatedBy, isEqualTo: userId);
    } else {
      query = query.orderBy(AppConstants.fieldCreatedAt, descending: true);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(ReceiptModel.fromFirestore)
          .where((r) => !r.isDeleted)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  @override
  Future<List<ReceiptModel>> getReceiptsList({
    String? userId,
    bool isAdmin = false,
    Map<String, dynamic>? filters,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _receiptsRef;

      if (!isAdmin && userId != null) {
        query = query.where(AppConstants.fieldCreatedBy, isEqualTo: userId);
      } else {
        query = query.orderBy(AppConstants.fieldCreatedAt, descending: true);
      }

      final snapshot = await query.limit(500).get();
      var receipts = snapshot.docs
          .map(ReceiptModel.fromFirestore)
          .where((r) => !r.isDeleted)
          .toList();

      // Client-side filtering to eliminate composite index requirement
      if (filters != null) {
        if (filters['status'] != null) {
          receipts =
              receipts.where((r) => r.status == filters['status']).toList();
        }
        if (filters['paymentMode'] != null) {
          receipts = receipts
              .where((r) => r.paymentMode == filters['paymentMode'])
              .toList();
        }
        if (filters['membershipYear'] != null) {
          receipts = receipts
              .where((r) => r.membershipYear == filters['membershipYear'])
              .toList();
        }
        if (filters['startDate'] != null && filters['endDate'] != null) {
          final start = filters['startDate'] as DateTime;
          final end = filters['endDate'] as DateTime;
          receipts = receipts.where((r) {
            return (r.date.isAfter(start) || r.date.isAtSameMomentAs(start)) &&
                (r.date.isBefore(end) || r.date.isAtSameMomentAs(end));
          }).toList();
        }
      }

      receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return receipts;
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e.code, e.message ?? 'List failed');
    }
  }

  @override
  Future<List<ReceiptModel>> searchReceipts({
    required String query,
    String? userId,
    bool isAdmin = false,
  }) async {
    // Firestore doesn't support full-text search natively.
    // We fetch all accessible receipts and filter client-side.
    // For production, consider Algolia or Firestore with composite indexes.
    try {
      final all = await getReceiptsList(userId: userId, isAdmin: isAdmin);
      final q = query.toLowerCase().trim();
      return all.where((r) {
        return r.receiptNumber.toLowerCase().contains(q) ||
            r.memberName.toLowerCase().contains(q) ||
            r.aktsNumber.toLowerCase().contains(q) ||
            (r.transactionId?.toLowerCase().contains(q) ?? false);
      }).toList();
    } catch (e) {
      if (e is AppException) rethrow;
      throw FirestoreException.unknown(e.toString());
    }
  }

  // ─── Update ──────────────────────────────────────────────────────────────

  @override
  Future<ReceiptModel> updateReceipt(
      String id, Map<String, dynamic> updates) async {
    try {
      updates[AppConstants.fieldUpdatedAt] = FieldValue.serverTimestamp();
      await _receiptsRef.doc(id).update(updates);
      final updated = await getReceiptById(id);
      if (updated == null) throw ReceiptException.notFound();
      return updated;
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e.code, e.message ?? 'Update failed');
    }
  }

  @override
  Future<void> revokeReceipt(String id, String revokedBy) async {
    try {
      final receipt = await getReceiptById(id);
      if (receipt == null) throw ReceiptException.notFound();
      if (receipt.isRevoked) throw ReceiptException.alreadyRevoked();

      await _receiptsRef.doc(id).update({
        AppConstants.fieldStatus: AppConstants.statusRevoked,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        'revokedBy': revokedBy,
        'revokedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e.code, e.message ?? 'Revoke failed');
    }
  }

  @override
  Future<void> deleteReceipt(String id) async {
    try {
      // 1. Try physical deletion first
      await _receiptsRef.doc(id).delete();
    } on FirebaseException catch (e) {
      // 2. If physical deletion is blocked by Firebase server security rules,
      // fallback to soft deletion (status = 'deleted')
      try {
        await _receiptsRef.doc(id).update({
          AppConstants.fieldStatus: AppConstants.statusDeleted,
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      } catch (fallbackError) {
        throw mapFirestoreError(e.code, e.message ?? 'Delete failed');
      }
    } catch (e) {
      if (e is AppException) rethrow;
      throw FirestoreException.unknown(e.toString());
    }
  }

  @override
  Future<void> updatePdfUrl(String receiptId, String pdfUrl) async {
    try {
      await _receiptsRef.doc(receiptId).update({
        AppConstants.fieldPdfUrl: pdfUrl,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e.code, e.message ?? 'PDF URL update failed');
    }
  }

  // ─── Receipt Number Generation ───────────────────────────────────────────

  @override
  Future<String> generateReceiptNumber() async {
    final year = DateTime.now().year.toString();
    final counterRef = _countersRef.doc(year);

    try {
      return await _firestore.runTransaction<String>((transaction) async {
        final counterDoc = await transaction.get(counterRef);
        int currentCount = 0;

        if (counterDoc.exists) {
          currentCount = (counterDoc.data()?[AppConstants.fieldCount] as int?) ?? 0;
        }

        final newCount = currentCount + 1;

        transaction.set(counterRef, {
          AppConstants.fieldCount: newCount,
          'year': year,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        final paddedCount = newCount
            .toString()
            .padLeft(AppConstants.receiptNumberPadding, '0');
        return '${AppConstants.receiptNumberPrefix}/$year/$paddedCount';
      });
    } on FirebaseException catch (e) {
      throw mapFirestoreError(e.code, e.message ?? 'Number gen failed');
    } catch (e) {
      throw ReceiptException.numberGenerationFailed();
    }
  }

  // ─── Dashboard Statistics ────────────────────────────────────────────────

  @override
  Future<Map<String, dynamic>> getDashboardStats({
    required String userId,
    required bool isAdmin,
  }) async {
    try {
      final allReceipts = await getReceiptsList(
        userId: userId,
        isAdmin: isAdmin,
      );

      final todayReceipts = allReceipts
          .where((r) => r.isValid && DateFormatter.isToday(r.date))
          .toList();

      final monthReceipts = allReceipts
          .where((r) => r.isValid && DateFormatter.isCurrentMonth(r.date))
          .toList();

      final validReceipts = allReceipts.where((r) => r.isValid).toList();

      final totalAmount = validReceipts.fold<double>(
          0, (sum, r) => sum + r.amount);
      final todayAmount = todayReceipts.fold<double>(
          0, (sum, r) => sum + r.amount);
      final monthAmount = monthReceipts.fold<double>(
          0, (sum, r) => sum + r.amount);

      return {
        'totalReceipts': allReceipts.length,
        'validReceipts': validReceipts.length,
        'revokedReceipts': allReceipts.where((r) => r.isRevoked).length,
        'totalAmount': totalAmount,
        'todayReceipts': todayReceipts.length,
        'todayAmount': todayAmount,
        'monthReceipts': monthReceipts.length,
        'monthAmount': monthAmount,
      };
    } catch (e) {
      if (e is AppException) rethrow;
      throw FirestoreException.unknown(e.toString());
    }
  }
}
