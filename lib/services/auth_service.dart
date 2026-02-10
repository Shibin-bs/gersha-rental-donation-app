import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';
import 'user_service.dart';

/// Authentication service using Firebase Authentication
/// Supports Email/Password and Phone Number authentication
class AuthService {
  /// Sign in with email and password
  /// After successful authentication, fetches or creates user document in Firestore
  static Future<UserModel?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      debugPrint('[INFO] [AuthService] Starting sign in for: ${email.trim()}');
      
      // Authenticate with Firebase Auth
      final credential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        debugPrint('[OK] [AuthService] Firebase Auth sign in successful: $uid');
        
        // Get user document from Firestore
        var user = await UserService.getUser(uid);
        
        // If user document doesn't exist, create it
        if (user == null) {
          debugPrint('[WARN] [AuthService] User document not found, creating...');
          try {
            await UserService.createUser(
              uid: uid,
              email: email.trim(),
              name: credential.user!.displayName,
            );
            debugPrint('[OK] [AuthService] User document created');
          } catch (e) {
            debugPrint('[ERROR] [AuthService] Failed to create user document: $e');
            throw Exception('Failed to create user document: $e');
          }
          
          // Wait a moment for Firestore to be ready
          await Future.delayed(const Duration(milliseconds: 500));
          user = await UserService.getUser(uid);
          
          // Retry once if still null
          if (user == null) {
            debugPrint('[WARN] [AuthService] User document still not found, retrying...');
            await Future.delayed(const Duration(milliseconds: 500));
            user = await UserService.getUser(uid);
          }
        } else {
          debugPrint('[OK] [AuthService] User document found');
        }
        
        if (user != null) {
          debugPrint('[OK] [AuthService] Sign in successful, user: ${user.email}');
        } else {
          debugPrint('[ERROR] [AuthService] User document still null after retries');
        }
        
        return user;
      }
      debugPrint('[ERROR] [AuthService] Credential user is null');
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('[ERROR] [AuthService] Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      debugPrint('[ERROR] [AuthService] Sign in failed: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign up with email and password
  /// Creates Firebase Auth user and user document in Firestore
  static Future<UserModel?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      debugPrint('[INFO] [AuthService] Starting sign up for: ${email.trim()}');
      
      // Create Firebase Auth user
      final credential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        debugPrint('[OK] [AuthService] Firebase Auth user created: $uid');
        
        // Update display name if provided
        if (name != null && name.isNotEmpty) {
          try {
            await credential.user!.updateDisplayName(name);
            await credential.user!.reload();
            debugPrint('[OK] [AuthService] Display name updated: $name');
          } catch (e) {
            debugPrint('[WARN] [AuthService] Display name update failed: $e');
            // Continue with user creation
          }
        }
        
        // Create user document in Firestore
        try {
          await UserService.createUser(
            uid: uid,
            email: email.trim(),
            name: name,
          );
          debugPrint('[OK] [AuthService] User document created in Firestore');
        } catch (e) {
          debugPrint('[ERROR] [AuthService] Failed to create user document: $e');
          throw Exception('Failed to create user document: $e');
        }
        
        // Wait a moment for Firestore to be ready
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Get and return user document (retry if needed)
        var user = await UserService.getUser(uid);
        if (user == null) {
          debugPrint('[WARN] [AuthService] User document not found, retrying...');
          // Retry once after a short delay
          await Future.delayed(const Duration(milliseconds: 500));
          user = await UserService.getUser(uid);
        }
        
        if (user != null) {
          debugPrint('[OK] [AuthService] User document retrieved successfully');
        } else {
          debugPrint('[ERROR] [AuthService] User document still not found after retry');
        }
        
        return user;
      }
      debugPrint('[ERROR] [AuthService] Credential user is null');
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('[ERROR] [AuthService] Firebase Auth Exception: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      debugPrint('[ERROR] [AuthService] Sign up failed: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with phone number
  /// Step 1: Send verification code
  static Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      await FirebaseService.auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (credential) async {
          // Auto-verification completed (Android only)
          final user = await _handlePhoneAuthSuccess(credential);
          if (user != null) {
            // Handle successful auto-verification
          }
        },
        verificationFailed: (error) {
          onError(_handleAuthException(error));
        },
        codeSent: (verificationId, resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          // Auto-retrieval timeout
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      onError('Phone verification failed: $e');
    }
  }

  /// Sign in with phone number
  /// Step 2: Verify SMS code and sign in
  static Future<UserModel?> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  }) async {
    try {
      // Create phone auth credential
      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in with credential
      final authResult = await FirebaseService.auth.signInWithCredential(credential);
      
      if (authResult.user != null) {
        return await _handlePhoneAuthSuccess(credential);
      }
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Phone sign in failed: $e');
    }
  }

  /// Handle successful phone authentication
  static Future<UserModel?> _handlePhoneAuthSuccess(
      firebase_auth.PhoneAuthCredential credential) async {
    try {
      final authResult = await FirebaseService.auth.signInWithCredential(credential);
      
      if (authResult.user != null) {
        final uid = authResult.user!.uid;
        final phone = authResult.user!.phoneNumber;
        
        // Get user document from Firestore
        var user = await UserService.getUser(uid);
        
        // If user document doesn't exist, create it
        if (user == null) {
          await UserService.createUser(
            uid: uid,
            phone: phone,
          );
          user = await UserService.getUser(uid);
        }
        
        return user;
      }
      return null;
    } catch (e) {
      throw Exception('Phone auth handling failed: $e');
    }
  }

  /// Sign out current user
  static Future<void> signOut() async {
    try {
      await FirebaseService.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  /// Get current authenticated user from Firebase Auth
  static firebase_auth.User? getCurrentFirebaseUser() {
    return FirebaseService.auth.currentUser;
  }

  /// Get current user document from Firestore
  static Future<UserModel?> getCurrentUser() async {
    final firebaseUser = getCurrentFirebaseUser();
    if (firebaseUser != null) {
      return await UserService.getUser(firebaseUser.uid);
    }
    return null;
  }

  /// Get current user stream (real-time updates)
  static Stream<UserModel?> getCurrentUserStream() {
    return FirebaseService.auth.authStateChanges().asyncMap((firebaseUser) async {
      try {
        if (firebaseUser != null) {
          return await UserService.getUser(firebaseUser.uid);
        }
        return null;
      } catch (e) {
        // Return null on error
        return null;
      }
    }).handleError((error) {
      // Handle stream errors gracefully
      return null;
    });
  }

  /// Check if user is logged in
  static bool isLoggedIn() {
    return getCurrentFirebaseUser() != null;
  }

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    final user = await getCurrentUser();
    return user?.role == UserRole.admin;
  }

  /// Handle Firebase Auth exceptions and return user-friendly messages
  static String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification ID.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      default:
        return 'Authentication failed: ${e.message ?? e.code}';
    }
  }
}
