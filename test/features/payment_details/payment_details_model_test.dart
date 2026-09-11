// test/features/payment_details/payment_details_model_test.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printer/features/payment_details/data/models/payment_details_model.dart';

void main() {
  group('PaymentDetailsModel Tests', () {
    test('creates model and correctly maps properties', () {
      final now = DateTime(2025, 3, 10);
      final sampleBytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final b64 = base64Encode(sampleBytes);

      final model = PaymentDetailsModel(
        id: 'test-pay-1',
        voucherNumber: 'PAY-2025-001',
        shopName: 'Sri Venkateswara Electronics',
        billNumber: 'INV-8899',
        date: now,
        amount: 3500.0,
        amountInWords: 'RUPEES THREE THOUSAND FIVE HUNDRED ONLY',
        paymentType: 'Online',
        paymentMode: 'UPI',
        transactionDetails: 'UPI Ref 491029410291',
        remarks: 'Office projector bulb purchase',
        imagesBase64: [b64],
        status: 'valid',
        createdBy: 'Admin User',
        createdAt: now,
        updatedAt: now,
      );

      expect(model.id, 'test-pay-1');
      expect(model.voucherNumber, 'PAY-2025-001');
      expect(model.shopName, 'Sri Venkateswara Electronics');
      expect(model.billNumber, 'INV-8899');
      expect(model.amount, 3500.0);
      expect(model.isOnline, isTrue);
      expect(model.hasImages, isTrue);
      expect(model.imageBytesList.length, 1);
      expect(model.imageBytesList.first, equals(sampleBytes));

      final map = model.toMap();
      expect(map['shopName'], 'Sri Venkateswara Electronics');
      expect(map['billNumber'], 'INV-8899');
      expect(map['amount'], 3500.0);

      final reconstructed = PaymentDetailsModel.fromMap(map);
      expect(reconstructed.id, 'test-pay-1');
      expect(reconstructed.shopName, model.shopName);
      expect(reconstructed.billNumber, model.billNumber);
      expect(reconstructed.amount, model.amount);
      expect(reconstructed.isOnline, isTrue);
      expect(reconstructed.hasImages, isTrue);
    });

    test('handles offline payments correctly', () {
      final now = DateTime.now();
      final model = PaymentDetailsModel(
        id: 'test-pay-2',
        voucherNumber: 'PAY-2025-002',
        shopName: 'General Store',
        billNumber: 'CASH-01',
        date: now,
        amount: 250.0,
        amountInWords: 'RUPEES TWO HUNDRED AND FIFTY ONLY',
        paymentType: 'Offline',
        paymentMode: 'Cash',
        createdBy: 'Staff',
        createdAt: now,
        updatedAt: now,
      );

      expect(model.isOnline, isFalse);
      expect(model.hasImages, isFalse);
      expect(model.imageBytesList, isEmpty);
    });
  });
}
