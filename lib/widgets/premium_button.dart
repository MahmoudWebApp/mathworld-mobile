import 'package:flutter/material.dart';

import '../config/design_tokens.dart';
import '../utils/layout_utils.dart';

/// A responsive gradient button that safely adapts to narrow layouts.
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool expand;
  final EdgeInsetsGeometry padding;
  final Gradient gradient;

  const PremiumButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.expand = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    this.gradient = AppGradients.primary,
  });

  @override
  State<PremiumButton> createState()=>_PremiumButtonState();
}
class _PremiumButtonState extends State<PremiumButton>{
  bool _pressed=false;
  @override
  Widget build(BuildContext context) {
    final PremiumButton(:label,:onPressed,:leadingIcon,:trailingIcon,:isLoading,:expand,:padding,:gradient)=widget;
    // A dark text color on the purple half of the gradient had insufficient
    // contrast. Use the same legible white foreground across both themes.
    const foreground = Colors.white;
    final actionGradient = gradient;
    final isEnabled = onPressed != null && !isLoading;

    final child = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: padding,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : actionGradient,
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
                  strokeWidth: 2,
                  color: foreground,
                ),
              )
            : Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcon != null) ...[
                    Icon(
                      LayoutUtils.resolveSemanticIcon(context, leadingIcon),
                      size: 19,
                      color: foreground,
                      textDirection: TextDirection.ltr,
                    ),
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
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 8),
                    Icon(
                      LayoutUtils.resolveSemanticIcon(context, trailingIcon),
                      size: 19,
                      color: foreground,
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ],
              ),
      ),
    );

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        onHighlightChanged:isEnabled?(value)=>setState(()=>_pressed=value):null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: child,
      ),
    );

    final motion=AnimatedScale(scale:_pressed&&isEnabled&&!MediaQuery.disableAnimationsOf(context)?0.97:1.0,duration:MediaQuery.disableAnimationsOf(context)?Duration.zero:const Duration(milliseconds:100),child:button);
    if (expand) return SizedBox(width: double.infinity,child:motion);
    return motion;
  }
}