import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/geometry_diagram.dart';

void main() {
  final triangle = <String, dynamic>{
    'schemaVersion': 1,
    'viewport': <String, dynamic>{'width': 360, 'height': 260},
    'altTextAr': 'مثلث قائم الزاوية',
    'altTextEn': 'Right triangle',
    'objects': <Map<String, dynamic>>[
      {
        'id': 'triangle',
        'type': 'polygon',
        'points': <Map<String, dynamic>>[
          {'x': 65, 'y': 205},
          {'x': 305, 'y': 205},
          {'x': 65, 'y': 45},
        ],
      },
      {'id': 'a', 'type': 'point', 'x': 65, 'y': 205, 'label': 'A'},
      {'id': 'b', 'type': 'point', 'x': 305, 'y': 205, 'label': 'B'},
      {'id': 'c', 'type': 'point', 'x': 65, 'y': 45, 'label': 'C'},
    ],
  };

  test('accepts shared bilingual right-triangle scene', () {
    expect(isValidGeometryScene(triangle), isTrue);
  });

  test('rejects unknown primitive types', () {
    final scene = Map<String, dynamic>.from(triangle);
    scene['objects'] = <Map<String, dynamic>>[
      {'id': 'unsafe', 'type': 'foreignObject', 'html': '<script />'},
    ];
    expect(isValidGeometryScene(scene), isFalse);
  });

  test('rejects duplicate object identifiers', () {
    final scene = Map<String, dynamic>.from(triangle);
    scene['objects'] = <Map<String, dynamic>>[
      {'id': 'a', 'type': 'point', 'x': 0, 'y': 0},
      {'id': 'a', 'type': 'point', 'x': 1, 'y': 1},
    ];
    expect(isValidGeometryScene(scene), isFalse);
  });

  test('matches web coordinate bounds for geometry objects', () {
    final scene = Map<String, dynamic>.from(triangle);
    scene['objects'] = <Map<String, dynamic>>[
      {'id': 'outside', 'type': 'point', 'x': 10001, 'y': 0},
    ];
    expect(isValidGeometryScene(scene), isFalse);
  });

  test('accepts signed arcs but rejects empty or full-turn arcs', () {
    final scene = Map<String, dynamic>.from(triangle);
    scene['objects'] = <Map<String, dynamic>>[
      {'id': 'cw', 'type': 'angle', 'cx': 100, 'cy': 100,
        'radius': 30, 'startDegrees': 90, 'endDegrees': 0},
    ];
    expect(isValidGeometryScene(scene), isTrue);
    scene['objects'] = <Map<String, dynamic>>[
      {'id': 'empty', 'type': 'angle', 'cx': 100, 'cy': 100,
        'radius': 30, 'startDegrees': 90, 'endDegrees': 90},
    ];
    expect(isValidGeometryScene(scene), isFalse);
    scene['objects'] = <Map<String, dynamic>>[
      {'id': 'full', 'type': 'angle', 'cx': 100, 'cy': 100,
        'radius': 30, 'startDegrees': 0, 'endDegrees': 360},
    ];
    expect(isValidGeometryScene(scene), isFalse);
  });

  test('rejects zero or nonfinite viewport dimensions', () {
    final scene = Map<String, dynamic>.from(triangle);
    scene['viewport'] = <String, dynamic>{'width': 0, 'height': 260};
    expect(isValidGeometryScene(scene), isFalse);
    scene['viewport'] = <String, dynamic>{'width': double.infinity, 'height': 260};
    expect(isValidGeometryScene(scene), isFalse);
  });
}
