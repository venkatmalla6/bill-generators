// lib/features/payment_details/services/payment_pdf_service.dart
// Professional PDF generation service for Payment Done Vouchers with embedded bill photos

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../data/models/payment_details_model.dart';

class PaymentPdfService {
  PaymentPdfService._();

  // Color palette matching AKTS theme
  static final PdfColor _navyPrimary = PdfColor.fromHex('#0D2366');
  static final PdfColor _navyDeep = PdfColor.fromHex('#050F30');
  static final PdfColor _gold = PdfColor.fromHex('#D4AF37');
  static final PdfColor _textSecondary = PdfColor.fromHex('#4A4A6A');
  static final PdfColor _dividerColor = PdfColor.fromHex('#E0E6F0');
  static final PdfColor _bgLight = PdfColor.fromHex('#F8FAFC');
  static final PdfColor _bgAccent = PdfColor.fromHex('#EFF6FF');
  static final PdfColor _statusPaid = PdfColor.fromHex('#16A34A');

  /// Generate a complete PDF document for the Payment Done voucher including all uploaded photos
  static Future<Uint8List> generatePaymentVoucherPdf(
    PaymentDetailsModel payment, {
    List<Uint8List>? additionalImages,
  }) async {
    final doc = pw.Document(
      title: 'AKTS Payment Voucher - ${payment.voucherNumber}',
      author: AppConstants.organizationNameEnglish,
      creator: 'AKTS Receipt & Payment Management System',
    );

    final List<Uint8List> images = [
      ...payment.imageBytesList,
      if (additionalImages != null) ...additionalImages,
    ];

    // Page 1: Main Voucher Details
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _navyPrimary, width: 2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                _buildTitleBar(payment),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _buildSummaryGrid(payment),
                      pw.SizedBox(height: 12),
                      _buildAmountBox(payment),
                      pw.SizedBox(height: 14),
                      if (images.isNotEmpty) ...[
                        _buildAttachmentsSummary(images.length),
                        pw.SizedBox(height: 10),
                        // If there is 1 image, display a preview right on page 1 if fits
                        if (images.length == 1)
                          _buildSingleEmbeddedImage(images.first, 'Bill Screenshot / Payment Proof (Page 1)'),
                      ],
                    ],
                  ),
                ),
                pw.Spacer(),
                _buildFooter(payment),
              ],
            ),
          );
        },
      ),
    );

    // If there is more than 1 image (or if 1 large image is attached), add dedicated photo pages
    if (images.length > 1 || (images.length == 1 && images.first.isNotEmpty)) {
      // Split into pairs or single pages for high clarity
      for (int i = 0; i < images.length; i++) {
        final imgBytes = images[i];
        if (imgBytes.isEmpty) continue;

        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(36),
            build: (context) {
              return pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _navyPrimary, width: 1.5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _buildAttachmentPageHeader(payment, i + 1, images.length),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        child: pw.Center(
                          child: _buildAttachmentImage(imgBytes),
                        ),
                      ),
                    ),
                    _buildAttachmentPageFooter(payment),
                  ],
                ),
              );
            },
          ),
        );
      }
    }

    return doc.save();
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  static pw.Widget _buildHeader() {
    return pw.Container(
      color: _navyPrimary,
      padding: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: pw.Row(
        children: [
          pw.Container(
            width: 48,
            height: 48,
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
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  AppConstants.organizationNameTelugu,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  AppConstants.organizationNameEnglish,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _gold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Kalpakkam, Tamil Nadu',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 48), // Balance logo
        ],
      ),
    );
  }

  // ─── Title Bar ────────────────────────────────────────────────────────────

  static pw.Widget _buildTitleBar(PaymentDetailsModel payment) {
    return pw.Container(
      color: _navyDeep,
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'చెల్లింపు వివరాలు (PAYMENT DONE DETAILS)',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'BILL PAYMENT VOUCHER',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: _gold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _statusPaid,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'PAYMENT DONE',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Summary Grid ─────────────────────────────────────────────────────────

  static pw.Widget _buildSummaryGrid(PaymentDetailsModel payment) {
    final fields = [
      ['Voucher No.', payment.voucherNumber],
      ['Date', DateFormatter.toDisplayDate(payment.date)],
      ['Shop Name', payment.shopName],
      ['Bill No.', payment.billNumber],
      ['Payment Type', '${payment.paymentType.toUpperCase()} (${payment.paymentMode})'],
      if (payment.transactionDetails != null && payment.transactionDetails!.isNotEmpty)
        ['Transaction Details', payment.transactionDetails!],
      if (payment.remarks != null && payment.remarks!.isNotEmpty)
        ['Remarks / Notes', payment.remarks!],
      ['Recorded By', payment.createdBy.isNotEmpty ? payment.createdBy : 'Admin / Staff'],
    ];

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _dividerColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        children: fields.map((f) => _buildRow(f[0], f[1])).toList(),
      ),
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _dividerColor, width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 9.5,
                color: _textSecondary,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(': ', style: pw.TextStyle(fontSize: 9.5, color: _textSecondary)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Amount Box ───────────────────────────────────────────────────────────

  static pw.Widget _buildAmountBox(PaymentDetailsModel payment) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: _bgAccent,
        border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE')),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'AMOUNT PAID',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _navyPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  currencyFormat.format(payment.amount),
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: _navyPrimary,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'In Words: ${payment.amountInWords}',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontStyle: pw.FontStyle.italic,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: payment.isOnline ? PdfColor.fromHex('#DBEAFE') : PdfColor.fromHex('#FEF3C7'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              payment.paymentType.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: payment.isOnline ? PdfColor.fromHex('#1E40AF') : PdfColor.fromHex('#92400E'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Attachments Info ─────────────────────────────────────────────────────

  static pw.Widget _buildAttachmentsSummary(int count) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: _bgLight,
        border: pw.Border.all(color: _dividerColor),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            '📎 Attached Bill Screenshots / Proof: ',
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _navyPrimary),
          ),
          pw.Text(
            '$count photo${count > 1 ? 's' : ''} attached (see following pages for full size)',
            style: pw.TextStyle(fontSize: 8.5, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSingleEmbeddedImage(Uint8List bytes, String title) {
    try {
      final imageProvider = pw.MemoryImage(bytes);
      return pw.Container(
        height: 140,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _dividerColor),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.ClipRRect(
          horizontalRadius: 4,
          verticalRadius: 4,
          child: pw.Image(
            imageProvider,
            fit: pw.BoxFit.contain,
          ),
        ),
      );
    } catch (_) {
      return pw.Container(
        height: 40,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _dividerColor),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        alignment: pw.Alignment.center,
        child: pw.Text('[Bill image attached]',
            style: pw.TextStyle(fontSize: 8, color: _textSecondary)),
      );
    }
  }

  static pw.Widget _buildAttachmentImage(Uint8List bytes) {
    try {
      final imageProvider = pw.MemoryImage(bytes);
      return pw.ClipRRect(
        horizontalRadius: 6,
        verticalRadius: 6,
        child: pw.Image(
          imageProvider,
          fit: pw.BoxFit.contain,
        ),
      );
    } catch (_) {
      return pw.Text(
        '[Unable to render attachment image]',
        style: pw.TextStyle(color: _textSecondary, fontSize: 10),
      );
    }
  }

  // ─── Footer ───────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter(PaymentDetailsModel payment) {
    return pw.Container(
      color: _bgLight,
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'AKTS Official Record',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _navyPrimary,
                ),
              ),
              pw.Text(
                'Generated on: ${DateFormatter.toDisplayDateTime(DateTime.now())}',
                style: pw.TextStyle(fontSize: 7.5, color: _textSecondary),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 110,
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: _navyPrimary, width: 1)),
                ),
                padding: const pw.EdgeInsets.only(top: 3),
                child: pw.Text(
                  'Authorized Signatory',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: _navyPrimary,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Attachment Page Header & Footer ──────────────────────────────────────

  static pw.Widget _buildAttachmentPageHeader(
      PaymentDetailsModel payment, int currentIndex, int totalCount) {
    return pw.Container(
      color: _navyPrimary,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'BILL SCREENSHOT / PAYMENT PROOF',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.Text(
                'Shop: ${payment.shopName} | Bill No: ${payment.billNumber}',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: _gold,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: const PdfColor(1, 1, 1, 0.15),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'PHOTO $currentIndex OF $totalCount',
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildAttachmentPageFooter(PaymentDetailsModel payment) {
    return pw.Container(
      color: _bgLight,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Voucher: ${payment.voucherNumber} | Amount: ₹${payment.amount.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 8, color: _textSecondary),
          ),
          pw.Text(
            AppConstants.organizationNameEnglish,
            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _navyPrimary),
          ),
        ],
      ),
    );
  }
}
