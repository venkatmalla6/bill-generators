// lib/shared/widgets/common/receipt_list_tile.dart
// Receipt list tile for history and bulk print screens

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../features/receipts/data/models/receipt_model.dart';

class ReceiptListTile extends StatelessWidget {
  final ReceiptModel receipt;
  final VoidCallback? onTap;
  final VoidCallback? onPdf;
  final VoidCallback? onRevoke;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final bool showCheckbox;
  final bool isSelected;
  final ValueChanged<bool?>? onCheckboxChanged;

  const ReceiptListTile({
    super.key,
    required this.receipt,
    this.onTap,
    this.onPdf,
    this.onRevoke,
    this.onShare,
    this.onDelete,
    this.showCheckbox = false,
    this.isSelected = false,
    this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppColors.navyPrimary : AppColors.dividerColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Checkbox (optional)
              if (showCheckbox)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: onCheckboxChanged,
                    activeColor: AppColors.navyPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              // Receipt number badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    receipt.receiptNumber.split('/').last,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navyPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            receipt.memberName,
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currencyFormat.format(receipt.amount),
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${receipt.receiptNumber} · ${receipt.aktsNumber}',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          DateFormatter.toDisplayDate(receipt.date),
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _PaymentModeBadge(mode: receipt.paymentMode),
                        const SizedBox(width: 6),
                        _StatusBadge(
                          label: statusLabel,
                          color: statusColor,
                          icon: statusIcon,
                        ),
                        const Spacer(),
                        // Action buttons
                        if (onPdf != null)
                          _ActionIconButton(
                            icon: Icons.picture_as_pdf_outlined,
                            onTap: onPdf!,
                            tooltip: 'Generate PDF',
                          ),
                        if (onShare != null)
                          _ActionIconButton(
                            icon: Icons.share_outlined,
                            onTap: onShare!,
                            tooltip: 'Share',
                          ),
                        if (onRevoke != null && receipt.isValid)
                          _ActionIconButton(
                            icon: Icons.cancel_outlined,
                            onTap: onRevoke!,
                            tooltip: 'Revoke',
                            color: AppColors.statusRevoked,
                          ),
                        if (onDelete != null)
                          _ActionIconButton(
                            icon: Icons.delete_outline,
                            onTap: onDelete!,
                            tooltip: 'Delete',
                            color: AppColors.error,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentModeBadge extends StatelessWidget {
  final String mode;

  const _PaymentModeBadge({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.navyPrimary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        mode,
        style: GoogleFonts.lato(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppColors.navyPrimary,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color color;

  const _ActionIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color = AppColors.navyPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
