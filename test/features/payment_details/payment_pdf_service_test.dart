// test/features/payment_details/payment_pdf_service_test.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printer/features/payment_details/data/models/payment_details_model.dart';
import 'package:receipt_printer/features/payment_details/services/payment_pdf_service.dart';

// Minimal valid 1x1 transparent PNG bytes
final Uint8List _samplePngBytes = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
  0, 0, 0, 13, 73, 68, 65, 84, 120, 156, 99, 248, 255, 255, 63, 0,
  5, 254, 2, 254, 167, 53, 129, 132, 0, 0, 0, 0, 73, 69, 78, 68,
  174, 66, 96, 130,
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PaymentPdfService Tests', () {
    test('generatePaymentVoucherPdf creates valid PDF without images', () async {
      final payment = PaymentDetailsModel(
        id: 'test-pay-1',
        voucherNumber: 'PAY-2025-0001',
        shopName: 'Super Mart',
        billNumber: 'BILL-100',
        date: DateTime(2025, 3, 1),
        amount: 850.0,
        amountInWords: 'RUPEES EIGHT HUNDRED AND FIFTY ONLY',
        paymentType: 'Online',
        paymentMode: 'UPI',
        transactionDetails: 'UPI/382910481029',
        status: 'valid',
        createdBy: 'Admin',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pdfBytes = await PaymentPdfService.generatePaymentVoucherPdf(payment);

      expect(pdfBytes, isNotEmpty);
      // Valid PDF documents start with '%PDF' (0x25, 0x50, 0x44, 0x46)
      expect(pdfBytes[0], 0x25);
      expect(pdfBytes[1], 0x50);
      expect(pdfBytes[2], 0x44);
      expect(pdfBytes[3], 0x46);
    });

    test('generatePaymentVoucherPdf creates valid PDF with embedded bill photo', () async {
      final b64 = base64Encode(_samplePngBytes);
      final payment = PaymentDetailsModel(
        id: 'test-pay-2',
        voucherNumber: 'PAY-2025-0002',
        shopName: 'City Hardware & Electricals',
        billNumber: 'INV-4412',
        date: DateTime(2025, 3, 2),
        amount: 4500.0,
        amountInWords: 'RUPEES FOUR THOUSAND FIVE HUNDRED ONLY',
        paymentType: 'Online',
        paymentMode: 'Bank Transfer',
        transactionDetails: 'IMPS/REF/9912830182',
        remarks: 'Office wiring and LED lights',
        imagesBase64: [b64],
        status: 'valid',
        createdBy: 'Staff User',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pdfBytes = await PaymentPdfService.generatePaymentVoucherPdf(payment);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes[0], 0x25); // '%'
      expect(pdfBytes[1], 0x50); // 'P'
      expect(pdfBytes[2], 0x44); // 'D'
      expect(pdfBytes[3], 0x46); // 'F'
    });
  });
}
