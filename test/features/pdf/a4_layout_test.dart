// test/features/pdf/a4_layout_test.dart
// Unit tests for single and bulk A4 receipt PDF generation

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printer/core/constants/app_constants.dart';
import 'package:receipt_printer/features/pdf/services/bulk_print_pdf_service.dart';
import 'package:receipt_printer/features/pdf/services/receipt_pdf_service.dart';
import 'package:receipt_printer/features/receipts/data/models/receipt_model.dart';

ReceiptModel _createMockReceipt({int index = 1}) {
  return ReceiptModel(
    id: 'test-receipt-$index',
    receiptNumber: '2024-25/${index.toString().padLeft(4, '0')}',
    date: DateTime(2025, 3, 1),
    memberName: 'MR. P VENKATESH $index',
    aktsNumber: 'AKTS ${index.toString().padLeft(3, '0')}',
    membershipYear: '2024-2025',
    amount: 1200.0,
    amountInWords: 'RUPEES ONE THOUSAND TWO HUNDRED ONLY',
    paymentMode: 'CASH',
    verificationId: 'v-guid-$index',
    verificationUrl: 'https://akts-receipts.web.app/verify/v-guid-$index',
    status: AppConstants.statusValid,
    createdBy: 'admin',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('A4 Receipt PDF Generation Tests', () {
    test('generateSingleReceiptPdf creates valid non-empty PDF bytes', () async {
      final receipt = _createMockReceipt(index: 49);
      final Uint8List pdfBytes =
          await ReceiptPdfService.generateSingleReceiptPdf(receipt);

      expect(pdfBytes, isNotEmpty);
      // PDF documents must begin with %PDF header (bytes: 0x25, 0x50, 0x44, 0x46)
      expect(pdfBytes[0], 0x25); // '%'
      expect(pdfBytes[1], 0x50); // 'P'
      expect(pdfBytes[2], 0x44); // 'D'
      expect(pdfBytes[3], 0x46); // 'F'
    });

    test('generateBulkPdf creates valid A4 grid PDF for 10 receipts (single page)',
        () async {
      final receipts = List.generate(10, (i) => _createMockReceipt(index: i + 1));
      final Uint8List pdfBytes =
          await BulkPrintPdfService.generateBulkPdf(receipts);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes[0], 0x25);
      expect(pdfBytes[1], 0x50);
      expect(pdfBytes[2], 0x44);
      expect(pdfBytes[3], 0x46);
    });

    test('generateBulkPdf handles partial pages with null padding gracefully',
        () async {
      // 3 receipts on a 10-slot grid
      final receipts = List.generate(3, (i) => _createMockReceipt(index: i + 1));
      final Uint8List pdfBytes =
          await BulkPrintPdfService.generateBulkPdf(receipts);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('generateBulkPdf handles multi-page bulk batches (e.g. 15 receipts)',
        () async {
      // 15 receipts should span 2 A4 pages
      final receipts = List.generate(15, (i) => _createMockReceipt(index: i + 1));
      final Uint8List pdfBytes =
          await BulkPrintPdfService.generateBulkPdf(receipts);

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(2000));
    });
  });
}
