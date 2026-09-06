// lib/features/verification/presentation/screens/verification_screen.dart
// Public receipt verification screen — no authentication required

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../receipts/presentation/providers/receipt_provider.dart';
import '../../../receipts/data/models/receipt_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/date_formatter.dart';

class VerificationScreen extends ConsumerWidget {
  final String verificationId;

  const VerificationScreen({super.key, required this.verificationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(verifyReceiptProvider(verificationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Receipt Verification'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: receiptAsync.when(
        data: (receipt) {
          if (receipt == null) {
            return _buildNotFound(context);
          }
          if (receipt.isRevoked) {
            return _buildRevoked(context, receipt);
          }
          return _buildValid(context, receipt);
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.navyPrimary),
              SizedBox(height: 16),
              Text('Verifying receipt...'),
            ],
          ),
        ),
        error: (e, _) => _buildError(context, e.toString()),
      ),
    );
  }

  // ─── Valid Receipt ────────────────────────────────────────────────────────

  Widget _buildValid(BuildContext context, ReceiptModel receipt) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Success banner
          _buildStatusBanner(
            icon: Icons.verified,
            title: '✓ AUTHENTICITY VERIFIED',
            subtitle: 'This is a genuine AKTS receipt',
            color: AppColors.statusValid,
            bgColor: AppColors.statusValidLight,
          ),
          const SizedBox(height: 20),

          // Organization header
          _buildOrgHeader(),
          const SizedBox(height: 16),

          // Receipt details card
          _buildDetailCard(
            title: 'Receipt Information',
            children: [
              _DetailRow(label: 'Receipt No.', value: receipt.receiptNumber, bold: true),
              _DetailRow(label: 'Date', value: DateFormatter.toDisplayDate(receipt.date)),
              _DetailRow(label: 'Member Name', value: receipt.memberName, bold: true),
              _DetailRow(label: 'AKTS No.', value: receipt.aktsNumber),
              _DetailRow(label: 'Membership Year', value: receipt.membershipYear),
              _DetailRow(
                label: 'Amount Paid',
                value: currencyFormat.format(receipt.amount),
                bold: true,
                valueColor: AppColors.navyPrimary,
              ),
              _DetailRow(label: 'Payment Mode', value: receipt.paymentMode),
              if (receipt.transactionId != null && receipt.transactionId!.isNotEmpty)
                _DetailRow(label: 'Transaction ID', value: receipt.transactionId!),
              _DetailRow(
                label: 'Status',
                value: 'VALID',
                valueColor: AppColors.statusValid,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Verification ID card
          _buildVerificationIdCard(receipt.verificationId),
          const SizedBox(height: 24),

          // Verify again button
          Text(
            'Verification completed on ${DateFormatter.toFullDateTime(DateTime.now())}',
            style: GoogleFonts.lato(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Revoked Receipt ──────────────────────────────────────────────────────

  Widget _buildRevoked(BuildContext context, ReceiptModel receipt) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatusBanner(
            icon: Icons.cancel,
            title: '⚠ RECEIPT REVOKED',
            subtitle: 'This receipt has been revoked and is no longer valid',
            color: AppColors.statusRevoked,
            bgColor: AppColors.statusRevokedLight,
          ),
          const SizedBox(height: 20),
          _buildOrgHeader(),
          const SizedBox(height: 16),
          _buildDetailCard(
            title: 'Revoked Receipt Details',
            children: [
              _DetailRow(label: 'Receipt No.', value: receipt.receiptNumber),
              _DetailRow(label: 'Member Name', value: receipt.memberName),
              _DetailRow(label: 'AKTS No.', value: receipt.aktsNumber),
              _DetailRow(
                label: 'Status',
                value: 'REVOKED',
                valueColor: AppColors.statusRevoked,
                bold: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVerificationIdCard(receipt.verificationId),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.statusRevokedLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.statusRevoked.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.statusRevoked, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'If you believe this is an error, please contact '
                    '${AppConstants.organizationNameEnglish} directly.',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: AppColors.statusRevoked,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Not Found ────────────────────────────────────────────────────────────

  Widget _buildNotFound(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStatusBanner(
            icon: Icons.search_off,
            title: '✕ RECEIPT NOT FOUND',
            subtitle:
                'No receipt was found with this verification ID',
            color: AppColors.textSecondary,
            bgColor: AppColors.background,
          ),
          const SizedBox(height: 24),
          _buildOrgHeader(),
          const SizedBox(height: 24),
          _buildDetailCard(
            title: 'Verification Details',
            children: [
              _DetailRow(label: 'Verification ID', value: verificationId),
              _DetailRow(label: 'Result', value: 'NOT FOUND'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dividerColor),
            ),
            child: Text(
              'This QR code does not correspond to any AKTS receipt. '
              'It may be counterfeit, expired, or invalid. '
              'Please contact ${AppConstants.organizationNameEnglish} to report this.',
              style: GoogleFonts.lato(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Error ───────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Verification failed',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to verify receipt. Please check your internet connection and try again.',
              style: GoogleFonts.lato(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────

  Widget _buildStatusBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrgHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: AppColors.gold, width: 1.5),
            ),
            child: Center(
              child: Text(
                'AKTS',
                style: GoogleFonts.lato(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: AppColors.navyPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppConstants.organizationNameTelugu,
                  style: GoogleFonts.notoSansTelugu(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  AppConstants.organizationNameEnglish,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
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

  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navyPrimary,
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationIdCard(String verificationId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, size: 16, color: AppColors.navyPrimary),
              const SizedBox(width: 8),
              Text(
                'Verification UUID',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navyPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            verificationId,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
