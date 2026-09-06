// lib/features/bulk_print/presentation/providers/bulk_print_provider.dart
// Bulk print selection state management

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../receipts/data/models/receipt_model.dart';

class BulkPrintState {
  final Set<String> selectedIds;
  final List<ReceiptModel> allReceipts;
  final bool isGenerating;
  final String? error;

  const BulkPrintState({
    this.selectedIds = const {},
    this.allReceipts = const [],
    this.isGenerating = false,
    this.error,
  });

  List<ReceiptModel> get selectedReceipts =>
      allReceipts.where((r) => selectedIds.contains(r.id)).toList();

  bool isSelected(String id) => selectedIds.contains(id);
  bool get hasSelection => selectedIds.isNotEmpty;
  int get selectionCount => selectedIds.length;

  BulkPrintState copyWith({
    Set<String>? selectedIds,
    List<ReceiptModel>? allReceipts,
    bool? isGenerating,
    String? error,
    bool clearError = false,
  }) {
    return BulkPrintState(
      selectedIds: selectedIds ?? this.selectedIds,
      allReceipts: allReceipts ?? this.allReceipts,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class BulkPrintController extends StateNotifier<BulkPrintState> {
  BulkPrintController() : super(const BulkPrintState());

  void setReceipts(List<ReceiptModel> receipts) {
    state = state.copyWith(allReceipts: receipts);
  }

  void toggleSelection(String id) {
    final current = Set<String>.from(state.selectedIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    state = state.copyWith(selectedIds: current);
  }

  void selectAll() {
    final ids = state.allReceipts.map((r) => r.id).toSet();
    state = state.copyWith(selectedIds: ids);
  }

  void clearSelection() {
    state = state.copyWith(selectedIds: {});
  }

  void selectByDateRange(DateTime start, DateTime end) {
    final ids = state.allReceipts
        .where((r) {
          return r.date.isAfter(start.subtract(const Duration(days: 1))) &&
              r.date.isBefore(end.add(const Duration(days: 1)));
        })
        .map((r) => r.id)
        .toSet();
    state = state.copyWith(selectedIds: ids);
  }

  void selectByYear(String year) {
    final ids = state.allReceipts
        .where((r) => r.membershipYear == year)
        .map((r) => r.id)
        .toSet();
    state = state.copyWith(selectedIds: ids);
  }

  void setGenerating(bool generating) {
    state = state.copyWith(isGenerating: generating);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

final bulkPrintControllerProvider =
    StateNotifierProvider<BulkPrintController, BulkPrintState>((ref) {
  return BulkPrintController();
});
