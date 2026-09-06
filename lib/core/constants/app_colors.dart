// lib/core/constants/app_colors.dart
// AKTS Brand Color Palette — Navy Blue Primary Identity

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ─── Primary Navy Palette ────────────────────────────────────────────────
  static const Color navyPrimary = Color(0xFF0D2366);
  static const Color navyDark = Color(0xFF071540);
  static const Color navyDeep = Color(0xFF050F30);
  static const Color navyLight = Color(0xFF1A3A8F);
  static const Color navyMedium = Color(0xFF163070);

  // ─── Surface / Background ───────────────────────────────────────────────
  static const Color background = Color(0xFFF0F4FF);
  static const Color surfaceLight = Color(0xFFF8FAFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color receiptBackground = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE0E6F0);

  // ─── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF4A4A6A);
  static const Color textMuted = Color(0xFF888AAA);
  static const Color textOnNavy = Color(0xFFFFFFFF);
  static const Color textOnNavyMuted = Color(0xFFB8C8F0);

  // ─── Status / Semantic ──────────────────────────────────────────────────
  static const Color statusValid = Color(0xFF16A34A);
  static const Color statusValidLight = Color(0xFFDCFCE7);
  static const Color statusRevoked = Color(0xFFDC2626);
  static const Color statusRevokedLight = Color(0xFFFEE2E2);
  static const Color statusCancelled = Color(0xFF6B7280);
  static const Color statusCancelledLight = Color(0xFFF3F4F6);

  // ─── Accent ──────────────────────────────────────────────────────────────
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFF8DC);
  static const Color success = Color(0xFF16A34A);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);
  static const Color info = Color(0xFF2563EB);

  // ─── Receipt-specific ───────────────────────────────────────────────────
  static const Color receiptBorder = Color(0xFF0D2366);
  static const Color receiptHeaderBg = Color(0xFF0D2366);
  static const Color receiptTitleBarBg = Color(0xFF071540);
  static const Color receiptFieldDivider = Color(0xFF0D2366);
  static const Color receiptDottedLine = Color(0xFF999999);
  static const Color receiptVerifyBg = Color(0xFFF0F4FF);

  // ─── Dashboard Stat Cards ────────────────────────────────────────────────
  static const Color statCard1 = Color(0xFF0D2366);
  static const Color statCard2 = Color(0xFF1A5276);
  static const Color statCard3 = Color(0xFF1A3A6B);
  static const Color statCard4 = Color(0xFF0E3460);

  // ─── Gradient Definitions ────────────────────────────────────────────────
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D2366), Color(0xFF071540)],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A3A8F), Color(0xFF0D2366)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A8F), Color(0xFF071540)],
  );

  // ─── Shadow ──────────────────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF0D2366).withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> receiptShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
}
