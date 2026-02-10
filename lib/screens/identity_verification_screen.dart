import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import 'agreement_confirmation_screen.dart';

/// Identity verification screen where users provide verification documents
/// Stores only masked/last few digits for security
class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isIndianUser = true; // Default to Indian user
  String? _selectedDocumentType;
  final _documentNumberController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default document type based on nationality
    _selectedDocumentType = _isIndianUser ? 'aadhaar' : 'passport';
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  /// Mask document number - show only last 4 digits
  /// Example: "1234-5678-9012" -> "****-****-9012"
  String _maskDocumentNumber(String documentNumber) {
    if (documentNumber.length <= 4) {
      return documentNumber; // If too short, return as is
    }
    final last4 = documentNumber.substring(documentNumber.length - 4);
    return '****$last4';
  }

  /// Handle verification submission
  /// Stores only masked document number in Firestore
  Future<void> _handleVerification() async {
    if (_formKey.currentState!.validate() && _selectedDocumentType != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final user = authProvider.currentUser;
        
        if (user != null) {
          // Mask the document number (store only last few digits)
          final maskedNumber = _maskDocumentNumber(_documentNumberController.text.trim());
          
          // Update verification status in Firestore
          await UserService.updateVerification(
            uid: user.uid,
            status: VerificationStatus.verified,
            documentType: _selectedDocumentType!,
            maskedDocumentNumber: maskedNumber,
          );

          // Refresh user data
          await authProvider.refreshUser();

          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            // Navigation happens automatically via authStateChanges in AuthWrapperScreen
            // The wrapper will detect the updated verification status and show AgreementConfirmationScreen
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
              content: Text('Verification failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info card
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please verify your identity to list items on GERSHA. Only the last few digits of your document will be stored for security.',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Nationality selection
                Text(
                  'Are you an Indian user?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Indian'), icon: Icon(Icons.flag)),
                    ButtonSegment(value: false, label: Text('Overseas'), icon: Icon(Icons.public)),
                  ],
                  selected: {_isIndianUser},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isIndianUser = newSelection.first;
                      // Reset document type based on nationality
                      _selectedDocumentType = _isIndianUser ? 'aadhaar' : 'passport';
                    });
                  },
                ),
                const SizedBox(height: 32),
                
                // Document type selection
                Text(
                  _isIndianUser
                      ? 'Select Document Type *'
                      : 'Document Type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                if (_isIndianUser) ...[
                  // Indian document options: Aadhaar OR Driving License
                  RadioListTile<String>(
                    title: const Text('Aadhaar Number'),
                    subtitle: const Text('12-digit Aadhaar number'),
                    value: 'aadhaar',
                    groupValue: _selectedDocumentType,
                    onChanged: (value) {
                      setState(() {
                        _selectedDocumentType = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('Driving License'),
                    subtitle: const Text('Driving License number'),
                    value: 'driving_license',
                    groupValue: _selectedDocumentType,
                    onChanged: (value) {
                      setState(() {
                        _selectedDocumentType = value;
                      });
                    },
                  ),
                ] else ...[
                  // Overseas document option: Passport
                  RadioListTile<String>(
                    title: const Text('Passport Number'),
                    subtitle: const Text('Passport number'),
                    value: 'passport',
                    groupValue: _selectedDocumentType,
                    onChanged: (value) {
                      setState(() {
                        _selectedDocumentType = value;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 24),
                
                // Document number field
                TextFormField(
                  controller: _documentNumberController,
                  decoration: InputDecoration(
                    labelText: _isIndianUser
                        ? (_selectedDocumentType == 'aadhaar'
                            ? 'Aadhaar Number'
                            : 'Driving License Number')
                        : 'Passport Number',
                    hintText: _isIndianUser
                        ? (_selectedDocumentType == 'aadhaar'
                            ? '1234-5678-9012'
                            : 'DL-XX-YYYY-1234567')
                        : 'A1234567',
                    prefixIcon: const Icon(Icons.badge),
                    border: const OutlineInputBorder(),
                    helperText: 'Only last 4 digits will be stored for security',
                  ),
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter document number';
                    }
                    // Basic validation
                    if (_selectedDocumentType == 'aadhaar' && value.replaceAll('-', '').length != 12) {
                      return 'Aadhaar number must be 12 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Submit button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleVerification,
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
                          'Verify Identity',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 16),
                
                // Privacy note
                Text(
                  'Your document information is stored securely. Only the last 4 digits are saved for verification purposes and will not be shared with other users.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
