import 'dart:ui' as ui;

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
    final markSize = height != null ? (height! < 52 ? height! : 52.0) : 48.0;
    return Semantics(
      label: semanticsLabel ?? 'MathWorld',
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: Directionality(
            textDirection: ui.TextDirection.ltr,
            child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              BrandMark(size: markSize),
              const SizedBox(width: 10),
              Flexible(
                child: FittedBox(
                  alignment: AlignmentDirectional.centerStart,
                  fit: fit == BoxFit.fill ? BoxFit.scaleDown : fit,
                  child: const RepaintBoundary(child: _BrandWordmark()),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandWordmark extends StatefulWidget {
  const _BrandWordmark();
  @override
  State<_BrandWordmark> createState() => _BrandWordmarkState();
}

class _BrandWordmarkState extends State<_BrandWordmark> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 9));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: const Text('MathWorld', maxLines: 1, style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
    builder: (_, child) => ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        begin: Alignment(-1.5 + _controller.value, 0),
        end: Alignment(1.5 - _controller.value * .3, 0),
        colors: const [AppColors.brandPurple, AppColors.brandViolet, AppColors.brandPink],
      ).createShader(bounds),
      child: child,
    ),
  );
}

/// Exact user-proposed image, resized, without redrawing its symbols.
class BrandMark extends StatelessWidget {
  final double size;

  const BrandMark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    // Preserve the approved logo's full geometry and transparent margins.
    // BoxFit.cover and rounded clipping cropped the mark on narrow devices.
    return Image.asset(
      'assets/branding/mathworld-mark.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      filterQuality: FilterQuality.high,
      semanticLabel: 'MathWorld',
    );
  }
}
