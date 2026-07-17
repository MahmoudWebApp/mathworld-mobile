import 'package:flutter/material.dart';

import '../config/design_tokens.dart';

/// A responsive gradient button that safely adapts to narrow layouts.
class PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;
  final EdgeInsetsGeometry padding;

  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkBackground
        : Colors.white;

    final child = Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: padding,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppGradients.primary,
        color: onPressed == null
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: isLoading
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: foreground),
              )
            : Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 19, color: foreground),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: foreground),
                    ),
                  ),
                ],
              ),
      ),
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: child,
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
