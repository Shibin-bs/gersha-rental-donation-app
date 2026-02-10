import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Auth Provider for managing authentication state using Provider
/// Provides current user data and authentication state to the app
class AuthProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;
  bool get isVerified => _currentUser?.isVerified ?? false;

  AuthProvider() {
    // Listen to auth state changes
    _initAuthListener();
    // Also load current user immediately
    _loadCurrentUser();
  }

  /// Initialize auth state listener
  void _initAuthListener() {
    AuthService.getCurrentUserStream().listen(
      (user) {
        _currentUser = user;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  /// Load current user immediately
  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService.getCurrentUser();
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      // Silently fail - user might not be logged in
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      debugPrint('[INFO] [AuthProvider] Sign in requested for: $email');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await AuthService.signInWithEmailAndPassword(email, password);
      
      if (user != null) {
        debugPrint('[OK] [AuthProvider] Sign in successful, user: ${user.email}');
        _currentUser = user;
        _isLoading = false;
        _errorMessage = null;
        // Notify listeners immediately so AuthWrapperScreen can react
        notifyListeners();
        // Small delay to ensure state is propagated
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      } else {
        debugPrint('[ERROR] [AuthProvider] Sign in failed: User document not found');
        _isLoading = false;
        _errorMessage = 'Sign in failed. User document not found.';
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] [AuthProvider] Sign in error: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      debugPrint('[INFO] [AuthProvider] Sign up requested for: $email');
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await AuthService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      
      if (user != null) {
        debugPrint('[OK] [AuthProvider] Sign up successful, user: ${user.email}');
        _currentUser = user;
        _isLoading = false;
        _errorMessage = null;
        // Notify listeners immediately so AuthWrapperScreen can react
        notifyListeners();
        // Small delay to ensure state is propagated
        await Future.delayed(const Duration(milliseconds: 100));
        return true;
      } else {
        debugPrint('[ERROR] [AuthProvider] Sign up failed: User document not created');
        _isLoading = false;
        _errorMessage = 'Sign up failed. User document not created.';
        notifyListeners();
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('[ERROR] [AuthProvider] Sign up error: $e');
      debugPrint('Stack trace: $stackTrace');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign in with phone number (step 1: send verification code)
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await AuthService.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _isLoading = false;
          notifyListeners();
          onCodeSent(verificationId);
        },
        onError: (error) {
          _isLoading = false;
          _errorMessage = error;
          notifyListeners();
          onError(error);
        },
      );
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      onError(e.toString());
    }
  }

  /// Sign in with phone number (step 2: verify code)
  Future<bool> signInWithPhoneNumber({
    required String verificationId,
    required String smsCode,
    String? phoneNumber,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await AuthService.signInWithPhoneNumber(
        verificationId: verificationId,
        smsCode: smsCode,
        phoneNumber: phoneNumber,
      );
      
      if (user != null) {
        _currentUser = user;
        _isLoading = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Phone sign in failed';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Sign out
  /// Only calls Firebase Auth signOut - navigation happens automatically via authStateChanges
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await AuthService.signOut();
      _currentUser = null;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      // Navigation will happen automatically via authStateChanges in AuthWrapperScreen
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Refresh current user data
  Future<void> refreshUser() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final user = await AuthService.getCurrentUser();
      _currentUser = user;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
