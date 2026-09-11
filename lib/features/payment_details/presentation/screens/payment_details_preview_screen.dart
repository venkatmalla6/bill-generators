// lib/features/payment_details/presentation/screens/payment_details_preview_screen.dart
// Interactive preview, PDF viewer, print, and share screen for Payment Done Vouchers

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../services/payment_pdf_service.dart';
import '../providers/payment_details_provider.dart';

class PaymentDetailsPreviewScreen extends ConsumerStatefulWidget {
  final String paymentId;

  const PaymentDetailsPreviewScreen({
    super.key,
    required this.paymentId,
  });

  @override
  ConsumerState<PaymentDetailsPreviewScreen> createState() =>
      _PaymentDetailsPreviewScreenState();
}

class _PaymentDetailsPreviewScreenState
    extends ConsumerState<PaymentDetailsPreviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentAsync = ref.watch(paymentDetailsByIdProvider(widget.paymentId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Payment Voucher',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: GoogleFonts.lato(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(icon: Icon(Icons.picture_as_pdf, size: 20), text: 'PDF Document'),
            Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Voucher Details'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            tooltip: 'Dashboard',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: paymentAsync.when(
        data: (payment) {
          if (payment == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 54, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text(
                    'Payment record not found',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          final currencyFormat = NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹',
            decimalDigits: 2,
          );

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: PDF Viewer with Print & Share
              PdfPreview(
                build: (format) =>
                    PaymentPdfService.generatePaymentVoucherPdf(payment),
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                pdfFileName:
                    'Payment_${payment.voucherNumber.replaceAll('-', '_')}.pdf',
                actions: [
                  PdfPreviewAction(
                    icon: const Icon(Icons.share),
                    onPressed: (context, buildFn, pageFormat) async {
                      final bytes = await buildFn(pageFormat);
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename:
                            'Payment_${payment.voucherNumber.replaceAll('-', '_')}.pdf',
                      );
                    },
                  ),
                ],
              ),

              // Tab 2: Detailed Voucher Card View
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: AppColors.cardGradient,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  payment.voucherNumber,
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.statusValid,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PAYMENT DONE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            currencyFormat.format(payment.amount),
                            style: GoogleFonts.lato(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            payment.amountInWords,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: AppColors.gold,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Information details card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Details',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(Icons.storefront, 'Shop Name', payment.shopName),
                          _buildDetailRow(Icons.tag, 'Bill Number', payment.billNumber),
                          _buildDetailRow(Icons.calendar_today, 'Date', DateFormatter.toDisplayDate(payment.date)),
                          _buildDetailRow(
                            payment.isOnline ? Icons.phone_android : Icons.money,
                            'Payment Type',
                            '${payment.paymentType} (${payment.paymentMode})',
                          ),
                          if (payment.transactionDetails != null &&
                              payment.transactionDetails!.isNotEmpty)
                            _buildDetailRow(
                              Icons.receipt,
                              'Transaction Details',
                              payment.transactionDetails!,
                            ),
                          if (payment.remarks != null && payment.remarks!.isNotEmpty)
                            _buildDetailRow(
                              Icons.notes,
                              'Remarks / Purpose',
                              payment.remarks!,
                            ),
                          _buildDetailRow(
                            Icons.person_outline,
                            'Recorded By',
                            payment.createdBy.isNotEmpty ? payment.createdBy : 'Staff',
                          ),
                        ],
                      ),
                    ),

                    // Attached bill screenshots
                    if (payment.hasImages) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Attached Bill Screenshots / Proof',
                                  style: GoogleFonts.lato(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.navyPrimary,
                                  ),
                                ),
                                Text(
                                  '${payment.imageBytesList.length} photos',
                                  style: GoogleFonts.lato(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            for (int i = 0; i < payment.imageBytesList.length; i++) ...[
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.dividerColor),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.memory(
                                    payment.imageBytesList[i],
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load voucher: $e'),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.navyPrimary),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
