// lib/features/bulk_print/presentation/screens/bulk_print_screen.dart
// A4 bulk print screen: select receipts → generate 2×5 PDF

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../providers/bulk_print_provider.dart';
import '../../../receipts/presentation/providers/receipt_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/common/receipt_list_tile.dart';
import '../../../../shared/widgets/common/loading_overlay.dart';
import '../../../pdf/services/bulk_print_pdf_service.dart';

class BulkPrintScreen extends ConsumerStatefulWidget {
  const BulkPrintScreen({super.key});

  @override
  ConsumerState<BulkPrintScreen> createState() => _BulkPrintScreenState();
}

class _BulkPrintScreenState extends ConsumerState<BulkPrintScreen> {
  String? _selectedYear;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReceipts();
    });
  }

  Future<void> _loadReceipts() async {
    // Load receipts from history into bulk print controller
    await ref.read(receiptHistoryControllerProvider.notifier).loadReceipts();
    final history = ref.read(receiptHistoryControllerProvider);
    ref.read(bulkPrintControllerProvider.notifier).setReceipts(
          history.receipts.where((r) => r.isValid).toList(),
        );
  }

  Future<void> _generateA4Pdf() async {
    final bulkState = ref.read(bulkPrintControllerProvider);
    if (!bulkState.hasSelection) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one receipt'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    ref.read(bulkPrintControllerProvider.notifier).setGenerating(true);

    try {
      final receipts = bulkState.selectedReceipts;
      final pdfBytes = await BulkPrintPdfService.generateBulkPdf(receipts);

      final totalPages = BulkPrintPdfService.calculateTotalPages(receipts.length);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Generated ${receipts.length} receipts across $totalPages page(s)',
            ),
            backgroundColor: AppColors.statusValid,
          ),
        );

        await Printing.layoutPdf(
          onLayout: (_) async => pdfBytes,
          name: 'AKTS_BulkPrint_${receipts.length}_receipts.pdf',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF generation failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(bulkPrintControllerProvider.notifier).setGenerating(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ReceiptHistoryState>(receiptHistoryControllerProvider, (_, next) {
      ref.read(bulkPrintControllerProvider.notifier).setReceipts(
        next.receipts.where((r) => r.isValid).toList(),
      );
    });

    final bulkState = ref.watch(bulkPrintControllerProvider);
    final historyState = ref.watch(receiptHistoryControllerProvider);

    return LoadingOverlay(
      isLoading: bulkState.isGenerating || historyState.isLoading,
      message: bulkState.isGenerating ? 'Generating A4 PDF...' : 'Loading receipts...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('A4 Bulk Print'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
        ),
        body: Column(
          children: [
            // Selection controls
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Info bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.navyPrimary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.navyPrimary.withOpacity(0.15)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.navyPrimary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '2 columns × 5 rows = 10 receipts per A4 page',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: AppColors.navyPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Selection controls row
                  Row(
                    children: [
                      // Select All
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              ref.read(bulkPrintControllerProvider.notifier).selectAll(),
                          child: Text(
                            'Select All (${bulkState.allReceipts.length})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Clear
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              ref.read(bulkPrintControllerProvider.notifier).clearSelection(),
                          child: const Text('Clear', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // By year
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedYear,
                          isDense: true,
                          decoration: const InputDecoration(
                            labelText: 'By Year',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Year')),
                            ...AppConstants.membershipYears.map((y) =>
                                DropdownMenuItem(value: y, child: Text(y))),
                          ],
                          onChanged: (v) {
                            setState(() => _selectedYear = v);
                            if (v != null) {
                              ref.read(bulkPrintControllerProvider.notifier)
                                  .selectByYear(v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Selection summary
            if (bulkState.hasSelection)
              Container(
                color: AppColors.navyPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${bulkState.selectionCount} selected',
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${BulkPrintPdfService.calculateTotalPages(bulkState.selectionCount)} page(s)',
                      style: GoogleFonts.lato(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Receipts list with checkboxes
            Expanded(
              child: bulkState.allReceipts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.print_disabled_outlined,
                              size: 56, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          Text(
                            'No valid receipts available',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: bulkState.allReceipts.length,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemBuilder: (context, index) {
                        final receipt = bulkState.allReceipts[index];
                        return ReceiptListTile(
                          receipt: receipt,
                          showCheckbox: true,
                          isSelected: bulkState.isSelected(receipt.id),
                          onCheckboxChanged: (selected) {
                            ref.read(bulkPrintControllerProvider.notifier)
                                .toggleSelection(receipt.id);
                          },
                          onTap: () {
                            ref.read(bulkPrintControllerProvider.notifier)
                                .toggleSelection(receipt.id);
                          },
                        );
                      },
                    ),
            ),

            // Bottom generate button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.dividerColor)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: bulkState.hasSelection && !bulkState.isGenerating
                      ? _generateA4Pdf
                      : null,
                  icon: const Icon(Icons.print, size: 20),
                  label: Text(
                    bulkState.hasSelection
                        ? 'GENERATE A4 PDF (${bulkState.selectionCount} receipts)'
                        : 'SELECT RECEIPTS FIRST',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
