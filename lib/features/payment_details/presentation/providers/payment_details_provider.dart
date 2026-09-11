// lib/features/payment_details/presentation/providers/payment_details_provider.dart
// Riverpod providers and StateNotifiers for Payment Done Details

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/amount_to_words.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../data/models/payment_details_model.dart';
import '../../data/repositories/payment_details_repository_impl.dart';
import '../../domain/repositories/payment_details_repository.dart';

// Repository provider
final paymentDetailsRepositoryProvider = Provider<PaymentDetailsRepository>((ref) {
  return PaymentDetailsRepositoryImpl();
});

// Stream provider for live payment history
final paymentsStreamProvider =
    StreamProvider.autoDispose<List<PaymentDetailsModel>>((ref) {
  final repo = ref.watch(paymentDetailsRepositoryProvider);
  return repo.getPaymentsStream();
});

// Single payment provider by ID
final paymentDetailsByIdProvider =
    FutureProvider.family<PaymentDetailsModel?, String>((ref, id) async {
  final repo = ref.read(paymentDetailsRepositoryProvider);
  return repo.getPaymentDetailsById(id);
});

// Statistics provider
final paymentStatsProvider = Provider.autoDispose<Map<String, dynamic>>((ref) {
  final paymentsAsync = ref.watch(paymentsStreamProvider);
  final payments = paymentsAsync.value ?? [];

  double totalAmount = 0.0;
  int onlineCount = 0;
  double onlineAmount = 0.0;
  int offlineCount = 0;
  double offlineAmount = 0.0;

  for (final p in payments) {
    if (p.isValid) {
      totalAmount += p.amount;
      if (p.isOnline) {
        onlineCount++;
        onlineAmount += p.amount;
      } else {
        offlineCount++;
        offlineAmount += p.amount;
      }
    }
  }

  return {
    'totalBills': payments.length,
    'totalAmount': totalAmount,
    'onlineCount': onlineCount,
    'onlineAmount': onlineAmount,
    'offlineCount': offlineCount,
    'offlineAmount': offlineAmount,
  };
});

// State for creating payment voucher
class CreatePaymentState {
  final bool isLoading;
  final String? error;
  final String amountInWords;

  const CreatePaymentState({
    this.isLoading = false,
    this.error,
    this.amountInWords = '',
  });

  CreatePaymentState copyWith({
    bool? isLoading,
    String? error,
    String? amountInWords,
  }) {
    return CreatePaymentState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      amountInWords: amountInWords ?? this.amountInWords,
    );
  }
}

class CreatePaymentController extends StateNotifier<CreatePaymentState> {
  final PaymentDetailsRepository _repository;
  final Ref _ref;

  CreatePaymentController(this._repository, this._ref)
      : super(const CreatePaymentState());

  void updateAmount(double amount) {
    if (amount <= 0) {
      state = state.copyWith(amountInWords: '');
      return;
    }
    final words = AmountToWords.convert(amount, uppercase: true);
    state = state.copyWith(amountInWords: words);
  }

  Future<PaymentDetailsModel?> submitPayment({
    required String shopName,
    required String billNumber,
    required DateTime date,
    required double amount,
    required String paymentType,
    required String paymentMode,
    String? transactionDetails,
    String? remarks,
    List<String> imagesBase64 = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _ref.read(currentUserProvider);
      final now = DateTime.now();

      // Generate voucher number: PAY-YYYY-XXXX
      final randSuffix = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
      final voucherNumber = 'PAY-${now.year}-$randSuffix';

      final amountInWords = state.amountInWords.isNotEmpty
          ? state.amountInWords
          : AmountToWords.convert(amount, uppercase: true);

      final payment = PaymentDetailsModel(
        id: '',
        voucherNumber: voucherNumber,
        shopName: shopName.trim(),
        billNumber: billNumber.trim(),
        date: date,
        amount: amount,
        amountInWords: amountInWords,
        paymentType: paymentType,
        paymentMode: paymentMode,
        transactionDetails: transactionDetails?.trim(),
        remarks: remarks?.trim(),
        imagesBase64: imagesBase64,
        status: 'valid',
        createdBy: user?.displayName.isNotEmpty == true
            ? user!.displayName
            : (user?.email ?? 'Staff'),
        createdAt: now,
        updatedAt: now,
      );

      final created = await _repository.createPaymentDetails(payment);
      state = state.copyWith(isLoading: false);
      return created;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }
}

final createPaymentControllerProvider =
    StateNotifierProvider.autoDispose<CreatePaymentController, CreatePaymentState>(
        (ref) {
  final repo = ref.watch(paymentDetailsRepositoryProvider);
  return CreatePaymentController(repo, ref);
});
