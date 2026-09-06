// lib/features/authentication/data/repositories/auth_repository_impl.dart
// Firebase Authentication repository implementation

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/constants/app_constants.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw AuthException.invalidCredentials();
      }

      // Update last login
      await updateLastLogin(user.uid);

      // Get user data from Firestore with graceful fallback
      UserModel userProfile;
      try {
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          userProfile = UserModel.fromFirestore(userDoc);
        } else {
          // Create a staff user document if doesn't exist
          final newUser = UserModel(
            uid: user.uid,
            email: user.email ?? email,
            displayName: user.displayName ?? email.split('@').first,
            role: AppConstants.roleStaff,
            createdAt: DateTime.now(),
          );
          try {
            await _firestore
                .collection(AppConstants.usersCollection)
                .doc(user.uid)
                .set(newUser.toFirestore());
          } catch (e) {
            debugPrint('Note: Could not save user profile to Firestore: $e');
          }
          userProfile = newUser;
        }
      } catch (e) {
        debugPrint('Note: Firestore user fetch error (check Security Rules): $e');
        userProfile = UserModel(
          uid: user.uid,
          email: user.email ?? email,
          displayName: user.displayName ?? email.split('@').first,
          role: AppConstants.roleStaff,
          createdAt: DateTime.now(),
        );
      }
      return userProfile;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthError(e.code, e.message ?? 'Authentication failed');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException.unknown(e.toString());
    }
  }

  @override
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String role = AppConstants.roleStaff,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) throw AuthException.unknown('Registration failed');

      // Update display name in Firebase Auth
      await user.updateDisplayName(displayName);

      // Create user document in Firestore
      final newUser = UserModel(
        uid: user.uid,
        email: user.email ?? email,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(newUser.toFirestore());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthError(e.code, e.message ?? 'Registration failed');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException.unknown(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw mapFirebaseAuthError(e.code, e.message ?? 'Password reset failed');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException.unknown(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException.unknown('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? user.email?.split('@').first ?? 'Staff',
        role: AppConstants.roleStaff,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? user.email?.split('@').first ?? 'Staff',
        role: AppConstants.roleStaff,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      try {
        final userDoc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .get();
        if (userDoc.exists) return UserModel.fromFirestore(userDoc);
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email?.split('@').first ?? 'Staff',
          role: AppConstants.roleStaff,
          createdAt: DateTime.now(),
        );
      } catch (_) {
        return UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? user.email?.split('@').first ?? 'Staff',
          role: AppConstants.roleStaff,
          createdAt: DateTime.now(),
        );
      }
    });
  }

  @override
  Future<void> updateLastLogin(String uid) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update(UserModel.lastLoginUpdate());
    } catch (_) {
      // Non-critical, ignore
    }
  }
}
