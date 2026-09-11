// lib/features/payment_details/domain/repositories/payment_details_repository.dart
// Abstract repository interface for Payment Done Details

import '../../data/models/payment_details_model.dart';

abstract class PaymentDetailsRepository {
  /// Create a new payment details record
  Future<PaymentDetailsModel> createPaymentDetails(PaymentDetailsModel payment);

  /// Get payment details by ID
  Future<PaymentDetailsModel?> getPaymentDetailsById(String id);

  /// Watch all payments as a real-time stream
  Stream<List<PaymentDetailsModel>> getPaymentsStream();

  /// Get payments as a one-time list with optional search query
  Future<List<PaymentDetailsModel>> getPaymentsList({String? query});

  /// Delete or cancel a payment details record
  Future<void> deletePaymentDetails(String id);
}
