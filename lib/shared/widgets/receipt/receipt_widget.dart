// lib/shared/widgets/receipt/receipt_widget.dart
// AKTS Receipt Flutter Widget — faithfully reproduces the visual design
// Used for: screen preview, PDF generation template reference

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../features/receipts/data/models/receipt_model.dart';

/// The primary AKTS receipt widget.
/// This widget faithfully reproduces the organization's receipt design:
/// - Navy blue header with Telugu + English org name
/// - Dark title bar with Telugu receipt title
/// - Dotted field separators
/// - QR verification section
/// - Signature areas
class ReceiptWidget extends StatelessWidget {
  final ReceiptModel receipt;
  final bool compact; // Used for A4 bulk print layout
  final double scale;

  const ReceiptWidget({
    super.key,
    required this.receipt,
    this.compact = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      alignment: Alignment.topCenter,
      child: compact ? _buildCompactReceipt() : _buildFullReceipt(),
    );
  }

  // ─── Full Receipt (Screen Preview & Single PDF) ───────────────────────────

  Widget _buildFullReceipt() {
    return Container(
      width: 595, // A4 width in points approximation
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.navyPrimary, width: 2),
        boxShadow: AppColors.receiptShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          _buildTitleBar(),
          _buildFieldsSection(),
          _buildBottomSection(),
        ],
      ),
    );
  }

  // ─── Header (Navy Blue with Logo + Org Names) ─────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          // Logo circle
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
            child: Center(
              child: Text(
                'AKTS',
                style: GoogleFonts.lato(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navyPrimary,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Organization names
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppConstants.organizationNameTelugu,
                  style: GoogleFonts.notoSansTelugu(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(
                  AppConstants.organizationNameEnglish,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  'Kalpakkam, Tamil Nadu',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textOnNavyMuted,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Receipt number badge on the right
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'REGD.',
                    style: GoogleFonts.lato(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'NO.',
                    style: GoogleFonts.lato(
                      fontSize: 7,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
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

  // ─── Title Bar ────────────────────────────────────────────────────────────

  Widget _buildTitleBar() {
    return Container(
      color: AppColors.navyDeep,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        children: [
          Text(
            AppConstants.receiptTitleTelugu,
            style: GoogleFonts.notoSansTelugu(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            '(${AppConstants.receiptTitleEnglish})',
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textOnNavyMuted,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Fields Section ───────────────────────────────────────────────────────

  Widget _buildFieldsSection() {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          _ReceiptFieldRow(
            label: 'Receipt No.',
            value: receipt.receiptNumber,
            bold: true,
          ),
          _ReceiptFieldRow(
            label: 'Date',
            value: DateFormatter.toDisplayDate(receipt.date),
          ),
          _ReceiptFieldRow(
            label: 'Member Name',
            value: receipt.memberName,
            bold: true,
          ),
          _ReceiptFieldRow(
            label: 'AKTS No.',
            value: receipt.aktsNumber,
          ),
          _ReceiptFieldRow(
            label: 'Membership Year',
            value: receipt.membershipYear,
          ),
          _ReceiptFieldRow(
            label: 'Amount Paid',
            value: currencyFormat.format(receipt.amount),
            bold: true,
            valueColor: AppColors.navyPrimary,
          ),
          _ReceiptAmountInWords(words: receipt.amountInWords),
          _ReceiptFieldRow(
            label: 'Payment Mode',
            value: receipt.paymentMode,
          ),
          if (receipt.transactionId != null && receipt.transactionId!.isNotEmpty)
            _ReceiptFieldRow(
              label: 'Transaction ID',
              value: receipt.transactionId!,
            ),
          if (receipt.remarks != null && receipt.remarks!.isNotEmpty)
            _ReceiptFieldRow(
              label: 'Remarks',
              value: receipt.remarks!,
            ),
          // Status badge for revoked receipts
          if (receipt.isRevoked)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.statusRevokedLight,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.statusRevoked),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cancel, color: AppColors.statusRevoked, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '⚠ THIS RECEIPT HAS BEEN REVOKED',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.statusRevoked,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Bottom Section: QR + Signatures ────────────────────────────────────

  Widget _buildBottomSection() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.navyPrimary, width: 1.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signature section (left)
          Expanded(
            flex: 3,
            child: _buildSignatureSection(),
          ),
          // QR verification section (right)
          Expanded(
            flex: 2,
            child: _buildQrSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Member Signature',
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            height: 1,
            width: double.infinity,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 20),
          Text(
            'Treasurer / Receiver',
            style: GoogleFonts.lato(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 28),
          Container(
            height: 1,
            width: double.infinity,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          // Footer text
          Text(
            'This is a computer-generated receipt.',
            style: GoogleFonts.lato(
              fontSize: 8,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.receiptVerifyBg,
        border: Border(
          left: BorderSide(color: AppColors.navyPrimary, width: 1.5),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.navyPrimary, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: QrImageView(
              data: receipt.verificationUrl,
              version: QrVersions.auto,
              size: 100,
              gapless: true,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: AppColors.navyPrimary,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Verified badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: receipt.isRevoked
                  ? AppColors.statusRevokedLight
                  : AppColors.statusValidLight,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: receipt.isRevoked
                    ? AppColors.statusRevoked
                    : AppColors.statusValid,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  receipt.isRevoked ? Icons.cancel : Icons.verified,
                  size: 10,
                  color: receipt.isRevoked
                      ? AppColors.statusRevoked
                      : AppColors.statusValid,
                ),
                const SizedBox(width: 3),
                Text(
                  receipt.isRevoked ? 'REVOKED' : 'AUTHENTICITY\nVERIFIED',
                  style: GoogleFonts.lato(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    color: receipt.isRevoked
                        ? AppColors.statusRevoked
                        : AppColors.statusValid,
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // UUID display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Text(
              'UUID:\n${_truncateUuid(receipt.verificationId)}',
              style: GoogleFonts.robotoMono(
                fontSize: 6.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Scan to verify',
            style: GoogleFonts.lato(
              fontSize: 7,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Compact Receipt (for A4 Bulk Print) ─────────────────────────────────

  Widget _buildCompactReceipt() {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.navyPrimary, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Compact header
          Container(
            color: AppColors.navyPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              children: [
                Text(
                  AppConstants.organizationNameEnglish,
                  style: GoogleFonts.lato(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  AppConstants.receiptTitleEnglish,
                  style: GoogleFonts.lato(
                    fontSize: 6.5,
                    color: AppColors.textOnNavyMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Compact fields + QR
          Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fields column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompactField(label: 'No', value: receipt.receiptNumber),
                      _CompactField(
                          label: 'Date',
                          value: DateFormatter.toDisplayDate(receipt.date)),
                      _CompactField(label: 'Name', value: receipt.memberName),
                      _CompactField(
                          label: 'AKTS', value: receipt.aktsNumber),
                      _CompactField(
                          label: 'Year', value: receipt.membershipYear),
                      _CompactField(
                          label: 'Amt',
                          value: currencyFormat.format(receipt.amount),
                          bold: true),
                      _CompactField(label: 'Mode', value: receipt.paymentMode),
                      if (receipt.transactionId != null &&
                          receipt.transactionId!.isNotEmpty)
                        _CompactField(
                            label: 'TxnID',
                            value: receipt.transactionId!,
                            maxLines: 1),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // QR + signatures column
                Column(
                  children: [
                    // QR code - must remain scannable
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                            color: AppColors.navyPrimary, width: 0.5),
                      ),
                      child: QrImageView(
                        data: receipt.verificationUrl,
                        version: QrVersions.auto,
                        size: 52,
                        gapless: true,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppColors.navyPrimary,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      receipt.isRevoked ? '⚠ REVOKED' : '✓ VERIFIED',
                      style: GoogleFonts.lato(
                        fontSize: 5.5,
                        fontWeight: FontWeight.w800,
                        color: receipt.isRevoked
                            ? AppColors.statusRevoked
                            : AppColors.statusValid,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Signature lines
                    _CompactSignatureLine(label: 'Member'),
                    const SizedBox(height: 6),
                    _CompactSignatureLine(label: 'Treasurer'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _truncateUuid(String uuid) {
    if (uuid.length <= 23) return uuid;
    return '${uuid.substring(0, 8)}-...\n...${uuid.substring(uuid.length - 12)}';
  }
}

// ─── Subwidgets ───────────────────────────────────────────────────────────────

/// A field row with label and dotted separator leading to value
class _ReceiptFieldRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _ReceiptFieldRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          // Label with colon
          Text(
            '$label :',
            style: GoogleFonts.lato(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          // Value immediately following the label
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: valueColor ?? AppColors.textPrimary,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Amount in words display (with aligned label)
class _ReceiptAmountInWords extends StatelessWidget {
  final String words;

  const _ReceiptAmountInWords({required this.words});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'Amount in Words :',
            style: GoogleFonts.lato(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              words,
              style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact field for A4 bulk print layout
class _CompactField extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final int maxLines;

  const _CompactField({
    required this.label,
    required this.value,
    this.bold = false,
    this.maxLines = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 6,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            ': ',
            style: GoogleFonts.lato(fontSize: 6, color: AppColors.textMuted),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 6.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact signature line for bulk print
class _CompactSignatureLine extends StatelessWidget {
  final String label;

  const _CompactSignatureLine({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 62,
          height: 0.5,
          color: AppColors.textMuted,
        ),
        Text(
          label,
          style: GoogleFonts.lato(
            fontSize: 5.5,
            color: AppColors.textMuted,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
