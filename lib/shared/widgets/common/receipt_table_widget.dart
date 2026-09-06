// lib/shared/widgets/common/receipt_table_widget.dart
// Responsive Tabular DataTable for receipts showing ID, Name, Date, Amount, Status & Actions

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../features/receipts/data/models/receipt_model.dart';

class ReceiptTableWidget extends StatelessWidget {
  final List<ReceiptModel> receipts;
  final ValueChanged<ReceiptModel>? onTap;
  final ValueChanged<ReceiptModel>? onPdf;
  final ValueChanged<ReceiptModel>? onShare;
  final ValueChanged<ReceiptModel>? onRevoke;
  final ValueChanged<ReceiptModel>? onDelete;

  const ReceiptTableWidget({
    super.key,
    required this.receipts,
    this.onTap,
    this.onPdf,
    this.onShare,
    this.onRevoke,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 720),
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.navyPrimary.withValues(alpha: 0.06),
            ),
            dataRowMinHeight: 56,
            dataRowMaxHeight: 64,
            horizontalMargin: 20,
            columnSpacing: 24,
            columns: [
              DataColumn(
                label: Text(
                  'ID / RECEIPT #',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'MEMBER NAME',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'DATE',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              DataColumn(
                numeric: true,
                label: Text(
                  'AMOUNT',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'STATUS',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'ACTIONS',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
            rows: receipts.asMap().entries.map((entry) {
              final index = entry.key;
              final receipt = entry.value;
              final isEven = index.isEven;

              Color statusColor;
              String statusLabel;
              IconData statusIcon;

              switch (receipt.status) {
                case AppConstants.statusRevoked:
                  statusColor = AppColors.statusRevoked;
                  statusLabel = 'REVOKED';
                  statusIcon = Icons.cancel_outlined;
                  break;
                case AppConstants.statusCancelled:
                  statusColor = AppColors.statusCancelled;
                  statusLabel = 'CANCELLED';
                  statusIcon = Icons.block_outlined;
                  break;
                default:
                  statusColor = AppColors.statusValid;
                  statusLabel = 'VALID';
                  statusIcon = Icons.check_circle_outline;
              }

              return DataRow(
                color: WidgetStateProperty.all(
                  isEven
                      ? Colors.white
                      : AppColors.background.withValues(alpha: 0.5),
                ),
                cells: [
                  // ID / Receipt number
                  DataCell(
                    InkWell(
                      onTap: onTap != null ? () => onTap!(receipt) : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            receipt.receiptNumber,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyPrimary,
                            ),
                          ),
                          if (receipt.aktsNumber.isNotEmpty)
                            Text(
                              receipt.aktsNumber,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // Member Name
                  DataCell(
                    InkWell(
                      onTap: onTap != null ? () => onTap!(receipt) : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.navyPrimary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Center(
                              child: Text(
                                receipt.memberName.isNotEmpty
                                    ? receipt.memberName[0].toUpperCase()
                                    : 'M',
                                style: GoogleFonts.lato(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navyPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            receipt.memberName,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Date
                  DataCell(
                    Text(
                      DateFormatter.toDisplayDate(receipt.date),
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Amount
                  DataCell(
                    Text(
                      currencyFormat.format(receipt.amount),
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyPrimary,
                      ),
                    ),
                  ),

                  // Status
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 10, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onTap != null)
                          _TableActionBtn(
                            icon: Icons.visibility_outlined,
                            tooltip: 'View Receipt',
                            color: AppColors.navyPrimary,
                            onTap: () => onTap!(receipt),
                          ),
                        if (onPdf != null)
                          _TableActionBtn(
                            icon: Icons.picture_as_pdf_outlined,
                            tooltip: 'PDF',
                            color: AppColors.navyPrimary,
                            onTap: () => onPdf!(receipt),
                          ),
                        if (onShare != null)
                          _TableActionBtn(
                            icon: Icons.share_outlined,
                            tooltip: 'Share',
                            color: AppColors.navyPrimary,
                            onTap: () => onShare!(receipt),
                          ),
                        if (onRevoke != null && receipt.isValid)
                          _TableActionBtn(
                            icon: Icons.cancel_outlined,
                            tooltip: 'Revoke',
                            color: AppColors.statusRevoked,
                            onTap: () => onRevoke!(receipt),
                          ),
                        if (onDelete != null)
                          _TableActionBtn(
                            icon: Icons.delete_outline,
                            tooltip: 'Delete',
                            color: AppColors.error,
                            onTap: () => onDelete!(receipt),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TableActionBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _TableActionBtn({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
