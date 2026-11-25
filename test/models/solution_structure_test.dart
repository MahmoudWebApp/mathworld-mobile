import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/problem.dart';

void main() {
  test('structured solution accepts both server casing conventions', () {
    for (final lower in [false, true]) {
      String key(String value) => lower
          ? value[0].toLowerCase() + value.substring(1)
          : value;
      final parsed = SolutionStructure.parse({
        key('Idea'): 'Multiply',
        key('FormulaLatex'): 'a b',
        key('Steps'): ['First', 'Second'],
        key('Result'): '12',
      });
      expect(parsed?.idea, 'Multiply');
      expect(parsed?.formulaLatex, 'a b');
      expect(parsed?.steps, ['First', 'Second']);
      expect(parsed?.result, '12');
    }
  });

  test('missing or malformed steps do not crash the detail screen', () {
    expect(SolutionStructure.parse(null), isNull);
    expect(SolutionStructure.parse({'Steps': 'invalid'})?.steps, isEmpty);
    expect(SolutionStructure.parse({'Steps': ['valid', null, 3]})?.steps,
        ['valid']);
  });
}
