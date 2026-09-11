// lib/features/dashboard/presentation/screens/dashboard_screen.dart
// AKTS Professional Dashboard

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../receipts/presentation/providers/receipt_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/common/stat_card.dart';
import '../../../../shared/widgets/common/receipt_list_tile.dart';
import '../../../../shared/widgets/common/receipt_table_widget.dart';
import '../../../receipts/data/models/receipt_model.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh receipts stream on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(receiptsStreamProvider);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final receiptsAsync = ref.watch(receiptsStreamProvider);
    final currencyFormat = NumberFormat.currency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppConstants.organizationShort,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        actions: [
          // Notifications placeholder
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
            tooltip: 'Notifications',
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: 'Settings',
          ),
          // User avatar menu
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: CircleAvatar(
              backgroundColor: Colors.white.withOpacity(0.2),
              radius: 18,
              child: Text(
                user?.displayName.isNotEmpty == true
                    ? user!.displayName[0].toUpperCase()
                    : 'U',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'User',
                      style: GoogleFonts.lato(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.lato(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    if (user?.isAdmin == true)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.navyPrimary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ADMIN',
                          style: GoogleFonts.lato(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18, color: AppColors.error),
                    const SizedBox(width: 8),
                    Text('Sign Out',
                        style: GoogleFonts.lato(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.navyPrimary,
        onRefresh: () async {
          ref.invalidate(receiptsStreamProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome banner
              _buildWelcomeBanner(user?.displayName ?? 'User'),
              const SizedBox(height: 20),

              // Stats cards
              Text(
                'Overview',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              statsAsync.when(
                data: (stats) => _buildStatsRow(stats, currencyFormat),
                loading: () => _buildStatsSkeleton(),
                error: (e, _) => Text('Failed to load stats: $e'),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 24),

              // Recent Receipts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Receipts',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.receiptHistory),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              receiptsAsync.when(
                data: (receipts) {
                  if (receipts.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            Text(
                              'No receipts yet',
                              style: GoogleFonts.lato(
                                fontSize: 15,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  context.push(AppRoutes.createReceipt),
                              child: const Text('Create First Receipt'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final recent = receipts.take(5).toList();
                  return _buildRecentReceipts(recent);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createReceipt),
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Receipt',
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(String name) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting,',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  name,
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.organizationNameEnglish,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: AppColors.gold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
      Map<String, dynamic> stats, NumberFormat currencyFormat) {
    final cards = [
      StatCard(
        title: 'Total Receipts',
        value: '${stats['totalReceipts'] ?? 0}',
        subtitle: '${stats['validReceipts'] ?? 0} valid',
        icon: Icons.receipt_long,
        color: AppColors.statCard1,
        onTap: () => context.push(AppRoutes.receiptHistory),
      ),
      StatCard(
        title: 'Total Collection',
        value: currencyFormat.format(stats['totalAmount'] ?? 0),
        icon: Icons.account_balance_wallet_outlined,
        color: AppColors.statCard2,
      ),
      StatCard(
        title: "Today's Receipts",
        value: '${stats['todayReceipts'] ?? 0}',
        subtitle: currencyFormat.format(stats['todayAmount'] ?? 0),
        icon: Icons.today_outlined,
        color: AppColors.statCard3,
      ),
      StatCard(
        title: 'Monthly Collection',
        value: currencyFormat.format(stats['monthAmount'] ?? 0),
        subtitle: '${stats['monthReceipts'] ?? 0} receipts',
        icon: Icons.calendar_month_outlined,
        color: AppColors.statCard4,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return SizedBox(
            height: 140,
            child: Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(child: cards[i]),
                ],
              ],
            ),
          );
        } else {
          return SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => SizedBox(
                width: 210,
                child: cards[i],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildStatsSkeleton() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 720) {
          return SizedBox(
            height: 140,
            child: Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: i == 0 ? 0 : 6, right: i == 3 ? 0 : 6),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.dividerColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) => Container(
                width: 210,
                decoration: BoxDecoration(
                  color: AppColors.dividerColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildQuickActions() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 720 ? 6 : 3;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.95,
          children: [
            QuickActionButton(
              label: 'CREATE\nRECEIPT',
              icon: Icons.add_circle_outline,
              color: AppColors.navyPrimary,
              onTap: () => context.push(AppRoutes.createReceipt),
            ),
            QuickActionButton(
              label: 'PAYMENT\nDONE',
              icon: Icons.payments_outlined,
              color: const Color(0xFFD97706),
              onTap: () => context.push(AppRoutes.createPaymentDetails),
            ),
            QuickActionButton(
              label: 'PAYMENT\nHISTORY',
              icon: Icons.receipt_long_outlined,
              color: const Color(0xFF0284C7),
              onTap: () => context.push(AppRoutes.paymentDetails),
            ),
            QuickActionButton(
              label: 'RECEIPT\nHISTORY',
              icon: Icons.history,
              color: AppColors.navyLight,
              onTap: () => context.push(AppRoutes.receiptHistory),
            ),
            QuickActionButton(
              label: 'SCAN\nQR',
              icon: Icons.qr_code_scanner,
              color: AppColors.navyMedium,
              onTap: () => context.push(AppRoutes.scanQr),
            ),
            QuickActionButton(
              label: 'A4\nPRINT',
              icon: Icons.print_outlined,
              color: AppColors.navyDark,
              onTap: () => context.push(AppRoutes.bulkPrint),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentReceipts(List<ReceiptModel> recent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        if (isWide) {
          return ReceiptTableWidget(
            receipts: recent,
            onTap: (r) => context.push(AppRoutes.receiptPreviewPath(r.id)),
            onPdf: (r) => context.push(AppRoutes.receiptPreviewPath(r.id)),
            onShare: (r) => context.push(AppRoutes.receiptPreviewPath(r.id)),
          );
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            itemBuilder: (context, index) {
              final receipt = recent[index];
              return ReceiptListTile(
                receipt: receipt,
                onTap: () => context.push(
                    AppRoutes.receiptPreviewPath(receipt.id)),
                onPdf: () => context.push(
                    AppRoutes.receiptPreviewPath(receipt.id)),
                onShare: () => context.push(
                    AppRoutes.receiptPreviewPath(receipt.id)),
              );
            },
          );
        }
      },
    );
  }
}
