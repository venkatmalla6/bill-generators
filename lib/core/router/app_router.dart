// lib/core/router/app_router.dart
// GoRouter configuration with auth guards for AKTS

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/receipts/presentation/screens/create_receipt_screen.dart';
import '../../features/receipts/presentation/screens/receipt_preview_screen.dart';
import '../../features/receipts/presentation/screens/receipt_history_screen.dart';
import '../../features/verification/presentation/screens/verification_screen.dart';
import '../../features/qr/presentation/screens/qr_scanner_screen.dart';
import '../../features/bulk_print/presentation/screens/bulk_print_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/payment_details/presentation/screens/create_payment_details_screen.dart';
import '../../features/payment_details/presentation/screens/payment_details_history_screen.dart';
import '../../features/payment_details/presentation/screens/payment_details_preview_screen.dart';

// Route names
class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const dashboard = '/';
  static const createReceipt = '/receipts/create';
  static const receiptPreview = '/receipts/:id';
  static const receiptHistory = '/receipts/history';
  static const verify = '/verify/:verificationId';
  static const scanQr = '/scan-qr';
  static const bulkPrint = '/bulk-print';
  static const settings = '/settings';
  static const paymentDetails = '/payment-details';
  static const createPaymentDetails = '/payment-details/create';
  static const paymentDetailsPreview = '/payment-details/:id';

  // Named helpers
  static String receiptPreviewPath(String id) => '/receipts/$id';
  static String verifyPath(String verificationId) => '/verify/$verificationId';
  static String paymentDetailsPreviewPath(String id) => '/payment-details/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateProvider.stream),
    ),
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isLoading = authState.isLoading;

      // Allow public routes without auth
      final publicRoutes = [
        '/verify/',
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ];

      final isPublicRoute = publicRoutes.any(
        (route) => state.matchedLocation.startsWith(route),
      );

      if (isLoading) return null;

      if (!isAuthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }

      if (isAuthenticated &&
          (state.matchedLocation == AppRoutes.login ||
              state.matchedLocation == AppRoutes.register)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      // ── Auth Routes ──────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ── Dashboard ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),

      // ── Receipts ─────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.createReceipt,
        name: 'create-receipt',
        builder: (context, state) => const CreateReceiptScreen(),
      ),
      GoRoute(
        path: AppRoutes.receiptHistory,
        name: 'receipt-history',
        builder: (context, state) => const ReceiptHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.receiptPreview,
        name: 'receipt-preview',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ReceiptPreviewScreen(receiptId: id);
        },
      ),

      // ── Public Verification ───────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.verify,
        name: 'verify',
        builder: (context, state) {
          final verificationId = state.pathParameters['verificationId']!;
          return VerificationScreen(verificationId: verificationId);
        },
      ),

      // ── QR Scanner ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.scanQr,
        name: 'scan-qr',
        builder: (context, state) => const QrScannerScreen(),
      ),

      // ── Bulk Print ────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.bulkPrint,
        name: 'bulk-print',
        builder: (context, state) => const BulkPrintScreen(),
      ),

      // ── Settings ──────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // ── Payment Done Details ──────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.paymentDetails,
        name: 'payment-details',
        builder: (context, state) => const PaymentDetailsHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.createPaymentDetails,
        name: 'create-payment-details',
        builder: (context, state) => const CreatePaymentDetailsScreen(),
      ),
      GoRoute(
        path: AppRoutes.paymentDetailsPreview,
        name: 'payment-details-preview',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PaymentDetailsPreviewScreen(paymentId: id);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.error?.message ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Allows GoRouter to listen to a Stream for refreshing redirect logic
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    (_subscription as dynamic).cancel();
    super.dispose();
  }
}
