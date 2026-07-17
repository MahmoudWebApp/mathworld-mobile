import '../config/constants.dart';
import 'problem.dart';

/// Defines problem search filters and pagination values.
class ProblemSearchParams {
  final String? query;
  final int? categoryId;
  final int? stageId;
  final int page;
  final int pageSize;

  const ProblemSearchParams({
    this.query,
    this.categoryId,
    this.stageId,
    this.page = 1,
    this.pageSize = AppConstants.pageSize,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProblemSearchParams &&
            other.query == query &&
            other.categoryId == categoryId &&
            other.stageId == stageId &&
            other.page == page &&
            other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(
        query,
        categoryId,
        stageId,
        page,
        pageSize,
      );
}

/// Represents a single page of problem search results.
class ProblemSearchResult {
  final List<ProblemPreview> problems;
  final int total;
  final int page;
  final int totalPages;

  const ProblemSearchResult({
    required this.problems,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  bool get hasMorePages => page < totalPages;
  bool get isEmpty => problems.isEmpty;
  bool get isNotEmpty => problems.isNotEmpty;
}
