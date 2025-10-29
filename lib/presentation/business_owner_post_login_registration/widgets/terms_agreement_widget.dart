import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TermsAgreementWidget extends StatelessWidget {
  final bool isAccepted;
  final ValueChanged<bool?> onChanged;

  const TermsAgreementWidget({
    Key? key,
    required this.isAccepted,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms and Business Agreement',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isAccepted,
                onChanged: onChanged,
                activeColor: AppTheme.lightTheme.primaryColor,
                checkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(
                        text: 'I agree to the ',
                      ),
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () =>
                              _showTermsDialog(context, 'Terms of Service'),
                      ),
                      const TextSpan(
                        text: ', ',
                      ),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap =
                              () => _showTermsDialog(context, 'Privacy Policy'),
                      ),
                      const TextSpan(
                        text: ', and ',
                      ),
                      TextSpan(
                        text: 'Business Agreement',
                        style: TextStyle(
                          color: AppTheme.lightTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () =>
                              _showTermsDialog(context, 'Business Agreement'),
                      ),
                      const TextSpan(
                        text:
                            '. I confirm that all provided information is accurate and I understand that false information may result in account suspension.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getTermsContent(title),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: AppTheme.lightTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  String _getTermsContent(String title) {
    switch (title) {
      case 'Terms of Service':
        return '''1. Acceptance of Terms
By using our business registration service, you agree to be bound by these terms and conditions.

2. Business Account Usage
Your business account must only be used for legitimate business purposes and in compliance with all applicable laws.

3. Information Accuracy
You are responsible for providing accurate and up-to-date business information.

4. Account Security
You are responsible for maintaining the security of your business account credentials.

5. Service Availability
We strive to provide continuous service but cannot guarantee 100% uptime.

6. Limitation of Liability
Our liability is limited to the extent permitted by law.

7. Termination
We reserve the right to terminate accounts that violate these terms.''';

      case 'Privacy Policy':
        return '''1. Information Collection
We collect business information necessary to provide our services and verify your business identity.

2. Use of Information
Your information is used to:
- Process your business registration
- Verify business credentials
- Provide customer support
- Send important service updates

3. Information Sharing
We do not sell your personal information to third parties. We may share information with:
- Regulatory bodies when required by law
- Service providers who assist in business verification
- Partners who help us provide our services

4. Data Security
We implement industry-standard security measures to protect your information.

5. Data Retention
We retain your information as long as your account is active or as needed to provide services.

6. Your Rights
You have the right to access, update, or delete your personal information.''';

      case 'Business Agreement':
        return '''1. Business Verification
All business registrations are subject to verification and approval processes.

2. Compliance Requirements
Your business must comply with all local, state, and federal regulations.

3. Service Standards
We expect all registered businesses to maintain professional service standards.

4. Fee Structure
Business registration and ongoing service fees are as outlined in our pricing schedule.

5. Support Services
Registered businesses have access to our business support services during regular business hours.

6. Account Management
Business owners are responsible for managing their account settings and keeping information current.

7. Dispute Resolution
Any disputes will be resolved through our standard business dispute resolution process.

8. Agreement Updates
This agreement may be updated periodically with notice to registered businesses.''';

      default:
        return 'Terms and conditions content not available.';
    }
  }
}
