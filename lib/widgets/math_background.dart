import 'package:flutter/material.dart';

import '../config/design_tokens.dart';
import 'stage_math_glyph.dart';

/// Paints a subtle MathWorld-branded ambient background.
class MathBackground extends StatelessWidget {
  final Widget child;
  final bool showSymbols;

  const MathBackground({
    super.key,
    required this.child,
    this.showSymbols = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return ColoredBox(
      color: background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.86, -0.96),
                radius: 1.05,
                colors: [
                  AppColors.brandCyan.withValues(
                    alpha: isDark ? 0.070 : 0.045,
                  ),
                  Colors.transparent,
                ],
                stops: const [0, 0.74],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.92, -0.72),
                radius: 1.12,
                colors: [
                  AppColors.brandPurple.withValues(
                    alpha: isDark ? 0.065 : 0.035,
                  ),
                  Colors.transparent,
                ],
                stops: const [0, 0.76],
              ),
            ),
          ),
          CustomPaint(
            painter: _MathGridPainter(
              color: AppColors.brandCyan.withValues(
                alpha: isDark ? 0.012 : 0.023,
              ),
            ),
          ),
          if (showSymbols) const _AmbientSymbolLayer(),
          child,
        ],
      ),
    );
  }
}

class _AmbientSymbolLayer extends StatelessWidget {
  const _AmbientSymbolLayer();
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: RepaintBoundary(child: Stack(
        children: [
          Positioned(top: 175, right: 28, child: _Symbol('Σ', AppColors.brandPurple.withValues(alpha: isDark ? .065 : .045), 26, .1)),
          Positioned(bottom: 220, left: 35, child: _Symbol('√x', AppColors.brandCyan.withValues(alpha: isDark ? .065 : .045), 24, -.08)),
          Positioned(top: 285, left: 18, child: _Symbol('∫', AppColors.brandPurple.withValues(alpha: isDark ? .06 : .04), 34, .08)),
          Positioned(bottom: 32, right: 90, child: _Symbol('△', AppColors.brandPurple.withValues(alpha: isDark ? .06 : .04), 30, -.12)),
          Positioned(
            top: 32,
            right: 18,
            child: StageMathGlyph(
              stageOrder: 2,
              color: AppColors.stageOrange.withValues(alpha: isDark ? .13 : .08),
              size: 84,
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            child: StageMathGlyph(
              stageOrder: 3,
              color: AppColors.stageGreen.withValues(alpha: isDark ? .12 : .07),
              size: 98,
            ),
          ),
          Positioned(
            top: 90,
            left: 24,
            child: _Symbol(
              'π',
              AppColors.brandPurple.withValues(
                alpha: isDark ? 0.050 : 0.055,
              ),
              30,
              -0.10,
            ),
          ),
          Positioned(
            bottom: 130,
            right: 28,
            child: _Symbol(
              '∞',
              AppColors.brandCyan.withValues(
                alpha: isDark ? 0.050 : 0.038,
              ),
              36,
              0.08,
            ),
          ),
        ],
      )),
    );
  }
}

class _Symbol extends StatelessWidget {
  final String symbol;
  final Color color;
  final double size;
  final double angle;

  const _Symbol(this.symbol, this.color, this.size, this.angle);

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Text(
        symbol,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MathGridPainter extends CustomPainter {
  final Color color;

  const _MathGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 72.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.6;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MathGridPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}