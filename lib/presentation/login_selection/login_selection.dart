import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/login_option_card.dart';
import './widgets/new_user_link.dart';
import './widgets/welcome_header.dart';

class LoginSelection extends StatefulWidget {
  const LoginSelection({Key? key}) : super(key: key);

  @override
  State<LoginSelection> createState() => _LoginSelectionState();
}

class _LoginSelectionState extends State<LoginSelection> {
  String? _lastUsedLoginMethod;

  @override
  void initState() {
    super.initState();
    _loadLastUsedLoginMethod();
  }

  void _loadLastUsedLoginMethod() {
    // In a real app, this would load from SharedPreferences
    // For now, we'll simulate having a last used method
    setState(() {
      _lastUsedLoginMethod = 'business_owner'; // Mock last used method
    });
  }

  void _handleBusinessOwnerLogin() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/business-owner-login');
  }

  void _handleCustomerLogin() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/customer-login');
  }

  void _handleNewUserTap() {
    Navigator.pushNamed(context, '/account-type-selection');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              children: [
                SizedBox(height: 4.h),
                // Welcome Header with Logo
                const WelcomeHeader(),
                SizedBox(height: 4.h),
                // Login Options
                Flexible(
                  child: Column(
                    children: [
                      // Business Owner Login Card
                      Stack(
                        children: [
                          LoginOptionCard(
                            title: 'Business Owner Login',
                            description: 'Sign in with email and password',
                            iconName: 'business',
                            onTap: _handleBusinessOwnerLogin,
                          ),
                          if (_lastUsedLoginMethod == 'business_owner')
                            Positioned(
                              top: 1.h,
                              right: 6.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Recent',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 2.h),
                      // Customer Login Card
                      Stack(
                        children: [
                          LoginOptionCard(
                            title: 'Customer Login',
                            description: 'Continue with Google account',
                            iconName: 'person',
                            onTap: _handleCustomerLogin,
                            isGoogleOption: true,
                          ),
                          if (_lastUsedLoginMethod == 'customer')
                            Positioned(
                              top: 1.h,
                              right: 6.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 0.5.h,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.lightTheme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Recent',
                                  style: AppTheme
                                      .lightTheme.textTheme.labelSmall
                                      ?.copyWith(
                                    color: AppTheme
                                        .lightTheme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 6.h),
                // New User Link
                NewUserLink(
                  onTap: _handleNewUserTap,
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
