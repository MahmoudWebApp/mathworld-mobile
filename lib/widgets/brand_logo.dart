import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Displays the transparent MathWorld brand asset for the active theme.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SvgPicture.asset(
      isDark
          ? 'assets/branding/mathworld-logo-dark.svg'
          : 'assets/branding/mathworld-logo-light.svg',
      width: width,
      height: height,
      fit: fit,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: semanticsLabel == null,
    );
  }
}

/// Displays the compact MathWorld mark used in small branded surfaces.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({
    super.key,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/branding/mathworld-mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: 'MathWorld',
    );
  }
}
