import 'package:flutter/material.dart';

import '../config/design_tokens.dart';

/// Defines where the icon appears relative to the button label.
enum PremiumButtonIconPlacement {
  leading,
  trailing,
}

/// A responsive gradient button that supports RTL and LTR layouts.
class PremiumButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final PremiumButtonIconPlacement iconPlacement;
  final bool isLoading;
  final bool expand;
  final EdgeInsetsGeometry padding;

  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconPlacement = PremiumButtonIconPlacement.leading,
    this.isLoading = false,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: 14,
    ),
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.brightness == Brightness.dark
        ? AppColors.darkBackground
        : Colors.white;

    final labelWidget = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          color: foreground,
        ),
      ),
    );

    final iconWidget = icon == null
        ? null
        : Icon(
            icon,
            size: 19,
            color: foreground,
            textDirection: Directionality.of(context),
          );

    final content = _buildContent(
      labelWidget: labelWidget,
      iconWidget: iconWidget,
    );

    final child = Container(
      constraints: const BoxConstraints(
        minHeight: 50,
      ),
      padding: padding,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : AppGradients.primary,
        color: onPressed == null
            ? theme.colorScheme.surfaceContainerHighest
            : null,
        borderRadius: BorderRadius.circular(
          AppRadius.md,
        ),
      ),
      child: Center(
        child: isLoading
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: content,
              ),
      ),
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(
          AppRadius.md,
        ),
        child: child,
      ),
    );

    if (expand) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  List<Widget> _buildContent({
    required Widget labelWidget,
    required Widget? iconWidget,
  }) {
    if (iconWidget == null) {
      return [labelWidget];
    }

    if (iconPlacement == PremiumButtonIconPlacement.trailing) {
      return [
        labelWidget,
        const SizedBox(width: 8),
        iconWidget,
      ];
    }

    return [
      iconWidget,
      const SizedBox(width: 8),
      labelWidget,
    ];
  }
}
