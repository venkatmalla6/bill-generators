// lib/features/pdf/services/receipt_pdf_service.dart
// PDF generation service for single AKTS receipts using pdf package primitives

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../../features/receipts/data/models/receipt_model.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';

class ReceiptPdfService {
  ReceiptPdfService._();

  // AKTS Navy Blue colors for PDF
  static final PdfColor _navyPrimary = PdfColor.fromHex('#0D2366');
  static final PdfColor _navyDeep = PdfColor.fromHex('#050F30');
  static final PdfColor _gold = PdfColor.fromHex('#D4AF37');
  static final PdfColor _textMuted = PdfColor.fromHex('#888AAA');
  static final PdfColor _textSecondary = PdfColor.fromHex('#4A4A6A');
  static final PdfColor _dividerColor = PdfColor.fromHex('#E0E6F0');
  static final PdfColor _bgLight = PdfColor.fromHex('#F0F4FF');
  static final PdfColor _statusValid = PdfColor.fromHex('#16A34A');
  static final PdfColor _statusRevoked = PdfColor.fromHex('#DC2626');

  /// Generate a single receipt PDF
  static Future<Uint8List> generateSingleReceiptPdf(
    ReceiptModel receipt,
  ) async {
    final doc = pw.Document(
      title: 'AKTS Receipt - ${receipt.receiptNumber}',
      author: AppConstants.organizationNameEnglish,
      creator: 'AKTS Receipt Management System',
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => _buildSingleReceiptPage(receipt),
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildSingleReceiptPage(ReceiptModel receipt) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _navyPrimary, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          _buildPdfHeader(),
          _buildPdfTitleBar(),
          _buildPdfFields(receipt),
          _buildPdfBottomSection(receipt),
        ],
      ),
    );
  }

  // ─── PDF Header ──────────────────────────────────────────────────────────

  static pw.Widget _buildPdfHeader() {
    return pw.Container(
      color: _navyPrimary,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: pw.Row(
        children: [
          // Logo circle placeholder
          pw.Container(
            width: 50,
            height: 50,
            decoration: pw.BoxDecoration(
              shape: pw.BoxShape.circle,
              color: PdfColors.white,
              border: pw.Border.all(color: _gold, width: 2),
            ),
            child: pw.Center(
              child: pw.Text(
                'AKTS',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: _navyPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  AppConstants.organizationNameTelugu,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  AppConstants.organizationNameEnglish,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: _gold,
                    letterSpacing: 2,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Kalpakkam, Tamil Nadu',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 50),
        ],
      ),
    );
  }

  // ─── PDF Title Bar ───────────────────────────────────────────────────────

  static pw.Widget _buildPdfTitleBar() {
    return pw.Container(
      color: _navyDeep,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: pw.Column(
        children: [
          pw.Text(
            AppConstants.receiptTitleTelugu,
            style: pw.TextStyle(
              fontSize: 13,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            '(${AppConstants.receiptTitleEnglish})',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.white,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── PDF Fields ──────────────────────────────────────────────────────────

  static pw.Widget _buildPdfFields(ReceiptModel receipt) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );

    final fields = [
      ['Receipt No.', receipt.receiptNumber],
      ['Date', DateFormatter.toDisplayDate(receipt.date)],
      ['Member Name', receipt.memberName],
      ['AKTS No.', receipt.aktsNumber],
      ['Membership Year', receipt.membershipYear],
      ['Amount Paid', currencyFormat.format(receipt.amount)],
      ['Payment Mode', receipt.paymentMode],
      if (receipt.transactionId != null && receipt.transactionId!.isNotEmpty)
        ['Transaction ID', receipt.transactionId!],
      if (receipt.remarks != null && receipt.remarks!.isNotEmpty)
        ['Remarks', receipt.remarks!],
    ];

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: pw.Column(
        children: [
          ...fields.map((f) => _buildPdfFieldRow(f[0], f[1])),
          pw.SizedBox(height: 4),
          // Amount in words
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: _bgLight,
              border: pw.Border.all(color: _dividerColor),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Amount in Words: ',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: _textSecondary,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    receipt.amountInWords,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _navyPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Revoked warning
          if (receipt.isRevoked) ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#FEE2E2'),
                border: pw.Border.all(color: _statusRevoked),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Center(
                child: pw.Text(
                  '⚠ THIS RECEIPT HAS BEEN REVOKED',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _statusRevoked,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildPdfFieldRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  label,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
                pw.Text(
                  ':',
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── PDF Bottom Section ──────────────────────────────────────────────────

  static pw.Widget _buildPdfBottomSection(ReceiptModel receipt) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _navyPrimary, width: 1.5),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Signatures (left)
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Member Signature',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: _textSecondary,
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Divider(color: _textMuted, thickness: 0.5),
                  pw.SizedBox(height: 16),
                  pw.Text(
                    'Treasurer / Receiver',
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: _textSecondary,
                    ),
                  ),
                  pw.SizedBox(height: 24),
                  pw.Divider(color: _textMuted, thickness: 0.5),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'This is a computer-generated receipt.',
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: _textMuted,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Vertical divider
          pw.Container(
            width: 1.5,
            color: _navyPrimary,
            height: 160,
          ),
          // QR Section (right)
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              color: _bgLight,
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // QR code placeholder (BarcodeWidget)
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: receipt.verificationUrl,
                    width: 90,
                    height: 90,
                    color: _navyPrimary,
                    backgroundColor: PdfColors.white,
                    padding: const pw.EdgeInsets.all(4),
                    drawText: false,
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: receipt.isRevoked
                          ? PdfColor.fromHex('#FEE2E2')
                          : PdfColor.fromHex('#DCFCE7'),
                      border: pw.Border.all(
                        color: receipt.isRevoked ? _statusRevoked : _statusValid,
                      ),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      receipt.isRevoked
                          ? '⚠ REVOKED'
                          : '✓ AUTHENTICITY VERIFIED',
                      style: pw.TextStyle(
                        fontSize: 7,
                        fontWeight: pw.FontWeight.bold,
                        color: receipt.isRevoked ? _statusRevoked : _statusValid,
                        letterSpacing: 0.3,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      border: pw.Border.all(color: _dividerColor),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                    ),
                    child: pw.Text(
                      'UUID:\n${_truncateUuid(receipt.verificationId)}',
                      style: pw.TextStyle(
                        fontSize: 6,
                        color: _textSecondary,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Scan to verify',
                    style: pw.TextStyle(
                      fontSize: 7,
                      color: _textMuted,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _truncateUuid(String uuid) {
    if (uuid.length <= 23) return uuid;
    return '${uuid.substring(0, 8)}-...\n...${uuid.substring(uuid.length - 12)}';
  }
}
