// test/widget_test.dart
// Smoke test for AKTS ReceiptWidget rendering
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printer/core/constants/app_constants.dart';
import 'package:receipt_printer/features/receipts/data/models/receipt_model.dart';
import 'package:receipt_printer/shared/widgets/receipt/receipt_widget.dart';

void main() {
  testWidgets('ReceiptWidget smoke test renders organization name and details',
      (WidgetTester tester) async {
    final receipt = ReceiptModel(
      id: 'test-smoke-1',
      receiptNumber: '2024-25/0049',
      date: DateTime(2025, 3, 1),
      memberName: 'MR. P VENKATESH',
      aktsNumber: 'AKTS 049',
      membershipYear: '2024-2025',
      amount: 1200.0,
      amountInWords: 'One Thousand Two Hundred Rupees Only',
      paymentMode: 'CASH',
      verificationId: 'test-v-id',
      verificationUrl: 'https://akts-receipts.web.app/verify/test-v-id',
      status: AppConstants.statusValid,
      createdBy: 'admin',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ReceiptWidget(receipt: receipt),
          ),
        ),
      ),
    );

    // Verify organization title is rendered
    expect(find.text(AppConstants.organizationNameEnglish), findsOneWidget);
    // Verify member name is rendered
    expect(find.text('MR. P VENKATESH'), findsOneWidget);
    // Verify AKTS number
    expect(find.text('AKTS 049'), findsOneWidget);
    // Verify amount
    expect(find.textContaining('1,200.00'), findsOneWidget);
  });
}
