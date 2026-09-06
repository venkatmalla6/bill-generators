// lib/features/receipts/presentation/screens/receipt_preview_screen.dart
// Full receipt preview with PDF, print, and share actions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../providers/receipt_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/receipt/receipt_widget.dart';
import '../../../../shared/widgets/common/loading_overlay.dart';
import '../../../pdf/services/receipt_pdf_service.dart';

class ReceiptPreviewScreen extends ConsumerStatefulWidget {
  final String receiptId;

  const ReceiptPreviewScreen({super.key, required this.receiptId});

  @override
  ConsumerState<ReceiptPreviewScreen> createState() =>
      _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends ConsumerState<ReceiptPreviewScreen> {
  bool _isGeneratingPdf = false;

  Future<void> _handlePrint() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final receipt = ref.read(receiptByIdProvider(widget.receiptId)).value;
      if (receipt == null) return;

      final pdfBytes = await ReceiptPdfService.generateSingleReceiptPdf(receipt);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'AKTS_${receipt.receiptNumber.replaceAll('/', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handleSavePdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      final receipt = ref.read(receiptByIdProvider(widget.receiptId)).value;
      if (receipt == null) return;

      final pdfBytes = await ReceiptPdfService.generateSingleReceiptPdf(receipt);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: 'AKTS_${receipt.receiptNumber.replaceAll('/', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _handleSharePdf() async {
    await _handleSavePdf(); // share_plus via printing
  }

  Future<void> _handleRevoke() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Receipt'),
        content: const Text(
          'Are you sure you want to revoke this receipt?\n\n'
          'The receipt will be marked as REVOKED and will no longer be valid. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusRevoked),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await ref
          .read(createReceiptControllerProvider.notifier)
          .revokeReceipt(widget.receiptId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Receipt revoked successfully' : 'Failed to revoke receipt',
            ),
            backgroundColor: success ? AppColors.statusValid : AppColors.error,
          ),
        );
        if (success) {
          ref.invalidate(receiptByIdProvider(widget.receiptId));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptAsync = ref.watch(receiptByIdProvider(widget.receiptId));
    final createState = ref.watch(createReceiptControllerProvider);

    return LoadingOverlay(
      isLoading: _isGeneratingPdf || createState.isLoading,
      message: _isGeneratingPdf ? 'Generating PDF...' : 'Processing...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Receipt Preview'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
          actions: [
            // Print
            IconButton(
              icon: const Icon(Icons.print_outlined),
              onPressed: _handlePrint,
              tooltip: 'Print',
            ),
            // Share
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: _handleSharePdf,
              tooltip: 'Share PDF',
            ),
            // More options
            receiptAsync.maybeWhen(
              data: (receipt) => receipt != null && receipt.isValid
                  ? PopupMenuButton<String>(
                      offset: const Offset(0, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      onSelected: (value) {
                        if (value == 'revoke') _handleRevoke();
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'revoke',
                          child: Row(
                            children: [
                              const Icon(Icons.cancel_outlined,
                                  size: 18, color: AppColors.statusRevoked),
                              const SizedBox(width: 8),
                              Text(
                                'Revoke Receipt',
                                style:
                                    GoogleFonts.lato(color: AppColors.statusRevoked),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: receiptAsync.when(
          data: (receipt) {
            if (receipt == null) {
              return const Center(child: Text('Receipt not found'));
            }

            return Column(
              children: [
                // Receipt preview area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Receipt widget in scrollable view
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: AppColors.receiptShadow,
                          ),
                          child: ReceiptWidget(receipt: receipt),
                        ),
                        const SizedBox(height: 24),
                        // Verification info
                        _buildVerificationInfo(receipt.verificationUrl),
                      ],
                    ),
                  ),
                ),
                // Bottom action bar
                _buildBottomActions(),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.navyPrimary),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildVerificationInfo(String verificationUrl) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyPrimary.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.qr_code, color: AppColors.navyPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification URL',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  verificationUrl,
                  style: GoogleFonts.robotoMono(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _handleSavePdf,
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Save PDF'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _handlePrint,
              icon: const Icon(Icons.print, size: 18),
              label: Text(
                'Print',
                style: GoogleFonts.lato(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
