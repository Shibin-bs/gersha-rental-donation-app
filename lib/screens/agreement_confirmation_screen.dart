import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import 'main_app_screen.dart';

/// Agreement confirmation screen shown after identity verification
/// Updates Firestore with agreementAccepted = true
class AgreementConfirmationScreen extends StatefulWidget {
  const AgreementConfirmationScreen({super.key});

  @override
  State<AgreementConfirmationScreen> createState() => _AgreementConfirmationScreenState();
}

class _AgreementConfirmationScreenState extends State<AgreementConfirmationScreen> {
  bool _hasAgreed = false;
  bool _isLoading = false;

  /// Handle agreement confirmation and update Firestore
  /// Sets agreementAccepted = true in user document
  Future<void> _handleConfirm() async {
    if (!_hasAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the agreement to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user != null) {
        // Update agreementAccepted in Firestore
        await UserService.updateAgreementAccepted(user.uid, true);

        // Refresh user data
        await authProvider.refreshUser();

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          // Navigation happens automatically via authStateChanges in AuthWrapperScreen
          // The wrapper will detect agreementAccepted = true and show MainAppScreen
        }
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to confirm agreement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Agreement'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success icon
              Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'Identity Verified!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
              const SizedBox(height: 32),
              
              // Agreement card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GERSHA User Agreement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Agreement terms
                      _buildAgreementPoint(
                        'I agree to list items accurately and honestly.',
                      ),
                      _buildAgreementPoint(
                        'I will maintain items in good condition for rentals.',
                      ),
                      _buildAgreementPoint(
                        'I understand that donations are always free and rentals may have charges (in INR).',
                      ),
                      _buildAgreementPoint(
                        'I will respect other users and use the platform responsibly.',
                      ),
                      _buildAgreementPoint(
                        'I understand that GERSHA is a peer-to-peer platform for donations and rentals in India.',
                      ),
                      _buildAgreementPoint(
                        'I agree to comply with all applicable laws and regulations.',
                      ),
                      const SizedBox(height: 16),
                      
                      // Checkbox for agreement
                      CheckboxListTile(
                        title: const Text(
                          'I accept the terms and conditions',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        value: _hasAgreed,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _hasAgreed = value ?? false;
                                });
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Confirm button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleConfirm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm & Continue',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to build agreement points
  Widget _buildAgreementPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: Colors.green[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
