import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// Firebase service to initialize Firebase and provide access to Firestore and Storage
/// This service handles the initialization of Firebase Core, Auth, Firestore, and Storage
class FirebaseService {
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;
  static FirebaseStorage? _storage;

  /// Initialize Firebase services
  /// This must be called after Firebase.initializeApp() in main()
  /// Uses google-services.json for Android configuration
  static Future<void> initialize() async {
    try {
      debugPrint('[INFO] [FirebaseService] Initializing Firebase services...');
      
      // Verify Firebase app is initialized (should already be initialized in main())
      final app = Firebase.app();
      debugPrint('[OK] [FirebaseService] Firebase App Name: ${app.name}');
      debugPrint('[OK] [FirebaseService] Firebase App Options: ${app.options.projectId}');
      
      // Initialize Firestore
      _firestore = FirebaseFirestore.instance;
      debugPrint('[OK] [FirebaseService] Firestore initialized');
      
      // Initialize Auth
      _auth = FirebaseAuth.instance;
      debugPrint('[OK] [FirebaseService] Firebase Auth initialized');
      debugPrint('[OK] [FirebaseService] Auth App: ${_auth!.app.name}');
      
      // Initialize Storage
      _storage = FirebaseStorage.instance;
      debugPrint('[OK] [FirebaseService] Firebase Storage initialized');
      
      // Enable Firestore persistence (offline support)
      // Note: Persistence may not be available on all platforms (e.g., web)
      try {
        _firestore?.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        debugPrint('[OK] [FirebaseService] Firestore persistence enabled');
      } catch (e) {
        debugPrint('[WARN] [FirebaseService] Firestore persistence not available: $e');
        // Persistence not available on this platform, continue without it
        // This is normal for web platform
      }
      
      debugPrint('[OK] [FirebaseService] Firebase initialization complete');
      debugPrint('[OK] [FirebaseService] Ready for authentication and Firestore operations');
    } catch (e, stackTrace) {
      debugPrint('[ERROR] [FirebaseService] Failed to initialize Firebase: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('[ERROR] [FirebaseService] Make sure Firebase.initializeApp() is called in main()');
      debugPrint('[ERROR] [FirebaseService] Make sure google-services.json is in android/app/');
      debugPrint('[ERROR] [FirebaseService] Verify SHA-1 is added in Firebase Console');
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  /// Get Firestore instance
  static FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _firestore!;
  }

  /// Get Auth instance
  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _auth!;
  }

  /// Get Storage instance
  static FirebaseStorage get storage {
    if (_storage == null) {
      throw Exception('Firebase not initialized. Call FirebaseService.initialize() first.');
    }
    return _storage!;
  }
}
