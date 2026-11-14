import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Safe declarative geometry renderer. Coordinates match the web SVG viewport.
/// Invalid scenes fail closed without loading arbitrary SVG or remote assets.
class GeometryDiagram extends StatelessWidget {
  const GeometryDiagram({super.key, required this.scene, required this.isArabic});
  final Map<String, dynamic> scene;
  final bool isArabic;

  @override
  Widget build(BuildContext context) {
    if (!isValidGeometryScene(scene)) return const SizedBox.shrink();
    final viewport = Map<String, dynamic>.from(scene['viewport'] as Map);
    final width = (viewport['width'] as num).toDouble();
    final height = (viewport['height'] as num).toDouble();
    final description = (scene[isArabic ? 'altTextAr' : 'altTextEn'] as String);
    return Semantics(
      label: description,
      image: true,
      child: AspectRatio(
        aspectRatio: width / height,
        child: CustomPaint(
          painter: _GeometryPainter(
            (scene['objects'] as List).cast<Map<String, dynamic>>(),
            Theme.of(context).colorScheme.onSurface,
            width,
            height,
          ),
        ),
      ),
    );
  }
}

bool isValidGeometryScene(Map<String, dynamic> scene) {
  if (scene['schemaVersion'] != 1 ||
      scene['altTextAr'] is! String || scene['altTextEn'] is! String ||
      (scene['altTextAr'] as String).length > 500 ||
      (scene['altTextEn'] as String).length > 500 ||
      scene['viewport'] is! Map || scene['objects'] is! List) return false;
  final view = scene['viewport'] as Map;
  bool finite(dynamic n, {bool positive = false}) =>
      n is num && n.toDouble().isFinite && n.abs() <= 10000 &&
      (!positive || n > 0);
  if (!finite(view['width'], positive: true) ||
      !finite(view['height'], positive: true)) return false;
  final objects = scene['objects'] as List;
  if (objects.length > 100) return false;
  final ids = <String>{};
  for (final value in objects) {
    if (value is! Map<String, dynamic>) return false;
    final id = value['id'];
    if (id is! String || !RegExp(r'^[a-zA-Z0-9_-]{1,40}$').hasMatch(id) ||
        !ids.add(id) || (value['label'] != null &&
        (value['label'] is! String || (value['label'] as String).length > 80))) return false;
    bool coords(List<String> keys) => keys.every((k) => finite(value[k]));
    switch (value['type']) {
      case 'point': if (!coords(['x','y'])) { return false; }
      case 'segment': case 'ray': case 'vector': case 'line':
        if (!coords(['x1','y1','x2','y2']) ||
            (value['x1'] == value['x2'] && value['y1'] == value['y2'])) { return false; }
      case 'circle':
        if (!coords(['cx','cy']) || !finite(value['r'], positive: true)) { return false; }
      case 'polygon':
        final points = value['points'];
        if (points is! List || points.length < 3 || points.length > 30 ||
            !points.every((p) => p is Map && finite(p['x']) && finite(p['y']))) { return false; }
      case 'angle':
        if (!coords(['cx','cy','startDegrees','endDegrees']) ||
            !finite(value['radius'], positive: true) ||
            (value['endDegrees'] - value['startDegrees']).abs() == 0 ||
            (value['endDegrees'] - value['startDegrees']).abs() >= 360) { return false; }
      case 'axes':
        if (!coords(['originX','originY']) ||
            !finite(value['xLength'], positive: true) ||
            !finite(value['yLength'], positive: true)) { return false; }
      default: { return false; }
    }
  }
  return true;
}

class _GeometryPainter extends CustomPainter {
  const _GeometryPainter(this.objects, this.color, this.width, this.height);
  final List<Map<String, dynamic>> objects;
  final Color color;
  final double width;
  final double height;
  double n(Map obj, String key) => (obj[key] as num).toDouble();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / width, size.height / height);
    final paint = Paint()..color = color..strokeWidth = 2..style = PaintingStyle.stroke;
    for (final o in objects) {
      final type = o['type'];
      if (type == 'point') {
        canvas.drawCircle(Offset(n(o,'x'), n(o,'y')), 3.5, Paint()..color = color);
      } else if (type == 'circle') {
        canvas.drawCircle(Offset(n(o,'cx'), n(o,'cy')), n(o,'r'), paint);
      } else if (type == 'polygon') {
        final pts = (o['points'] as List).cast<Map>();
        final path = Path()..moveTo(n(pts.first,'x'), n(pts.first,'y'));
        for (final p in pts.skip(1)) { path.lineTo(n(p,'x'), n(p,'y')); }
        canvas.drawPath(path..close(), paint);
      } else if (type == 'angle') {
        final start = n(o,'startDegrees') * math.pi / 180;
        final sweep = (n(o,'endDegrees') - n(o,'startDegrees')) * math.pi / 180;
        final r = n(o,'radius');
        canvas.drawArc(Rect.fromCircle(center: Offset(n(o,'cx'), n(o,'cy')), radius: r),
            -start, -sweep, false, paint);
      } else if (type == 'axes') {
        final x = n(o,'originX'), y = n(o,'originY');
        canvas.drawLine(Offset(x-n(o,'xLength'),y), Offset(x+n(o,'xLength'),y),paint);
        canvas.drawLine(Offset(x,y+n(o,'yLength')), Offset(x,y-n(o,'yLength')),paint);
      } else {
        final from = Offset(n(o,'x1'), n(o,'y1'));
        final to = Offset(n(o,'x2'), n(o,'y2'));
        canvas.drawLine(from,to,paint);
        if (type == 'vector' || type == 'ray' || type == 'line') {
          final theta = math.atan2(to.dy-from.dy, to.dx-from.dx);
          final p1 = Offset(to.dx-10*math.cos(theta-.5),to.dy-10*math.sin(theta-.5));
          final p2 = Offset(to.dx-10*math.cos(theta+.5),to.dy-10*math.sin(theta+.5));
          canvas.drawLine(to,p1,paint); canvas.drawLine(to,p2,paint);
        }
      }
      if (o['label'] is String) {
        final x = type == 'point' ? n(o,'x') : type == 'circle' || type == 'angle'
            ? n(o,'cx') : type == 'polygon' ? n((o['points'] as List).first as Map,'x')
            : type == 'axes' ? n(o,'originX') : n(o,'x1');
        final y = type == 'point' ? n(o,'y') : type == 'circle' || type == 'angle'
            ? n(o,'cy') : type == 'polygon' ? n((o['points'] as List).first as Map,'y')
            : type == 'axes' ? n(o,'originY') : n(o,'y1');
        final tp = TextPainter(
          text: TextSpan(text: o['label'] as String, style: TextStyle(color: color, fontSize: 14)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x+7,y-22));
      }
    }
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant _GeometryPainter old) =>
      old.objects != objects || old.color != color || old.width != width || old.height != height;
}
