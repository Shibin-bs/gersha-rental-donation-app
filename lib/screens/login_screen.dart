import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'main_app_screen.dart';
import 'admin/admin_dashboard_screen.dart';
import 'identity_verification_screen.dart';
import '../models/user_model.dart';

/// Login screen with Email/Password and Phone Number authentication
/// Supports both sign in and sign up flows
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false;
  bool _isPhoneAuth = false;
  String? _verificationId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _smsCodeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Handle email/password sign in
  /// Only calls Firebase Auth - navigation happens automatically via authStateChanges
  Future<void> _handleEmailSignIn() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Sign in failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          // If success, AuthWrapperScreen will automatically navigate via authStateChanges
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign in failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Handle email/password sign up
  /// Only calls Firebase Auth - navigation happens automatically via authStateChanges
  Future<void> _handleEmailSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (!success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(authProvider.errorMessage ?? 'Sign up failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
          // If success, AuthWrapperScreen will automatically navigate via authStateChanges
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign up failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// Handle phone authentication - Step 1: Send verification code
  Future<void> _handlePhoneAuth() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final phoneNumber = _phoneController.text.trim();
      
      // Ensure phone number starts with + for international format
      final formattedPhone = phoneNumber.startsWith('+') 
          ? phoneNumber 
          : '+91$phoneNumber'; // Default to India (+91)

      await authProvider.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        onCodeSent: (verificationId) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _verificationId = verificationId;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification code sent to your phone'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    }
  }

  /// Handle phone authentication - Step 2: Verify SMS code
  /// Only calls Firebase Auth - navigation happens automatically via authStateChanges
  Future<void> _handlePhoneVerify() async {
    if (_smsCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the verification code'),
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
      final success = await authProvider.signInWithPhoneNumber(
        verificationId: _verificationId!,
        smsCode: _smsCodeController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.errorMessage ?? 'Verification failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
        // If success, AuthWrapperScreen will automatically navigate via authStateChanges
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App logo/icon
                  Icon(
                    Icons.favorite,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  
                  // App title
                  Text(
                    'GERSHA',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Donate & Rent Platform',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),

                  // Tab bar for Email/Phone
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: 'Email'),
                      Tab(text: 'Phone'),
                    ],
                    onTap: (index) {
                      setState(() {
                        _isPhoneAuth = index == 1;
                        _verificationId = null;
                        _smsCodeController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Email/Password form
                  if (!_isPhoneAuth) ...[
                    // Name field (only for sign up)
                    if (_isSignUp)
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name (Optional)',
                          hintText: 'Enter your name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    if (_isSignUp) const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'user@example.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Sign in/Sign up button
                    ElevatedButton(
                      onPressed: _isLoading ? null : (_isSignUp ? _handleEmailSignUp : _handleEmailSignIn),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isSignUp ? 'Sign Up' : 'Sign In',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Toggle sign in/sign up
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                        });
                      },
                      child: Text(
                        _isSignUp
                            ? 'Already have an account? Sign In'
                            : 'Don\'t have an account? Sign Up',
                      ),
                    ),
                  ],

                  // Phone authentication form
                  if (_isPhoneAuth) ...[
                    // Phone number field
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '+91-9876543210',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                      enabled: _verificationId == null,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // SMS code field (shown after code is sent)
                    if (_verificationId != null) ...[
                      TextFormField(
                        controller: _smsCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Verification Code',
                          hintText: 'Enter 6-digit code',
                          prefixIcon: Icon(Icons.sms),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Send code / Verify button
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : (_verificationId == null ? _handlePhoneAuth : _handlePhoneVerify),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _verificationId == null ? 'Send Verification Code' : 'Verify Code',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
