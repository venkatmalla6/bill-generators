// lib/features/receipts/presentation/providers/receipt_provider.dart
// Riverpod receipt state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/receipt_model.dart';
import '../../data/repositories/receipt_repository_impl.dart';
import '../../domain/repositories/receipt_repository.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../../../core/utils/amount_to_words.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/utils/date_formatter.dart';

// ─── Repository Provider ─────────────────────────────────────────────────────

final receiptRepositoryProvider = Provider<ReceiptRepository>((ref) {
  return ReceiptRepositoryImpl();
});

// ─── Receipts Stream ──────────────────────────────────────────────────────────

final receiptsStreamProvider = StreamProvider<List<ReceiptModel>>((ref) {
  final repo = ref.watch(receiptRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();
  return repo.getReceiptsStream(
    userId: user.uid,
    isAdmin: user.isAdmin,
  );
});

// ─── Dashboard Statistics (Real-time computed from Receipts Stream) ───────────

final dashboardStatsProvider =
    Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final receiptsAsync = ref.watch(receiptsStreamProvider);
  return receiptsAsync.whenData((receipts) {
    final active = receipts.where((r) => !r.isDeleted).toList();
    final validReceipts = active.where((r) => r.isValid).toList();
    final todayReceipts = validReceipts.where((r) {
      return DateFormatter.isToday(r.date) ||
          DateFormatter.isToday(r.createdAt);
    }).toList();
    final monthReceipts = validReceipts.where((r) {
      return DateFormatter.isCurrentMonth(r.date) ||
          DateFormatter.isCurrentMonth(r.createdAt);
    }).toList();

    final totalAmount =
        validReceipts.fold<double>(0, (sum, r) => sum + r.amount);
    final todayAmount =
        todayReceipts.fold<double>(0, (sum, r) => sum + r.amount);
    final monthAmount =
        monthReceipts.fold<double>(0, (sum, r) => sum + r.amount);

    return {
      'totalReceipts': active.length,
      'validReceipts': validReceipts.length,
      'revokedReceipts': active.where((r) => r.isRevoked).length,
      'totalAmount': totalAmount,
      'todayReceipts': todayReceipts.length,
      'todayAmount': todayAmount,
      'monthReceipts': monthReceipts.length,
      'monthAmount': monthAmount,
    };
  });
});

// ─── Single Receipt ───────────────────────────────────────────────────────────

final receiptByIdProvider =
    FutureProvider.family<ReceiptModel?, String>((ref, id) {
  final repo = ref.watch(receiptRepositoryProvider);
  return repo.getReceiptById(id);
});

// ─── Verification ─────────────────────────────────────────────────────────────

final verifyReceiptProvider =
    FutureProvider.family<ReceiptModel?, String>((ref, verificationId) {
  final repo = ref.watch(receiptRepositoryProvider);
  return repo.getReceiptByVerificationId(verificationId);
});

// ─── Receipt Creation State ────────────────────────────────────────────────────

class CreateReceiptState {
  final bool isLoading;
  final String? error;
  final ReceiptModel? createdReceipt;
  final String? generatedReceiptNumber;
  final String amountInWords;

  const CreateReceiptState({
    this.isLoading = false,
    this.error,
    this.createdReceipt,
    this.generatedReceiptNumber,
    this.amountInWords = '',
  });

  CreateReceiptState copyWith({
    bool? isLoading,
    String? error,
    ReceiptModel? createdReceipt,
    String? generatedReceiptNumber,
    String? amountInWords,
    bool clearError = false,
  }) {
    return CreateReceiptState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      createdReceipt: createdReceipt ?? this.createdReceipt,
      generatedReceiptNumber:
          generatedReceiptNumber ?? this.generatedReceiptNumber,
      amountInWords: amountInWords ?? this.amountInWords,
    );
  }
}

class CreateReceiptController extends StateNotifier<CreateReceiptState> {
  final ReceiptRepository _repository;
  final Ref _ref;

  CreateReceiptController(this._repository, this._ref)
      : super(const CreateReceiptState());

  /// Update amount in words when amount changes
  void updateAmountInWords(double amount) {
    final words = AmountToWords.convert(amount);
    state = state.copyWith(amountInWords: words);
  }

  /// Pre-fetch the next receipt number
  Future<void> preloadReceiptNumber() async {
    // Just indicate ready state
  }

  /// Create a complete receipt from form data
  Future<ReceiptModel?> createReceipt({
    required DateTime date,
    required String memberName,
    required String aktsNumber,
    required String membershipYear,
    required double amount,
    required String paymentMode,
    String? transactionId,
    String? remarks,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) {
        throw AuthException.sessionExpired();
      }

      // 1. Generate receipt number (atomic)
      final receiptNumber = await _repository.generateReceiptNumber();

      // 2. Generate verification ID
      final verificationId = UuidGenerator.generate();

      // 3. Build verification URL
      final verificationUrl = AppConfig.buildVerificationUrl(verificationId);

      // 4. Generate amount in words
      final amountInWords = AmountToWords.convert(amount);

      // 5. Build receipt model
      final receipt = ReceiptModel(
        id: '', // Will be set by Firestore
        receiptNumber: receiptNumber,
        date: date,
        memberName: memberName.trim().toUpperCase(),
        aktsNumber: aktsNumber.trim().toUpperCase(),
        membershipYear: membershipYear,
        amount: amount,
        amountInWords: amountInWords,
        paymentMode: paymentMode,
        transactionId: transactionId?.trim().isEmpty ?? true
            ? null
            : transactionId?.trim(),
        remarks: remarks?.trim().isEmpty ?? true ? null : remarks?.trim(),
        verificationId: verificationId,
        verificationUrl: verificationUrl,
        status: AppConstants.statusValid,
        createdBy: user.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 6. Save to Firestore
      final created = await _repository.createReceipt(receipt);

      state = state.copyWith(
        isLoading: false,
        createdReceipt: created,
        amountInWords: amountInWords,
      );

      return created;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', '').replaceAll('AppException[number-generation-failed]: ', ''),
      );
      return null;
    }
  }

  /// Revoke a receipt
  Future<bool> revokeReceipt(String receiptId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw AuthException.sessionExpired();
      await _repository.revokeReceipt(receiptId, user.uid);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  void reset() {
    state = const CreateReceiptState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final createReceiptControllerProvider =
    StateNotifierProvider<CreateReceiptController, CreateReceiptState>((ref) {
  final repo = ref.watch(receiptRepositoryProvider);
  return CreateReceiptController(repo, ref);
});

// ─── Receipt History Filter State ─────────────────────────────────────────────

class ReceiptHistoryState {
  final bool isLoading;
  final List<ReceiptModel> receipts;
  final List<ReceiptModel> filtered;
  final String searchQuery;
  final String? statusFilter;
  final String? paymentModeFilter;
  final String? membershipYearFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? error;

  const ReceiptHistoryState({
    this.isLoading = false,
    this.receipts = const [],
    this.filtered = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.paymentModeFilter,
    this.membershipYearFilter,
    this.startDate,
    this.endDate,
    this.error,
  });

  ReceiptHistoryState copyWith({
    bool? isLoading,
    List<ReceiptModel>? receipts,
    List<ReceiptModel>? filtered,
    String? searchQuery,
    String? statusFilter,
    String? paymentModeFilter,
    String? membershipYearFilter,
    DateTime? startDate,
    DateTime? endDate,
    String? error,
    bool clearFilters = false,
  }) {
    return ReceiptHistoryState(
      isLoading: isLoading ?? this.isLoading,
      receipts: receipts ?? this.receipts,
      filtered: filtered ?? this.filtered,
      searchQuery: clearFilters ? '' : (searchQuery ?? this.searchQuery),
      statusFilter: clearFilters ? null : (statusFilter ?? this.statusFilter),
      paymentModeFilter: clearFilters ? null : (paymentModeFilter ?? this.paymentModeFilter),
      membershipYearFilter: clearFilters ? null : (membershipYearFilter ?? this.membershipYearFilter),
      startDate: clearFilters ? null : (startDate ?? this.startDate),
      endDate: clearFilters ? null : (endDate ?? this.endDate),
      error: error ?? this.error,
    );
  }
}

class ReceiptHistoryController extends StateNotifier<ReceiptHistoryState> {
  final ReceiptRepository _repository;
  final Ref _ref;

  ReceiptHistoryController(this._repository, this._ref)
      : super(const ReceiptHistoryState()) {
    _initStream();
  }

  void _initStream() {
    _ref.listen<AsyncValue<List<ReceiptModel>>>(
      receiptsStreamProvider,
      (previous, next) {
        next.whenData((receipts) {
          _updateReceipts(receipts);
        });
      },
      fireImmediately: true,
    );
  }

  void _updateReceipts(List<ReceiptModel> receipts) {
    state = state.copyWith(
      isLoading: false,
      receipts: receipts,
    );
    applyFilters(
      searchQuery: state.searchQuery,
      statusFilter: state.statusFilter,
      paymentModeFilter: state.paymentModeFilter,
      membershipYearFilter: state.membershipYearFilter,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  Future<void> loadReceipts() async {
    _ref.invalidate(receiptsStreamProvider);
    state = state.copyWith(isLoading: true);
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) return;

      final receipts = await _repository.getReceiptsList(
        userId: user.uid,
        isAdmin: user.isAdmin,
      );
      _updateReceipts(receipts);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void applyFilters({
    String? searchQuery,
    String? statusFilter,
    String? paymentModeFilter,
    String? membershipYearFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final newState = state.copyWith(
      searchQuery: searchQuery,
      statusFilter: statusFilter,
      paymentModeFilter: paymentModeFilter,
      membershipYearFilter: membershipYearFilter,
      startDate: startDate,
      endDate: endDate,
    );

    List<ReceiptModel> result = newState.receipts;

    // Search filter
    if (newState.searchQuery.isNotEmpty) {
      final q = newState.searchQuery.toLowerCase();
      result = result.where((r) {
        return r.receiptNumber.toLowerCase().contains(q) ||
            r.memberName.toLowerCase().contains(q) ||
            r.aktsNumber.toLowerCase().contains(q) ||
            (r.transactionId?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    // Status filter
    if (newState.statusFilter != null) {
      result = result.where((r) => r.status == newState.statusFilter).toList();
    }

    // Payment mode filter
    if (newState.paymentModeFilter != null) {
      result = result
          .where((r) => r.paymentMode == newState.paymentModeFilter)
          .toList();
    }

    // Membership year filter
    if (newState.membershipYearFilter != null) {
      result = result
          .where((r) => r.membershipYear == newState.membershipYearFilter)
          .toList();
    }

    // Date range filter
    if (newState.startDate != null && newState.endDate != null) {
      result = result.where((r) {
        return r.date.isAfter(newState.startDate!.subtract(const Duration(days: 1))) &&
            r.date.isBefore(newState.endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    state = newState.copyWith(filtered: result);
  }

  void clearFilters() {
    state = ReceiptHistoryState(
      receipts: state.receipts,
      filtered: state.receipts,
    );
  }

  /// Delete a receipt permanently (returns null on success, error message on failure)
  Future<String?> deleteReceipt(String receiptId) async {
    try {
      await _repository.deleteReceipt(receiptId);
      final updatedReceipts =
          state.receipts.where((r) => r.id != receiptId).toList();
      final updatedFiltered =
          state.filtered.where((r) => r.id != receiptId).toList();
      state = state.copyWith(
        receipts: updatedReceipts,
        filtered: updatedFiltered,
      );
      return null;
    } catch (e) {
      final msg = e.toString();
      state = state.copyWith(error: msg);
      return msg;
    }
  }
}

final receiptHistoryControllerProvider =
    StateNotifierProvider<ReceiptHistoryController, ReceiptHistoryState>((ref) {
  final repo = ref.watch(receiptRepositoryProvider);
  return ReceiptHistoryController(repo, ref);
});
