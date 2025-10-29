import 'package:flutter/material.dart';
import '../presentation/business_owner_registration/business_owner_registration.dart';
import '../presentation/login_selection/login_selection.dart';
import '../presentation/business_owner_login/business_owner_login.dart';
import '../presentation/customer_login/customer_login.dart';
import '../presentation/account_type_selection/account_type_selection.dart';
import '../presentation/business_owner_post_login_registration/business_owner_post_login_registration.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String businessOwnerRegistration =
      '/business-owner-registration';
  static const String loginSelection = '/login-selection';
  static const String businessOwnerLogin = '/business-owner-login';
  static const String customerLogin = '/customer-login';
  static const String accountTypeSelection = '/account-type-selection';
  static const String businessOwnerPostLoginRegistration =
      '/business-owner-post-login-registration';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const AccountTypeSelection(),
    businessOwnerRegistration: (context) => const BusinessOwnerRegistration(),
    loginSelection: (context) => const LoginSelection(),
    businessOwnerLogin: (context) => const BusinessOwnerLogin(),
    customerLogin: (context) => const CustomerLogin(),
    accountTypeSelection: (context) => const AccountTypeSelection(),
    businessOwnerPostLoginRegistration: (context) =>
        const BusinessOwnerPostLoginRegistration(),
    // TODO: Add your other routes here
  };
}
