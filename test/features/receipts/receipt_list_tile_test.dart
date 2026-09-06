// test/features/receipts/receipt_list_tile_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_printer/core/constants/app_constants.dart';
import 'package:receipt_printer/features/receipts/data/models/receipt_model.dart';
import 'package:receipt_printer/shared/widgets/common/receipt_list_tile.dart';

void main() {
  testWidgets('ReceiptListTile renders delete button and responds to tap',
      (WidgetTester tester) async {
    bool deleteTapped = false;

    final receipt = ReceiptModel(
      id: 'test-delete-1',
      receiptNumber: '2024-25/0100',
      date: DateTime(2025, 3, 1),
      memberName: 'JOHN DOE',
      aktsNumber: 'AKTS 100',
      membershipYear: '2024-2025',
      amount: 500.0,
      amountInWords: 'Five Hundred Rupees Only',
      paymentMode: 'CASH',
      verificationId: 'v-100',
      verificationUrl: 'https://akts-receipts.web.app/verify/v-100',
      status: AppConstants.statusValid,
      createdBy: 'test-user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReceiptListTile(
            receipt: receipt,
            onDelete: () {
              deleteTapped = true;
            },
          ),
        ),
      ),
    );

    // Verify member name and receipt number
    expect(find.text('JOHN DOE'), findsOneWidget);

    // Verify delete icon button is displayed
    final deleteButtonFinder = find.byIcon(Icons.delete_outline);
    expect(deleteButtonFinder, findsOneWidget);

    // Tap delete button
    await tester.tap(deleteButtonFinder);
    await tester.pump();

    // Verify callback was triggered
    expect(deleteTapped, isTrue);
  });
}
