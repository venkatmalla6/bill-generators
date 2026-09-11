// lib/features/payment_details/presentation/screens/payment_details_history_screen.dart
// Screen displaying history of all Payment Done Details with search, filters, and PDF export

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
import '../../data/models/payment_details_model.dart';

class PaymentDetailsHistoryScreen extends ConsumerStatefulWidget {
  const PaymentDetailsHistoryScreen({super.key});

  @override
  ConsumerState<PaymentDetailsHistoryScreen> createState() =>
      _PaymentDetailsHistoryScreenState();
}

class _PaymentDetailsHistoryScreenState
    extends ConsumerState<PaymentDetailsHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all' | 'online' | 'offline'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentsStreamProvider);
    final stats = ref.watch(paymentStatsProvider);
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Payment Done Records',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Payment Details',
            onPressed: () => context.push('/payment-details/create'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.navyPrimary,
        onRefresh: () async {
          ref.invalidate(paymentsStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats cards
              _buildStatsSection(stats, currencyFormat),
              const SizedBox(height: 18),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by shop, bill no, or UTR...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.navyPrimary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.dividerColor),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 12),

              // Filter Chips
              Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Online', 'online'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Offline', 'offline'),
                ],
              ),
              const SizedBox(height: 16),

              // Payments list
              paymentsAsync.when(
                data: (payments) {
                  // Apply filters
                  var filtered = payments.where((p) {
                    if (_filterType == 'online' && !p.isOnline) return false;
                    if (_filterType == 'offline' && p.isOnline) return false;
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      final matchShop = p.shopName.toLowerCase().contains(q);
                      final matchBill = p.billNumber.toLowerCase().contains(q);
                      final matchVoucher = p.voucherNumber.toLowerCase().contains(q);
                      final matchUtr = p.transactionDetails?.toLowerCase().contains(q) ?? false;
                      return matchShop || matchBill || matchVoucher || matchUtr;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const Icon(Icons.receipt_outlined,
                                size: 54, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              payments.isEmpty
                                  ? 'No payment records added yet'
                                  : 'No payments match your search',
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  context.push('/payment-details/create'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.navyPrimary,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Payment Details'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final payment = filtered[index];
                      return _buildPaymentCard(payment);
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(child: Text('Error loading payments: $e')),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/payment-details/create'),
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          'Add Payment',
          style: GoogleFonts.lato(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: GoogleFonts.lato(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppColors.textPrimary,
      ),
      selectedColor: AppColors.navyPrimary,
      checkmarkColor: Colors.white,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.navyPrimary : AppColors.dividerColor,
        ),
      ),
      onSelected: (_) => setState(() => _filterType = value),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats, NumberFormat format) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Payments',
                  format.format(stats['totalAmount'] ?? 0),
                  '${stats['totalBills'] ?? 0} bills',
                  Icons.account_balance_wallet,
                  AppColors.navyPrimary,
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.dividerColor),
              Expanded(
                child: _buildStatItem(
                  'Online Paid',
                  format.format(stats['onlineAmount'] ?? 0),
                  '${stats['onlineCount'] ?? 0} online',
                  Icons.phone_android,
                  Colors.blue.shade700,
                ),
              ),
              Container(width: 1, height: 44, color: AppColors.dividerColor),
              Expanded(
                child: _buildStatItem(
                  'Offline Paid',
                  format.format(stats['offlineAmount'] ?? 0),
                  '${stats['offlineCount'] ?? 0} cash/other',
                  Icons.money,
                  Colors.teal.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String title, String val, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.lato(fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            val,
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: GoogleFonts.lato(fontSize: 10, color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentDetailsModel payment) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 2,
    );

    return InkWell(
      onTap: () => context.push('/payment-details/${payment.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: payment.isOnline
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                payment.isOnline ? Icons.phone_android : Icons.storefront,
                color: payment.isOnline ? Colors.blue.shade800 : Colors.amber.shade900,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          payment.shopName,
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        currencyFormat.format(payment.amount),
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        'Bill: ${payment.billNumber}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${DateFormatter.toDisplayDate(payment.date)}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: payment.isOnline
                              ? Colors.blue.withOpacity(0.08)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${payment.paymentType} • ${payment.paymentMode}',
                          style: GoogleFonts.lato(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: payment.isOnline ? Colors.blue.shade800 : Colors.grey.shade800,
                          ),
                        ),
                      ),
                      if (payment.hasImages) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.camera_alt, size: 10, color: AppColors.navyPrimary),
                              const SizedBox(width: 3),
                              Text(
                                '${payment.imagesBase64.length} photo${payment.imagesBase64.length > 1 ? 's' : ''}',
                                style: GoogleFonts.lato(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.navyPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
