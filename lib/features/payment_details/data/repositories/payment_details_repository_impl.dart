// lib/features/payment_details/data/repositories/payment_details_repository_impl.dart
// Implementation of PaymentDetailsRepository with Firestore & local fallback

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/payment_details_repository.dart';
import '../models/payment_details_model.dart';

class PaymentDetailsRepositoryImpl implements PaymentDetailsRepository {
  final FirebaseFirestore _firestore;

  // In-memory fallback cache to allow seamless offline or unauthenticated operations
  final List<PaymentDetailsModel> _fallbackCache = [];
  final StreamController<List<PaymentDetailsModel>> _fallbackController =
      StreamController<List<PaymentDetailsModel>>.broadcast();

  PaymentDetailsRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.paymentsDoneCollection);

  @override
  Future<PaymentDetailsModel> createPaymentDetails(
      PaymentDetailsModel payment) async {
    try {
      final docRef = _collection.doc();
      final recordWithId = payment.copyWith(id: docRef.id);
      await docRef.set(recordWithId.toFirestore());
      
      // Update cache
      _fallbackCache.insert(0, recordWithId);
      _fallbackController.add(List.unmodifiable(_fallbackCache));
      return recordWithId;
    } catch (e) {
      debugPrint('Firestore write failed, using local cache: $e');
      final fallbackId = payment.id.isNotEmpty
          ? payment.id
          : 'local_${DateTime.now().millisecondsSinceEpoch}';
      final localPayment = payment.copyWith(id: fallbackId);
      _fallbackCache.insert(0, localPayment);
      _fallbackController.add(List.unmodifiable(_fallbackCache));
      return localPayment;
    }
  }

  @override
  Future<PaymentDetailsModel?> getPaymentDetailsById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (doc.exists) {
        return PaymentDetailsModel.fromFirestore(doc);
      }
    } catch (e) {
      debugPrint('Firestore read failed: $e');
    }

    // Check local fallback cache
    try {
      return _fallbackCache.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<PaymentDetailsModel>> getPaymentsStream() {
    try {
      return _collection
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs
            .map((doc) => PaymentDetailsModel.fromFirestore(doc))
            .toList();
        // Sync cache
        _fallbackCache.clear();
        _fallbackCache.addAll(list);
        return list;
      }).handleError((err) {
        debugPrint('Firestore stream error, falling back to local stream: $err');
        return _fallbackCache;
      });
    } catch (e) {
      debugPrint('Error attaching Firestore stream: $e');
      return _fallbackController.stream;
    }
  }

  @override
  Future<List<PaymentDetailsModel>> getPaymentsList({String? query}) async {
    List<PaymentDetailsModel> results = [];
    try {
      final snapshot =
          await _collection.orderBy('createdAt', descending: true).get();
      results = snapshot.docs
          .map((doc) => PaymentDetailsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Firestore getPaymentsList error: $e');
      results = List.from(_fallbackCache);
    }

    if (query != null && query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      results = results.where((p) {
        return p.shopName.toLowerCase().contains(q) ||
            p.billNumber.toLowerCase().contains(q) ||
            p.voucherNumber.toLowerCase().contains(q) ||
            (p.transactionDetails?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return results;
  }

  @override
  Future<void> deletePaymentDetails(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      debugPrint('Firestore delete failed: $e');
    }
    _fallbackCache.removeWhere((p) => p.id == id);
    _fallbackController.add(List.unmodifiable(_fallbackCache));
  }
}
