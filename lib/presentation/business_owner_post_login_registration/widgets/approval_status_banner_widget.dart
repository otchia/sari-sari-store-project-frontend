import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ApprovalStatusBannerWidget extends StatelessWidget {
  final String status;
  final String estimatedTime;

  const ApprovalStatusBannerWidget({
    Key? key,
    required this.status,
    required this.estimatedTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _getStatusColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: _getStatusIcon(),
              color: _getStatusColor(),
              size: 5.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusTitle(),
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _getStatusMessage(),
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'approved':
        return AppTheme.lightTheme.colorScheme.tertiary;
      case 'rejected':
        return AppTheme.lightTheme.colorScheme.error;
      default:
        return const Color(0xFFFF9800);
    }
  }

  String _getStatusIcon() {
    switch (status) {
      case 'pending':
        return 'schedule';
      case 'approved':
        return 'check_circle';
      case 'rejected':
        return 'error';
      default:
        return 'schedule';
    }
  }

  String _getStatusTitle() {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Application Approved';
      case 'rejected':
        return 'Application Rejected';
      default:
        return 'Pending Review';
    }
  }

  String _getStatusMessage() {
    switch (status) {
      case 'pending':
        return 'Your application is under review. Estimated time: $estimatedTime';
      case 'approved':
        return 'Congratulations! Your business account has been approved.';
      case 'rejected':
        return 'Please review and resubmit your application with correct information.';
      default:
        return 'Your application is under review. Estimated time: $estimatedTime';
    }
  }
}
