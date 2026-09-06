// lib/features/receipts/presentation/screens/receipt_history_screen.dart
// Receipt history with search, filters, and actions

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import '../providers/receipt_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/common/receipt_list_tile.dart';
import '../../../../shared/widgets/common/receipt_table_widget.dart';
import '../../../../shared/widgets/common/loading_overlay.dart';
import '../../../pdf/services/receipt_pdf_service.dart';
import '../../data/models/receipt_model.dart';

class ReceiptHistoryScreen extends ConsumerStatefulWidget {
  const ReceiptHistoryScreen({super.key});

  @override
  ConsumerState<ReceiptHistoryScreen> createState() =>
      _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends ConsumerState<ReceiptHistoryScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedPaymentMode;
  String? _selectedYear;
  bool _showFilters = false;
  bool _isGeneratingPdf = false;
  bool _isTableView = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receiptHistoryControllerProvider.notifier).loadReceipts();
    });

    _searchController.addListener(() {
      ref.read(receiptHistoryControllerProvider.notifier).applyFilters(
            searchQuery: _searchController.text,
            statusFilter: _selectedStatus,
            paymentModeFilter: _selectedPaymentMode,
            membershipYearFilter: _selectedYear,
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(receiptHistoryControllerProvider.notifier).applyFilters(
          searchQuery: _searchController.text,
          statusFilter: _selectedStatus,
          paymentModeFilter: _selectedPaymentMode,
          membershipYearFilter: _selectedYear,
        );
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedPaymentMode = null;
      _selectedYear = null;
    });
    ref.read(receiptHistoryControllerProvider.notifier).clearFilters();
  }

  Future<void> _generatePdf(String receiptId) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final history = ref.read(receiptHistoryControllerProvider);
      final receipt =
          history.receipts.firstWhere((r) => r.id == receiptId);
      final pdfBytes = await ReceiptPdfService.generateSingleReceiptPdf(receipt);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename:
            'AKTS_${receipt.receiptNumber.replaceAll('/', '_')}.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  Future<void> _revokeReceipt(String receiptId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Revoke Receipt'),
        content: const Text(
          'Are you sure you want to revoke this receipt? This cannot be undone.',
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
          .revokeReceipt(receiptId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Receipt revoked successfully'
                : 'Failed to revoke'),
            backgroundColor: success ? AppColors.statusValid : AppColors.error,
          ),
        );
        if (success) {
          ref.read(receiptHistoryControllerProvider.notifier).loadReceipts();
        }
      }
    }
  }

  Future<void> _deleteReceipt(ReceiptModel receipt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Receipt'),
        content: Text(
          'Are you sure you want to permanently delete receipt "${receipt.receiptNumber}" for ${receipt.memberName}?\n\nThis action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final errorMsg = await ref
          .read(receiptHistoryControllerProvider.notifier)
          .deleteReceipt(receipt.id);

      if (mounted) {
        if (errorMsg == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Receipt "${receipt.receiptNumber}" deleted successfully'),
              backgroundColor: AppColors.statusValid,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete receipt: $errorMsg'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(receiptHistoryControllerProvider);

    return LoadingOverlay(
      isLoading: _isGeneratingPdf,
      message: 'Generating PDF...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Receipt History'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => context.pop(),
          ),
          actions: [
            // Filter toggle
            IconButton(
              icon: Badge(
                isLabelVisible: _selectedStatus != null ||
                    _selectedPaymentMode != null ||
                    _selectedYear != null,
                label: const Text('!'),
                child: const Icon(Icons.filter_list),
              ),
              onPressed: () => setState(() => _showFilters = !_showFilters),
              tooltip: 'Filters',
            ),
            // Table / Card view toggle
            IconButton(
              icon: Icon(_isTableView
                  ? Icons.view_agenda_outlined
                  : Icons.table_chart_outlined),
              onPressed: () => setState(() => _isTableView = !_isTableView),
              tooltip:
                  _isTableView ? 'Switch to Card View' : 'Switch to Table View',
            ),
            // Refresh
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () =>
                  ref.read(receiptHistoryControllerProvider.notifier).loadReceipts(),
              tooltip: 'Refresh',
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name, receipt#, AKTS#...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
              ),
            ),

            // Filter panel
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              color: Colors.white,
              height: _showFilters ? null : 0,
              child: _showFilters
                  ? _buildFilterPanel()
                  : const SizedBox.shrink(),
            ),

            // Results count
            if (historyState.searchQuery.isNotEmpty ||
                _selectedStatus != null ||
                _selectedPaymentMode != null ||
                _selectedYear != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.navyPrimary.withOpacity(0.05),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${historyState.filtered.length} result(s) found',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.navyPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearFilters,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero),
                      child: const Text('Clear All',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),

            // List
            Expanded(
              child: historyState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.navyPrimary),
                    )
                  : historyState.filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 56, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                historyState.receipts.isEmpty
                                    ? 'No receipts created yet'
                                    : 'No receipts match your search',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.navyPrimary,
                          onRefresh: () async => ref
                              .read(receiptHistoryControllerProvider.notifier)
                              .loadReceipts(),
                          child: _isTableView
                              ? SingleChildScrollView(
                                  padding: const EdgeInsets.all(16),
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: ReceiptTableWidget(
                                    receipts: historyState.filtered,
                                    onTap: (receipt) => context.push(
                                        AppRoutes.receiptPreviewPath(
                                            receipt.id)),
                                    onPdf: (receipt) =>
                                        _generatePdf(receipt.id),
                                    onShare: (receipt) =>
                                        _generatePdf(receipt.id),
                                    onRevoke: (receipt) => receipt.isValid
                                        ? _revokeReceipt(receipt.id)
                                        : null,
                                    onDelete: (receipt) =>
                                        _deleteReceipt(receipt),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: historyState.filtered.length,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  itemBuilder: (context, index) {
                                    final receipt =
                                        historyState.filtered[index];
                                    return ReceiptListTile(
                                      receipt: receipt,
                                      onTap: () => context.push(
                                          AppRoutes.receiptPreviewPath(
                                              receipt.id)),
                                      onPdf: () => _generatePdf(receipt.id),
                                      onShare: () => _generatePdf(receipt.id),
                                      onRevoke: receipt.isValid
                                          ? () => _revokeReceipt(receipt.id)
                                          : null,
                                      onDelete: () => _deleteReceipt(receipt),
                                    );
                                  },
                                ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Status')),
                    ...['valid', 'revoked', 'cancelled'].map((s) =>
                        DropdownMenuItem(
                          value: s,
                          child: Text(s.toUpperCase()),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedStatus = v);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPaymentMode,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Payment Mode',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Modes')),
                    ...AppConstants.paymentModes.map((m) =>
                        DropdownMenuItem(value: m, child: Text(m))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedPaymentMode = v);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedYear,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Years')),
                    ...AppConstants.membershipYears.map((y) =>
                        DropdownMenuItem(value: y, child: Text(y))),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedYear = v);
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
