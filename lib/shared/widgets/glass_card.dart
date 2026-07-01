import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blur;
  final bool highlight;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
    this.blur = 6,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlight ? AppColors.accentGlow : AppColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: highlight
                ? AppColors.accent.withValues(alpha: 0.2)
                : AppColors.border,
              width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }
}
