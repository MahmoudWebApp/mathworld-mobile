import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/models/problem_search.dart';

void main() {
  test('equal search parameters have equal hash codes', () {
    const first = ProblemSearchParams(
      query: 'algebra',
      categoryId: 2,
      stageId: 3,
      page: 1,
    );
    const second = ProblemSearchParams(
      query: 'algebra',
      categoryId: 2,
      stageId: 3,
      page: 1,
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('hide-solved uses a distinct provider key for pagination', () {
    const all = ProblemSearchParams(stageId: 1, page: 1);
    const unsolved = ProblemSearchParams(
      stageId: 1, page: 1, hideSolved: true,
    );
    expect(all, isNot(unsolved));
    expect(unsolved.hideSolved, isTrue);
  });
}
