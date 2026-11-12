import 'package:flutter/material.dart';

import '../config/design_tokens.dart';

/// Shared lockup using the approved cap / sigma / x² symbol.
class BrandLogo extends StatelessWidget {
  final double width;
  final double? height;
  final BoxFit fit;
  final String? semanticsLabel;

  const BrandLogo({
    super.key,
    this.width = 170,
    this.height,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final markSize = height != null ? (height! < 52 ? height! : 52.0) : 48.0;
    return Semantics(
      label: semanticsLabel ?? 'MathWorld',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(size: markSize),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  alignment: AlignmentDirectional.centerStart,
                  fit: fit == BoxFit.fill ? BoxFit.scaleDown : fit,
                  child: Text(
                    'MathWorld',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: dark ? const Color(0xFFEC4899) : AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Exact user-proposed image, resized, without redrawing its symbols.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/branding/mathworld-mark.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        semanticLabel: 'MathWorld',
      ),
    );
  }
}
