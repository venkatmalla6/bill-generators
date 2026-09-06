// test/features/receipts/receipt_table_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printer/core/constants/app_constants.dart';
import 'package:receipt_printer/features/receipts/data/models/receipt_model.dart';
import 'package:receipt_printer/shared/widgets/common/receipt_table_widget.dart';

void main() {
  testWidgets('ReceiptTableWidget renders ID, Name, Date, Amount in tabular format',
      (WidgetTester tester) async {
    final receipt = ReceiptModel(
      id: 'test-tbl-1',
      receiptNumber: 'AKTS/2026/001',
      date: DateTime(2026, 9, 6),
      memberName: 'VENKAT RAMANA',
      aktsNumber: 'AKTS 405',
      membershipYear: '2026-2027',
      amount: 1500.0,
      amountInWords: 'One Thousand Five Hundred Rupees Only',
      paymentMode: 'Cash',
      verificationId: 'v-tbl-1',
      verificationUrl: 'https://akts-receipts.web.app/verify/v-tbl-1',
      status: AppConstants.statusValid,
      createdBy: 'test-user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptTableWidget(
            receipts: [receipt],
          ),
        ),
      ),
    );

    // Verify table headers
    expect(find.text('ID / RECEIPT #'), findsOneWidget);
    expect(find.text('MEMBER NAME'), findsOneWidget);
    expect(find.text('DATE'), findsOneWidget);
    expect(find.text('AMOUNT'), findsOneWidget);
    expect(find.text('STATUS'), findsOneWidget);
    expect(find.text('ACTIONS'), findsOneWidget);

    // Verify row data: ID, Name, Date, Amount
    expect(find.text('AKTS/2026/001'), findsOneWidget);
    expect(find.text('AKTS 405'), findsOneWidget);
    expect(find.text('VENKAT RAMANA'), findsOneWidget);
    expect(find.textContaining('1,500'), findsOneWidget);
    expect(find.text('VALID'), findsOneWidget);
  });
}
