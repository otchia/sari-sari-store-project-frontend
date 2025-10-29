import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import './widgets/account_type_card.dart';
import './widgets/app_logo_widget.dart';
import './widgets/sign_in_link_widget.dart';

class AccountTypeSelection extends StatefulWidget {
  const AccountTypeSelection({Key? key}) : super(key: key);

  @override
  State<AccountTypeSelection> createState() => _AccountTypeSelectionState();
}

class _AccountTypeSelectionState extends State<AccountTypeSelection> {
  String? selectedAccountType;

  final List<Map<String, dynamic>> accountTypes = [
    {
      "type": "business_owner",
      "title": "Business Owner",
      "description": "Login-only access for business management",
      "iconName": "business",
      "features": [],
      "route": "/business-owner-login",
    },
    {
      "type": "customer",
      "title": "Customer",
      "description": "Quick access for customers",
      "iconName": "person",
      "features": [],
      "route": "/customer-login",
    },
  ];

  void _handleAccountTypeSelection(String accountType, String route) {
    HapticFeedback.lightImpact();
    setState(() {
      selectedAccountType = accountType;
    });

    // Navigate after a brief delay to show selection
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        Navigator.pushNamed(context, route);
      }
    });
  }

  void _handleSignInTap() {
    HapticFeedback.lightImpact();
    Navigator.pushNamed(context, '/login-selection');
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

                // App Logo Section
                const AppLogoWidget(),

                SizedBox(height: 4.h),

                // Account Type Cards Section
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: accountTypes.length,
                    itemBuilder: (context, index) {
                      final accountType = accountTypes[index];
                      return AccountTypeCard(
                        title: accountType["title"] as String,
                        description: accountType["description"] as String,
                        iconName: accountType["iconName"] as String,
                        features:
                            (accountType["features"] as List).cast<String>(),
                        isSelected: selectedAccountType == accountType["type"],
                        onTap: () => _handleAccountTypeSelection(
                          accountType["type"] as String,
                          accountType["route"] as String,
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 4.h),

                // Sign In Link Section
                SignInLinkWidget(
                  onTap: _handleSignInTap,
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
