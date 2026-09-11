// lib/features/payment_details/data/models/payment_details_model.dart
// Data model for Payment Done Details (Bill / Voucher with uploaded screenshots)

import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentDetailsModel {
  final String id;
  final String voucherNumber;
  final String shopName;
  final String billNumber;
  final DateTime date;
  final double amount;
  final String amountInWords;
  final String paymentType; // 'Online' | 'Offline'
  final String paymentMode; // 'UPI' | 'Cash' | 'Bank Transfer' | 'Card' | 'Cheque' | 'Other'
  final String? transactionDetails; // UTR / Reference ID / Transaction details
  final String? remarks;
  final List<String> imagesBase64; // Base64 encoded screenshot/photo strings
  final String status; // 'valid' | 'cancelled'
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PaymentDetailsModel({
    required this.id,
    required this.voucherNumber,
    required this.shopName,
    required this.billNumber,
    required this.date,
    required this.amount,
    required this.amountInWords,
    required this.paymentType,
    required this.paymentMode,
    this.transactionDetails,
    this.remarks,
    this.imagesBase64 = const [],
    this.status = 'valid',
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOnline => paymentType.toLowerCase() == 'online';
  bool get hasImages => imagesBase64.isNotEmpty;
  bool get isValid => status == 'valid';

  /// Helper to get decoded Uint8List bytes for all attached images
  List<Uint8List> get imageBytesList {
    final list = <Uint8List>[];
    for (final b64 in imagesBase64) {
      try {
        final clean = b64.contains(',') ? b64.split(',').last : b64;
        list.add(base64Decode(clean));
      } catch (_) {}
    }
    return list;
  }

  factory PaymentDetailsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PaymentDetailsModel.fromMap(data, id: doc.id);
  }

  factory PaymentDetailsModel.fromMap(Map<String, dynamic> data, {String? id}) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.now();
    }

    final rawImages = data['imagesBase64'] ?? data['images'] ?? [];
    final List<String> parsedImages = [];
    if (rawImages is List) {
      for (final item in rawImages) {
        if (item is String && item.isNotEmpty) {
          parsedImages.add(item);
        }
      }
    }

    return PaymentDetailsModel(
      id: id ?? data['id'] as String? ?? '',
      voucherNumber: data['voucherNumber'] as String? ?? '',
      shopName: data['shopName'] as String? ?? '',
      billNumber: data['billNumber'] as String? ?? '',
      date: parseDate(data['date']),
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      amountInWords: data['amountInWords'] as String? ?? '',
      paymentType: data['paymentType'] as String? ?? 'Online',
      paymentMode: data['paymentMode'] as String? ?? 'UPI',
      transactionDetails: data['transactionDetails'] as String?,
      remarks: data['remarks'] as String?,
      imagesBase64: parsedImages,
      status: data['status'] as String? ?? 'valid',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'voucherNumber': voucherNumber,
      'shopName': shopName,
      'billNumber': billNumber,
      'date': Timestamp.fromDate(date),
      'amount': amount,
      'amountInWords': amountInWords,
      'paymentType': paymentType,
      'paymentMode': paymentMode,
      'transactionDetails': transactionDetails,
      'remarks': remarks,
      'imagesBase64': imagesBase64,
      'status': status,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'voucherNumber': voucherNumber,
      'shopName': shopName,
      'billNumber': billNumber,
      'date': date.toIso8601String(),
      'amount': amount,
      'amountInWords': amountInWords,
      'paymentType': paymentType,
      'paymentMode': paymentMode,
      'transactionDetails': transactionDetails,
      'remarks': remarks,
      'imagesBase64': imagesBase64,
      'status': status,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  PaymentDetailsModel copyWith({
    String? id,
    String? voucherNumber,
    String? shopName,
    String? billNumber,
    DateTime? date,
    double? amount,
    String? amountInWords,
    String? paymentType,
    String? paymentMode,
    String? transactionDetails,
    String? remarks,
    List<String>? imagesBase64,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentDetailsModel(
      id: id ?? this.id,
      voucherNumber: voucherNumber ?? this.voucherNumber,
      shopName: shopName ?? this.shopName,
      billNumber: billNumber ?? this.billNumber,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      amountInWords: amountInWords ?? this.amountInWords,
      paymentType: paymentType ?? this.paymentType,
      paymentMode: paymentMode ?? this.paymentMode,
      transactionDetails: transactionDetails ?? this.transactionDetails,
      remarks: remarks ?? this.remarks,
      imagesBase64: imagesBase64 ?? this.imagesBase64,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
