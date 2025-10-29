import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LoginOptionCard extends StatefulWidget {
  final String title;
  final String description;
  final String iconName;
  final VoidCallback onTap;
  final bool isGoogleOption;

  const LoginOptionCard({
    Key? key,
    required this.title,
    required this.description,
    required this.iconName,
    required this.onTap,
    this.isGoogleOption = false,
  }) : super(key: key);

  @override
  State<LoginOptionCard> createState() => _LoginOptionCardState();
}

class _LoginOptionCardState extends State<LoginOptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: () {
              _animationController.reverse();
              widget.onTap();
            },
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: 16.h,
                maxHeight: 20.h,
              ),
              margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.outline,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12.w,
                          height: 12.w,
                          decoration: BoxDecoration(
                            color: widget.isGoogleOption
                                ? Colors.white
                                : AppTheme
                                    .lightTheme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                            border: widget.isGoogleOption
                                ? Border.all(
                                    color:
                                        AppTheme.lightTheme.colorScheme.outline,
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Center(
                            child: widget.isGoogleOption
                                ? CustomImageWidget(
                                    imageUrl:
                                        "https://developers.google.com/identity/images/g-logo.png",
                                    width: 6.w,
                                    height: 6.w,
                                    fit: BoxFit.contain,
                                    semanticLabel:
                                        "Google logo with colorful G letter",
                                  )
                                : CustomIconWidget(
                                    iconName: widget.iconName,
                                    color:
                                        AppTheme.lightTheme.colorScheme.primary,
                                    size: 6.w,
                                  ),
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: AppTheme.lightTheme.textTheme.titleMedium
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      AppTheme.lightTheme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                widget.description,
                                style: AppTheme.lightTheme.textTheme.bodyMedium
                                    ?.copyWith(
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        CustomIconWidget(
                          iconName: 'arrow_forward_ios',
                          color:
                              AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          size: 4.w,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
