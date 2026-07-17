import 'package:flutter/material.dart';

/// Paints a subtle ambient background that never competes with content.
class MathBackground extends StatelessWidget {
  final Widget child;
  final bool showSymbols;

  const MathBackground({
    super.key,
    required this.child,
    this.showSymbols = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final background = Theme.of(context).scaffoldBackgroundColor;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.72, -0.92),
          radius: 1.25,
          colors: [
            scheme.primary.withValues(alpha: isDark ? 0.055 : 0.038),
            background,
            background,
          ],
          stops: const [0, 0.36, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _MathGridPainter(
              color: scheme.primary.withValues(
                alpha: isDark ? 0.018 : 0.012,
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
    final color =
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.028);
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 90,
            left: 24,
            child: _Symbol('π', color, 30, -0.10),
          ),
          Positioned(
            bottom: 130,
            right: 28,
            child: _Symbol('∞', color, 36, 0.08),
          ),
        ],
      ),
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
