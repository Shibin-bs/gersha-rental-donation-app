import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'main_app_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'splash_screen.dart';
import 'identity_verification_screen.dart';
import 'agreement_confirmation_screen.dart';


/// Auth wrapper screen that listens to Firebase auth state changes
/// and routes based on the Firestore user document (role).
///
/// Key goals with the new Firestore rules:
/// - Fetch users/{uid} once per auth change (no nested/infinite builders)
/// - Safely create the document if it doesn't exist
/// - Handle permission and network errors explicitly
/// - Avoid endless loading spinners by surfacing errors + retry
class AuthWrapperScreen extends StatefulWidget {
  const AuthWrapperScreen({super.key});

  @override
  State<AuthWrapperScreen> createState() => _AuthWrapperScreenState();
}

class _AuthWrapperScreenState extends State<AuthWrapperScreen> {
  /// Cache for the last loaded user document to avoid refetching unnecessarily.
  UserModel? _cachedUser;
  String? _cachedUserUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Single source of truth: Firebase Auth state
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        debugPrint(
            '[INFO] [AuthWrapper] authStateChanges snapshot - state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');

        // Auth stream error – log and fall back to login screen
        if (snapshot.hasError) {
          debugPrint('[ERROR] [AuthWrapper] Auth state error: ${snapshot.error}');
          return _buildErrorScaffold(
            title: 'Authentication Error',
            message: 'Something went wrong while checking your login state.',
            onRetry: () {
              setState(() {});
            },
            fallback: const LoginScreen(),
          );
        }

        // Still determining if a Firebase user exists – show splash
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final firebaseUser = snapshot.data;

        // Not logged in – go to login screen
        if (firebaseUser == null) {
          debugPrint('[INFO] [AuthWrapper] No authenticated Firebase user. Showing LoginScreen.');
          _cachedUser = null;
          _cachedUserUid = null;
          return const LoginScreen();
        }

        // If we already have a cached user for this UID, route immediately
        if (_cachedUser != null && _cachedUserUid == firebaseUser.uid) {
          debugPrint(
              '[INFO] [AuthWrapper] Using cached user profile for UID: ${firebaseUser.uid}. Routing without refetch.');
          return _buildScreenForUser(_cachedUser!);
        }

        // Fetch or create the Firestore user document ONCE for this UID
        return FutureBuilder<UserModel?>(
          future: _fetchOrCreateUser(firebaseUser),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const SplashScreen();
            }

            if (userSnapshot.hasError) {
              final error = userSnapshot.error;
              debugPrint('[ERROR] [AuthWrapper] User fetch error: $error');

              String message = 'Unable to load your profile. Please try again.';
              if (error is FirebaseException && error.code == 'permission-denied') {
                message =
                    'You do not have permission to access your profile document. Please contact support.';
              }

              return _buildErrorScaffold(
                title: 'Profile Error',
                message: message,
                onRetry: () {
                  setState(() {
                    _cachedUser = null;
                    _cachedUserUid = null;
                  });
                },
                fallback: const LoginScreen(),
              );
            }

            final user = userSnapshot.data;
            if (user == null) {
              debugPrint(
                  '[ERROR] [AuthWrapper] User document is null after creation attempt for UID: ${firebaseUser.uid}');
              return _buildErrorScaffold(
                title: 'Profile Missing',
                message:
                    'Your user profile could not be created. Please sign out and try again.',
                onRetry: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    setState(() {
                      _cachedUser = null;
                      _cachedUserUid = null;
                    });
                  }
                },
                fallback: const LoginScreen(),
              );
            }

            // Cache and route
            _cachedUser = user;
            _cachedUserUid = firebaseUser.uid;
            return _buildScreenForUser(user);
          },
        );
      },
    );
  }

  /// Fetch existing user document or create it if missing.
  /// This is called exactly once per authenticated UID (unless retrying after error).
  Future<UserModel?> _fetchOrCreateUser(User firebaseUser) async {
    debugPrint('[INFO] [AuthWrapper] Fetching user profile for UID: ${firebaseUser.uid}');
    try {
      var user = await UserService.getUser(firebaseUser.uid);

      if (user == null) {
        debugPrint('[WARN] [AuthWrapper] User document missing. Creating new document.');
        await UserService.createUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          name: firebaseUser.displayName,
          phone: firebaseUser.phoneNumber,
        );

        // Re-fetch once after creation
        user = await UserService.getUser(firebaseUser.uid);
        if (user == null) {
          debugPrint(
              '[ERROR] [AuthWrapper] User document still null after creation for UID: ${firebaseUser.uid}');
        }
      }

      // Defensive null/field handling is mostly inside UserModel.fromJson,
      // but we still ensure we never return a partially invalid object.
      if (user != null) {
        debugPrint(
            '[OK] [AuthWrapper] User profile loaded. Role: ${user.role}, agreementAccepted: ${user.agreementAccepted}, verificationStatus: ${user.verificationStatus}, kycRequired: ${user.kycRequired}');
      }

      return user;
    } on FirebaseException catch (e, stack) {
      debugPrint(
          '[ERROR] [AuthWrapper] Firestore error while fetching/creating user: ${e.code} - ${e.message}');
      debugPrint(stack.toString());
      rethrow;
    } catch (e, stack) {
      debugPrint('[ERROR] [AuthWrapper] Unexpected error while fetching/creating user: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Decide which top-level screen to show based on user.role.
  ///
  /// STRICT ORDER (do not change):
  /// 1. IF role == "admin"      → AdminDashboardScreen (bypass all other checks)
  /// 2. ELSE (normal user flow):
  ///    - IF kycRequired == true AND verificationStatus != "verified"
  ///         → IdentityVerificationScreen (KYC)
  ///    - ELSE IF agreementAccepted != true
  ///         → AgreementConfirmationScreen
  ///    - ELSE
  ///         → MainAppScreen (user dashboard)
  Widget _buildScreenForUser(UserModel user) {
    // ADMIN BYPASS (MUST BE FIRST)
    if (user.role == UserRole.admin) {
      debugPrint(
          '[INFO] [AuthWrapper] Admin detected (role == admin). Routing directly to AdminDashboardScreen and bypassing KYC/agreement.');
      return const AdminDashboardScreen();
    }

    // Defensive defaults for routing-critical fields:
    final bool kycRequired = user.kycRequired;
    final VerificationStatus verificationStatus = user.verificationStatus;
    final bool agreementAccepted = user.agreementAccepted;

    // NORMAL USER FLOW
    // 1) KYC gate
    if (kycRequired && verificationStatus != VerificationStatus.verified) {
      debugPrint(
          '[INFO] [AuthWrapper] Routing to IdentityVerificationScreen (kycRequired=$kycRequired, verificationStatus=$verificationStatus).');
      return const IdentityVerificationScreen();
    }

    // 2) Agreement gate
    if (!agreementAccepted) {
      debugPrint(
          '[INFO] [AuthWrapper] Routing to AgreementConfirmationScreen (agreementAccepted=$agreementAccepted).');
      return const AgreementConfirmationScreen();
    }

    // 3) Fully onboarded user → main user dashboard
    debugPrint(
        '[INFO] [AuthWrapper] Routing to MainAppScreen (role=user, kycRequired=$kycRequired, verificationStatus=$verificationStatus, agreementAccepted=$agreementAccepted).');
    return const MainAppScreen();
  }

  /// Generic error scaffold used when we can't proceed automatically.
  /// This ensures we never show an endless spinner; the user always sees
  /// what went wrong and can retry or fall back safely.
  Widget _buildErrorScaffold({
    required String title,
    required String message,
    required VoidCallback onRetry,
    required Widget fallback,
  }) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 72, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => fallback),
                      (route) => false,
                    );
                  },
                  child: const Text('Back to start'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
