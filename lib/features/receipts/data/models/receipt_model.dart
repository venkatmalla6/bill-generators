// lib/features/receipts/data/models/receipt_model.dart
// Complete data model for AKTS receipts

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

class ReceiptModel {
  final String id;
  final String receiptNumber;
  final DateTime date;
  final String memberName;
  final String aktsNumber;
  final String membershipYear;
  final double amount;
  final String amountInWords;
  final String paymentMode;
  final String? transactionId;
  final String? remarks;
  final String verificationId;
  final String verificationUrl;
  final String status; // valid | revoked | cancelled
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? pdfUrl;

  const ReceiptModel({
    required this.id,
    required this.receiptNumber,
    required this.date,
    required this.memberName,
    required this.aktsNumber,
    required this.membershipYear,
    required this.amount,
    required this.amountInWords,
    required this.paymentMode,
    this.transactionId,
    this.remarks,
    required this.verificationId,
    required this.verificationUrl,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.pdfUrl,
  });

  bool get isValid => status == AppConstants.statusValid;
  bool get isRevoked => status == AppConstants.statusRevoked;
  bool get isCancelled => status == AppConstants.statusCancelled;
  bool get isDeleted => status == AppConstants.statusDeleted;

  /// Create a ReceiptModel from a Firestore document
  factory ReceiptModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReceiptModel(
      id: doc.id,
      receiptNumber: data[AppConstants.fieldReceiptNumber] as String? ?? '',
      date: (data[AppConstants.fieldDate] as Timestamp?)?.toDate() ??
          DateTime.now(),
      memberName: data[AppConstants.fieldMemberName] as String? ?? '',
      aktsNumber: data[AppConstants.fieldAktsNumber] as String? ?? '',
      membershipYear: data[AppConstants.fieldMembershipYear] as String? ?? '',
      amount: (data[AppConstants.fieldAmount] as num?)?.toDouble() ?? 0.0,
      amountInWords: data[AppConstants.fieldAmountInWords] as String? ?? '',
      paymentMode: data[AppConstants.fieldPaymentMode] as String? ?? '',
      transactionId: data[AppConstants.fieldTransactionId] as String?,
      remarks: data[AppConstants.fieldRemarks] as String?,
      verificationId: data[AppConstants.fieldVerificationId] as String? ?? '',
      verificationUrl: data[AppConstants.fieldVerificationUrl] as String? ?? '',
      status: data[AppConstants.fieldStatus] as String? ?? AppConstants.statusValid,
      createdBy: data[AppConstants.fieldCreatedBy] as String? ?? '',
      createdAt: (data[AppConstants.fieldCreatedAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt: (data[AppConstants.fieldUpdatedAt] as Timestamp?)?.toDate() ??
          DateTime.now(),
      pdfUrl: data[AppConstants.fieldPdfUrl] as String?,
    );
  }

  /// Convert to a Map for Firestore storage
  Map<String, dynamic> toFirestore() {
    return {
      AppConstants.fieldReceiptNumber: receiptNumber,
      AppConstants.fieldDate: Timestamp.fromDate(date),
      AppConstants.fieldMemberName: memberName,
      AppConstants.fieldAktsNumber: aktsNumber,
      AppConstants.fieldMembershipYear: membershipYear,
      AppConstants.fieldAmount: amount,
      AppConstants.fieldAmountInWords: amountInWords,
      AppConstants.fieldPaymentMode: paymentMode,
      AppConstants.fieldTransactionId: transactionId,
      AppConstants.fieldRemarks: remarks,
      AppConstants.fieldVerificationId: verificationId,
      AppConstants.fieldVerificationUrl: verificationUrl,
      AppConstants.fieldStatus: status,
      AppConstants.fieldCreatedBy: createdBy,
      AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
      AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      AppConstants.fieldPdfUrl: pdfUrl,
    };
  }

  /// Map for Firestore update (only mutable fields)
  Map<String, dynamic> toUpdateMap() {
    return {
      AppConstants.fieldStatus: status,
      AppConstants.fieldPdfUrl: pdfUrl,
      AppConstants.fieldRemarks: remarks,
      AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    };
  }

  /// Copy with modified fields
  ReceiptModel copyWith({
    String? id,
    String? receiptNumber,
    DateTime? date,
    String? memberName,
    String? aktsNumber,
    String? membershipYear,
    double? amount,
    String? amountInWords,
    String? paymentMode,
    String? transactionId,
    String? remarks,
    String? verificationId,
    String? verificationUrl,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? pdfUrl,
  }) {
    return ReceiptModel(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      date: date ?? this.date,
      memberName: memberName ?? this.memberName,
      aktsNumber: aktsNumber ?? this.aktsNumber,
      membershipYear: membershipYear ?? this.membershipYear,
      amount: amount ?? this.amount,
      amountInWords: amountInWords ?? this.amountInWords,
      paymentMode: paymentMode ?? this.paymentMode,
      transactionId: transactionId ?? this.transactionId,
      remarks: remarks ?? this.remarks,
      verificationId: verificationId ?? this.verificationId,
      verificationUrl: verificationUrl ?? this.verificationUrl,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
    );
  }

  @override
  String toString() =>
      'ReceiptModel(id: $id, receiptNumber: $receiptNumber, memberName: $memberName, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
