// lib/features/pdf/services/bulk_print_pdf_service.dart
// A4 bulk print PDF service: 2 columns × 5 rows = 10 receipts per page

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../features/receipts/data/models/receipt_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';

class BulkPrintPdfService {
  BulkPrintPdfService._();

  // A4 dimensions in PDF points: 595.28 x 841.89
  static const double _a4Width = 595.28;
  static const double _a4Height = 841.89;
  static const double _pageMargin = 20.0;
  static const double _columnGap = 10.0;
  static const double _rowGap = 8.0;
  static const int _receiptsPerPage = 10;
  static const int _columns = 2;
  static const int _rows = 5;

  // AKTS Colors
  static final PdfColor _navy = PdfColor.fromHex('#0D2366');
  static final PdfColor _textSecondary = PdfColor.fromHex('#4A4A6A');
  static final PdfColor _textMuted = PdfColor.fromHex('#888AAA');
  static final PdfColor _divider = PdfColor.fromHex('#E0E6F0');
  static final PdfColor _bgLight = PdfColor.fromHex('#F0F4FF');
  static final PdfColor _statusValid = PdfColor.fromHex('#16A34A');
  static final PdfColor _statusRevoked = PdfColor.fromHex('#DC2626');

  /// Generate A4 PDF with 10 receipts per page (2 columns × 5 rows)
  static Future<Uint8List> generateBulkPdf(
    List<ReceiptModel> receipts,
  ) async {
    final doc = pw.Document(
      title: 'AKTS Bulk Print - ${receipts.length} Receipts',
      author: AppConstants.organizationNameEnglish,
      creator: 'AKTS Receipt Management System',
    );

    // Split receipts into pages of 10
    final pages = <List<ReceiptModel?>>[];
    for (int i = 0; i < receipts.length; i += _receiptsPerPage) {
      final List<ReceiptModel?> pageReceipts = receipts
          .skip(i)
          .take(_receiptsPerPage)
          .map<ReceiptModel?>((r) => r)
          .toList();
      // Pad to exactly 10 slots
      while (pageReceipts.length < _receiptsPerPage) {
        pageReceipts.add(null);
      }
      pages.add(pageReceipts);
    }

    for (final pageReceipts in pages) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(_pageMargin),
          build: (context) => _buildA4Page(pageReceipts),
        ),
      );
    }

    return doc.save();
  }

  static pw.Widget _buildA4Page(List<ReceiptModel?> receipts) {
    // Calculate dimensions for each receipt slot
    // Available width after margins and gap
    final totalWidth = _a4Width - 2 * _pageMargin;
    final receiptWidth = (totalWidth - _columnGap) / _columns;

    // Available height after margins and gaps
    final totalHeight = _a4Height - 2 * _pageMargin;
    final receiptHeight = (totalHeight - (_rows - 1) * _rowGap) / _rows;

    return pw.Column(
      children: List.generate(_rows, (row) {
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: List.generate(_columns, (col) {
            final index = row * _columns + col;
            final receipt = index < receipts.length ? receipts[index] : null;

            return pw.Container(
              width: receiptWidth,
              height: receiptHeight,
              margin: pw.EdgeInsets.only(
                right: col < _columns - 1 ? _columnGap : 0,
                bottom: row < _rows - 1 ? _rowGap : 0,
              ),
              child: receipt != null
                  ? _buildCompactReceipt(receipt, receiptWidth, receiptHeight)
                  : _buildEmptySlot(receiptWidth, receiptHeight),
            );
          }),
        );
      }),
    );
  }

  static pw.Widget _buildCompactReceipt(
    ReceiptModel receipt,
    double width,
    double height,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _navy, width: 0.75),
        color: PdfColors.white,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // Compact header
          pw.Container(
            color: _navy,
            padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: pw.Column(
              children: [
                pw.Text(
                  AppConstants.organizationNameEnglish,
                  style: pw.TextStyle(
                    fontSize: 6.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  AppConstants.receiptTitleEnglish,
                  style: pw.TextStyle(
                    fontSize: 5.5,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          // Content row: fields + QR
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Fields column
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _compactField('No', receipt.receiptNumber),
                        _compactField('Date',
                            DateFormatter.toDisplayDate(receipt.date)),
                        _compactField('Name', receipt.memberName),
                        _compactField('AKTS', receipt.aktsNumber),
                        _compactField('Year', receipt.membershipYear),
                        _compactField(
                          'Amt',
                          currencyFormat.format(receipt.amount),
                          bold: true,
                        ),
                        _compactField('Mode', receipt.paymentMode),
                        if (receipt.transactionId != null &&
                            receipt.transactionId!.isNotEmpty)
                          _compactField('Txn', receipt.transactionId!,
                              truncate: true),
                        pw.Spacer(),
                        // Signature lines
                        _compactSignatureLine('Member Signature'),
                        pw.SizedBox(height: 5),
                        _compactSignatureLine('Treasurer'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  // QR column - MINIMUM 50x50 to remain scannable
                  pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.start,
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      // QR barcode — 50x50 minimum for scan reliability
                      pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(
                          errorCorrectLevel: pw.BarcodeQRCorrectionLevel.medium,
                        ),
                        data: receipt.verificationUrl,
                        width: 52,
                        height: 52,
                        color: _navy,
                        backgroundColor: PdfColors.white,
                        padding: const pw.EdgeInsets.all(2),
                        drawText: false,
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        receipt.isRevoked ? '⚠REVOKED' : '✓VERIFIED',
                        style: pw.TextStyle(
                          fontSize: 5,
                          fontWeight: pw.FontWeight.bold,
                          color: receipt.isRevoked ? _statusRevoked : _statusValid,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 2),
                      // Short UUID for reference
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 2, vertical: 1),
                        decoration: pw.BoxDecoration(
                          color: _bgLight,
                          border: pw.Border.all(color: _divider, width: 0.3),
                        ),
                        child: pw.Text(
                          receipt.verificationId.substring(0, 8),
                          style: pw.TextStyle(
                            fontSize: 4.5,
                            color: _textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _compactField(
    String label,
    String value, {
    bool bold = false,
    bool truncate = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 26,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 5.5,
                color: _textSecondary,
              ),
            ),
          ),
          pw.Text(
            ': ',
            style: pw.TextStyle(fontSize: 5.5, color: _textMuted),
          ),
          pw.Expanded(
            child: pw.Text(
              truncate && value.length > 12
                  ? '${value.substring(0, 12)}...'
                  : value,
              style: pw.TextStyle(
                fontSize: 6,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _compactSignatureLine(String label) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          height: 0.5,
          color: _textMuted,
        ),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 5,
            color: _textMuted,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildEmptySlot(double width, double height) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColor.fromHex('#E0E6F0'),
          width: 0.5,
        ),
        color: PdfColor.fromHex('#FAFAFA'),
      ),
      child: pw.Center(
        child: pw.Text(
          '',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColor.fromHex('#E0E6F0'),
          ),
        ),
      ),
    );
  }

  /// Calculate total pages needed for given number of receipts
  static int calculateTotalPages(int receiptCount) {
    return (receiptCount / _receiptsPerPage).ceil();
  }

  /// Verify layout constraint: exactly 10 receipts per page
  static bool verifyLayout() {
    return _columns * _rows == _receiptsPerPage;
  }
}
