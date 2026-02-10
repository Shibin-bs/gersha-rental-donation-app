import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'firebase_service.dart';

/// Service to manage user data in Firestore 'users' collection
/// Handles CRUD operations for user documents
class UserService {
  static const String _collectionName = 'users';

  /// Get Firestore reference to users collection
  static CollectionReference<Map<String, dynamic>> get _collection =>
      FirebaseService.firestore.collection(_collectionName);

  /// Create a new user document in Firestore after authentication
  /// This is called after successful Firebase Authentication sign-up
  static Future<void> createUser({
    required String uid,
    String? name,
    String? email,
    String? phone,
    UserRole role = UserRole.user,
  }) async {
    try {
      debugPrint('[INFO] [UserService] Creating user document for UID: $uid');
      
      final userData = {
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.toString().split('.').last,
        'address': '', // Initially empty
        'verificationStatus': VerificationStatus.pending.toString().split('.').last,
        'verificationDocumentType': null,
        'verificationDocumentNumber': null,
        'agreementAccepted': false,
        // Default onboarding flags for new users (non-admins)
        // Admins are created manually in Firebase Console and are not blocked
        // by these flags because the routing layer bypasses them for role == 'admin'.
        'kycRequired': true,
        'createdAt': DateTime.now().toIso8601String(),
      };

      debugPrint('[INFO] [UserService] User data: $userData');

      // Create user document with uid as document ID
      await _collection.doc(uid).set(userData);
      debugPrint('[OK] [UserService] User document created successfully');
    } catch (e, stackTrace) {
      debugPrint('[ERROR] [UserService] Failed to create user: $e');
      debugPrint('Stack trace: $stackTrace');
      throw Exception('Failed to create user: $e');
    }
  }

  /// Get user document by UID
  static Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _collection.doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          try {
            return UserModel.fromJson(data, doc.id);
          } catch (e) {
            // Invalid document data
            return null;
          }
        }
      }
      return null;
    } catch (e) {
      // Return null on error instead of throwing
      return null;
    }
  }

  /// Update user document
  static Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      await _collection.doc(uid).update(updates);
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Update user verification status and document info
  /// Stores only masked/last few digits of verification document
  static Future<void> updateVerification({
    required String uid,
    required VerificationStatus status,
    required String documentType,
    required String maskedDocumentNumber, // Only last few digits
  }) async {
    try {
      await _collection.doc(uid).update({
        'verificationStatus': status.toString().split('.').last,
        'verificationDocumentType': documentType,
        'verificationDocumentNumber': maskedDocumentNumber,
      });
    } catch (e) {
      throw Exception('Failed to update verification: $e');
    }
  }

  /// Update agreement acceptance status
  static Future<void> updateAgreementAccepted(String uid, bool accepted) async {
    try {
      await _collection.doc(uid).update({
        'agreementAccepted': accepted,
      });
    } catch (e) {
      throw Exception('Failed to update agreement: $e');
    }
  }

  /// Update user address
  static Future<void> updateAddress(String uid, String address) async {
    try {
      await _collection.doc(uid).update({
        'address': address,
      });
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  /// Update user role (admin only)
  static Future<void> updateRole(String uid, UserRole role) async {
    try {
      await _collection.doc(uid).update({
        'role': role.toString().split('.').last,
      });
    } catch (e) {
      throw Exception('Failed to update role: $e');
    }
  }

  /// Get all users (for admin panel)
  static Stream<List<UserModel>> getAllUsers() {
    try {
      return _collection.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) {
              try {
                return UserModel.fromJson(doc.data(), doc.id);
              } catch (e) {
                // Skip invalid documents
                return null;
              }
            })
            .where((user) => user != null)
            .cast<UserModel>()
            .toList();
      }).handleError((error) {
        return <UserModel>[];
      });
    } catch (e) {
      return Stream.value(<UserModel>[]);
    }
  }

  /// Get user stream (real-time updates)
  static Stream<UserModel?> getUserStream(String uid) {
    return _collection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          try {
            return UserModel.fromJson(data, doc.id);
          } catch (e) {
            // Invalid document data
            return null;
          }
        }
      }
      return null;
    }).handleError((error) {
      // Return null on stream error
      return null;
    });
  }
}
