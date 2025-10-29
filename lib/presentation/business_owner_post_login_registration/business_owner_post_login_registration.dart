import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/approval_status_banner_widget.dart';
import './widgets/business_form_section_widget.dart';
import './widgets/document_upload_section_widget.dart';
import './widgets/terms_agreement_widget.dart';

class BusinessOwnerPostLoginRegistration extends StatefulWidget {
  const BusinessOwnerPostLoginRegistration({Key? key}) : super(key: key);

  @override
  State<BusinessOwnerPostLoginRegistration> createState() =>
      _BusinessOwnerPostLoginRegistrationState();
}

class _BusinessOwnerPostLoginRegistrationState
    extends State<BusinessOwnerPostLoginRegistration> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _registrationNumberController = TextEditingController();

  // Form state
  String? _selectedBusinessType;
  String? _selectedCountryCode = '+1';
  List<Map<String, dynamic>> _uploadedDocuments = [];
  bool _termsAccepted = false;
  bool _isSubmitting = false;

  // Approval state
  String _approvalStatus = 'pending'; // pending, approved, rejected
  String _estimatedReviewTime = '2-3 business days';

  final List<String> _businessTypes = [
    'Restaurant',
    'Retail Store',
    'Service Provider',
    'Technology Company',
    'Healthcare',
    'Education',
    'Manufacturing',
    'Other',
  ];

  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'country': 'US/CA'},
    {'code': '+44', 'country': 'UK'},
    {'code': '+91', 'country': 'IN'},
    {'code': '+86', 'country': 'CN'},
    {'code': '+49', 'country': 'DE'},
    {'code': '+33', 'country': 'FR'},
    {'code': '+81', 'country': 'JP'},
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _phoneController.dispose();
    _registrationNumberController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleLogout() {
    HapticFeedback.lightImpact();
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/account-type-selection',
      (route) => false,
    );
  }

  void _handleDocumentUpload(Map<String, dynamic> document) {
    setState(() {
      _uploadedDocuments.add(document);
    });
  }

  void _handleDocumentRemove(int index) {
    setState(() {
      _uploadedDocuments.removeAt(index);
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate() ||
        !_termsAccepted ||
        _uploadedDocuments.isEmpty) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Simulate submission process
      await Future.delayed(const Duration(seconds: 2));

      HapticFeedback.mediumImpact();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                const Text('Business registration submitted successfully!'),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        setState(() {
          _approvalStatus = 'pending';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Submission failed. Please try again.'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header with logout
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Complete Business Setup',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: _handleLogout,
                    child: Container(
                      padding: EdgeInsets.all(2.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CustomIconWidget(
                        iconName: 'logout',
                        color: AppTheme.lightTheme.colorScheme.error,
                        size: 5.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: _uploadedDocuments.isNotEmpty
                                ? AppTheme.lightTheme.primaryColor
                                : AppTheme.lightTheme.colorScheme.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: _termsAccepted
                                ? AppTheme.lightTheme.primaryColor
                                : AppTheme.lightTheme.colorScheme.outline,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Step 1 of 3: Business Information',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Approval status banner
            if (_approvalStatus == 'pending')
              ApprovalStatusBannerWidget(
                status: _approvalStatus,
                estimatedTime: _estimatedReviewTime,
              ),

            // Main content
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Business form section
                      BusinessFormSectionWidget(
                        businessNameController: _businessNameController,
                        businessAddressController: _businessAddressController,
                        phoneController: _phoneController,
                        registrationNumberController:
                            _registrationNumberController,
                        selectedBusinessType: _selectedBusinessType,
                        selectedCountryCode: _selectedCountryCode,
                        businessTypes: _businessTypes,
                        countryCodes: _countryCodes,
                        onBusinessTypeChanged: (value) {
                          setState(() {
                            _selectedBusinessType = value;
                          });
                        },
                        onCountryCodeChanged: (value) {
                          setState(() {
                            _selectedCountryCode = value;
                          });
                        },
                      ),

                      SizedBox(height: 3.h),

                      // Document upload section
                      DocumentUploadSectionWidget(
                        uploadedDocuments: _uploadedDocuments,
                        onDocumentUpload: _handleDocumentUpload,
                        onDocumentRemove: _handleDocumentRemove,
                      ),

                      SizedBox(height: 3.h),

                      // Terms agreement
                      TermsAgreementWidget(
                        isAccepted: _termsAccepted,
                        onChanged: (value) {
                          setState(() {
                            _termsAccepted = value ?? false;
                          });
                        },
                      ),

                      SizedBox(height: 4.h),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_formKey.currentState?.validate() ?? false) &&
                                      _termsAccepted &&
                                      _uploadedDocuments.isNotEmpty &&
                                      !_isSubmitting
                                  ? _handleSubmit
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.lightTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 4.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 5.w,
                                  width: 5.w,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  'Submit for Approval',
                                  style: AppTheme
                                      .lightTheme.textTheme.titleMedium
                                      ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
