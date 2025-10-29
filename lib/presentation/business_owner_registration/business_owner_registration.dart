import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/registration_form_widget.dart';
import './widgets/registration_progress_widget.dart';
import './widgets/terms_checkbox_widget.dart';

class BusinessOwnerRegistration extends StatefulWidget {
  const BusinessOwnerRegistration({super.key});

  @override
  State<BusinessOwnerRegistration> createState() =>
      _BusinessOwnerRegistrationState();
}

class _BusinessOwnerRegistrationState extends State<BusinessOwnerRegistration> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isTermsAccepted = false;
  bool _isLoading = false;
  bool _isUsernameAvailable = true;
  bool _isCheckingUsername = false;

  Timer? _usernameCheckTimer;

  // Mock existing usernames for validation
  final List<String> _existingUsernames = [
    'admin',
    'test',
    'user',
    'business',
    'owner',
    'demo',
    'sample'
  ];

  // Mock existing emails for validation
  final List<String> _existingEmails = [
    'admin@example.com',
    'test@example.com',
    'demo@business.com'
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameCheckTimer?.cancel();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  void _onUsernameChanged(String username) {
    _usernameCheckTimer?.cancel();

    if (username.isEmpty) {
      setState(() {
        _isUsernameAvailable = true;
        _isCheckingUsername = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
    });

    _usernameCheckTimer = Timer(const Duration(milliseconds: 800), () {
      _checkUsernameAvailability(username);
    });
  }

  void _checkUsernameAvailability(String username) {
    // Simulate API call delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isUsernameAvailable =
              !_existingUsernames.contains(username.toLowerCase());
          _isCheckingUsername = false;
        });
      }
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  void _onTermsChanged(bool? value) {
    setState(() {
      _isTermsAccepted = value ?? false;
    });
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isTermsAccepted) {
      _showErrorMessage(
          'Please accept the Terms of Service and Privacy Policy');
      return;
    }

    if (!_isUsernameAvailable) {
      _showErrorMessage('Please choose a different username');
      return;
    }

    // Check if email already exists
    if (_existingEmails.contains(_emailController.text.toLowerCase())) {
      _showErrorMessage('An account with this email already exists');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate account creation API call
      await Future.delayed(const Duration(seconds: 2));

      // Simulate success
      HapticFeedback.lightImpact();

      if (mounted) {
        _showSuccessMessage('Account created successfully!');

        // Navigate to login or dashboard after a brief delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/business-owner-login');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to create account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.lightTheme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successLight,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(4.w),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Business Account',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        leading: IconButton(
          onPressed: () => Navigator.pushReplacementNamed(
              context, '/account-type-selection'),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
        elevation: 0,
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            RegistrationProgressWidget(
              currentStep: 1,
              totalSteps: 1,
            ),

            // Scrollable Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Text
                    Text(
                      'Join DualAuth Business',
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Create your business account to manage authentication and access powerful features.',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 4.h),

                    // Registration Form
                    RegistrationFormWidget(
                      formKey: _formKey,
                      businessNameController: _businessNameController,
                      ownerNameController: _ownerNameController,
                      emailController: _emailController,
                      usernameController: _usernameController,
                      passwordController: _passwordController,
                      confirmPasswordController: _confirmPasswordController,
                      isPasswordVisible: _isPasswordVisible,
                      isConfirmPasswordVisible: _isConfirmPasswordVisible,
                      onPasswordVisibilityToggle: _togglePasswordVisibility,
                      onConfirmPasswordVisibilityToggle:
                          _toggleConfirmPasswordVisibility,
                      onUsernameChanged: _onUsernameChanged,
                      isUsernameAvailable: _isUsernameAvailable,
                      isCheckingUsername: _isCheckingUsername,
                    ),

                    SizedBox(height: 3.h),

                    // Terms and Privacy Policy Checkbox
                    TermsCheckboxWidget(
                      isAccepted: _isTermsAccepted,
                      onChanged: _onTermsChanged,
                    ),

                    SizedBox(height: 4.h),

                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 6.h,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isTermsAccepted && !_isLoading
                              ? AppTheme.lightTheme.colorScheme.primary
                              : AppTheme.lightTheme.colorScheme.outline,
                          foregroundColor:
                              AppTheme.lightTheme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : Text(
                                'Create Account',
                                style: AppTheme.lightTheme.textTheme.labelLarge
                                    ?.copyWith(
                                  color:
                                      AppTheme.lightTheme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    SizedBox(height: 3.h),

                    // Already have account link
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/business-owner-login'),
                        child: RichText(
                          text: TextSpan(
                            style: AppTheme.lightTheme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
