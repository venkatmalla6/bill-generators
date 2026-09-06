// lib/features/authentication/domain/repositories/auth_repository.dart
// Abstract auth repository interface

import '../../data/models/user_model.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Register a new user
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String displayName,
    String role,
  });

  /// Send a password reset email
  Future<void> sendPasswordResetEmail(String email);

  /// Sign out the current user
  Future<void> signOut();

  /// Get the current user model (null if not authenticated)
  Future<UserModel?> getCurrentUser();

  /// Stream of authentication state changes
  Stream<UserModel?> get authStateChanges;

  /// Update user's last login timestamp
  Future<void> updateLastLogin(String uid);
}
