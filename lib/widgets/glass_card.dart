import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/design_tokens.dart';

/// A blurred elevated surface with optional interaction and custom decoration.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final double blur;
  final Color? color;
  final BorderSide? border;
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.gradient,
    this.blur = 0,
    this.color,
    this.border,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(AppRadius.lg);
    final effectiveBorder =
        border ?? BorderSide(color: scheme.outline.withValues(alpha: 0.88));
    final decoration = BoxDecoration(
        color: gradient == null
            ? (color ?? scheme.surface).withValues(
                alpha: blur > 0 ? (isDark ? 0.84 : 0.90) : 1,
              )
            : null,
        gradient: gradient,
        borderRadius: radius,
        border: Border.fromBorderSide(effectiveBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.11 : 0.032),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      );
    // Ink is painted on its Material ancestor, so taps, keyboard focus
    // and ripples stay visible ABOVE the opaque/gradient card background.
    Widget content = onTap == null
        ? Container(
            padding: padding,
            decoration: decoration,
            child: child,
          )
        : Material(
            color: Colors.transparent,
            child: Ink(
              decoration: decoration,
              child: InkWell(
                onTap: onTap,
                borderRadius: radius,
                child: Padding(padding: padding, child: child),
              ),
            ),
          );
    if (blur > 0) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }
    return content;
  }
}