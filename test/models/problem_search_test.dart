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
}
