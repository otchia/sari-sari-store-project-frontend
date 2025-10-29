import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/account_switch_widget.dart';
import './widgets/biometric_prompt_widget.dart';
import './widgets/login_form_widget.dart';

class BusinessOwnerLogin extends StatefulWidget {
  const BusinessOwnerLogin({Key? key}) : super(key: key);

  @override
  State<BusinessOwnerLogin> createState() => _BusinessOwnerLoginState();
}

class _BusinessOwnerLoginState extends State<BusinessOwnerLogin> {
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _showBiometricPrompt = false;
  String? _errorMessage;

  // Mock credentials for demonstration
  final Map<String, String> _mockCredentials = {
    'admin@business.com': 'admin123',
    'owner@company.com': 'owner123',
    'manager@store.com': 'manager123',
    'business_admin': 'admin123',
    'store_owner': 'owner123',
  };

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    // Simulate biometric availability check
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isBiometricAvailable = true;
        _showBiometricPrompt = true;
      });
    }
  }

  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Check mock credentials
      final storedPassword = _mockCredentials[email.toLowerCase()];

      if (storedPassword == null) {
        throw Exception('Account not found. Please check your email/username.');
      }

      if (storedPassword != password) {
        throw Exception('Invalid password. Please try again.');
      }

      // Success - trigger haptic feedback
      HapticFeedback.mediumImpact();

      // Navigate to business dashboard (simulated)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back! Redirecting to dashboard...'),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          ),
        );

        // Simulate navigation to dashboard
        await Future.delayed(const Duration(seconds: 1));
        // Navigator.pushReplacementNamed(context, '/business-dashboard');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate biometric authentication
      await Future.delayed(const Duration(seconds: 1));

      // Simulate successful biometric authentication
      HapticFeedback.lightImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Biometric authentication successful!'),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
          ),
        );

        // Navigate to dashboard
        await Future.delayed(const Duration(seconds: 1));
        // Navigator.pushReplacementNamed(context, '/business-dashboard');
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometric authentication failed. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSwitchToCustomer() {
    Navigator.pushNamed(context, '/customer-login');
  }

  void _handleBackToSelection() {
    Navigator.pushNamed(context, '/login-selection');
  }

  void _dismissBiometricPrompt() {
    setState(() {
      _showBiometricPrompt = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _isLoading ? null : _handleBackToSelection,
                    icon: CustomIconWidget(
                      iconName: 'arrow_back',
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 6.w,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Business Login',
                    style: AppTheme.lightTheme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2.h),

                    // Welcome text
                    Text(
                      'Welcome Back',
                      style: AppTheme.lightTheme.textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                    ),

                    SizedBox(height: 1.h),

                    Text(
                      'Sign in to your business account to access your dashboard and manage your operations.',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Biometric prompt (if available and not dismissed)
                    if (_showBiometricPrompt &&
                        _isBiometricAvailable &&
                        !_isLoading)
                      BiometricPromptWidget(
                        onBiometricLogin: _handleBiometricLogin,
                        onSkip: _dismissBiometricPrompt,
                        isAvailable: _isBiometricAvailable,
                      ),

                    // Error message
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(3.w),
                        margin: EdgeInsets.only(bottom: 3.h),
                        decoration: BoxDecoration(
                          color: AppTheme.lightTheme.colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.lightTheme.colorScheme.error
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            CustomIconWidget(
                              iconName: 'error_outline',
                              color: AppTheme.lightTheme.colorScheme.error,
                              size: 5.w,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                      color:
                                          AppTheme
                                              .lightTheme
                                              .colorScheme
                                              .onErrorContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Login form
                    LoginFormWidget(
                      onLogin: _handleLogin,
                      isLoading: _isLoading,
                    ),

                    // Account switch widget
                    AccountSwitchWidget(
                      onSwitchToCustomer: _handleSwitchToCustomer,
                    ),

                    SizedBox(height: 4.h),

                    // Additional help text - REMOVED CREATE ACCOUNT OPTION
                    Center(
                      child: Text(
                        'Need help signing in?',
                        style: AppTheme.lightTheme.textTheme.bodySmall
                            ?.copyWith(
                              color:
                                  AppTheme
                                      .lightTheme
                                      .colorScheme
                                      .onSurfaceVariant,
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
