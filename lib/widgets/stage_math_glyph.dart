import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Accessible, lightweight geometry ornament shared across MathWorld stages.
/// This is decorative line art, not an image asset or an interactive control.
class StageMathGlyph extends StatelessWidget {
  const StageMathGlyph({
    super.key,
    required this.stageOrder,
    required this.color,
    this.size = 44,
  });

  final int stageOrder;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _StageGeometryPainter(
              order: stageOrder,
              color: color,
            ),
          ),
        ),
      );
}

class _StageGeometryPainter extends CustomPainter {
  const _StageGeometryPainter({required this.order, required this.color});
  final int order;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final middle = rect.center;
    final r = math.min(size.width, size.height) * .37;
    final paint = Paint()
      ..color = color
      ..strokeWidth = math.max(1.5, size.shortestSide * .038)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final lighter = Paint()
      ..color = color.withValues(alpha: .48)
      ..strokeWidth = paint.strokeWidth * .65
      ..style = PaintingStyle.stroke;

    switch ((order <= 0 ? 0 : order - 1) % 4) {
      case 0:
        canvas.drawCircle(middle, r, paint);
        canvas.drawLine(Offset(middle.dx - r, middle.dy),
            Offset(middle.dx + r, middle.dy), lighter);
        canvas.drawLine(Offset(middle.dx, middle.dy - r),
            Offset(middle.dx, middle.dy + r), lighter);
        canvas.drawCircle(middle, r * .32, paint);
        break;
      case 1:
        final top = Offset(middle.dx, middle.dy - r);
        final left = Offset(middle.dx - r, middle.dy + r * .75);
        final right = Offset(middle.dx + r, middle.dy + r * .75);
        final triangle = Path()..moveTo(top.dx, top.dy)
          ..lineTo(left.dx, left.dy)..lineTo(right.dx, right.dy)..close();
        canvas.drawPath(triangle, paint);
        canvas.drawLine(top, middle, lighter);
        canvas.drawCircle(middle, r * .13, paint);
        break;
      case 2:
        canvas.save();
        canvas.translate(middle.dx, middle.dy);
        canvas.rotate(.22);
        canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: r * 1.7,
              height: r * 1.7), Radius.circular(r * .22)), paint);
        canvas.rotate(.56);
        canvas.drawRect(Rect.fromCenter(center: Offset.zero,
            width: r * 1.02, height: r * 1.02), lighter);
        canvas.restore();
        break;
      case 3:
        canvas.save();
        canvas.translate(middle.dx, middle.dy);
        canvas.rotate(.55);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero,
            width: 2 * r, height: r * .78), paint);
        canvas.rotate(-1.1);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero,
            width: 2 * r, height: r * .78), lighter);
        canvas.restore();
        canvas.drawCircle(middle, r * .12, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _StageGeometryPainter oldDelegate) =>
      oldDelegate.order != order || oldDelegate.color != color;
}
