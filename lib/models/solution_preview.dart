/// Solution shown only when a Premium learner explicitly requests a preview.
class SolutionPreview {
  final int problemId;
  final int? correctOptionId;
  final String detailedSolution;
  final String? youtubeSolutionUrl;

  const SolutionPreview({
    required this.problemId,
    this.correctOptionId,
    required this.detailedSolution,
    this.youtubeSolutionUrl,
  });

  factory SolutionPreview.fromJson(Map<String, dynamic> json) {
    final rawCorrect = json['CorrectOptionId'] ?? json['correctOptionId'];
    return SolutionPreview(
      problemId: _int(json['ProblemId'] ?? json['problemId']) ?? 0,
      correctOptionId: _int(rawCorrect),
      detailedSolution: (json['DetailedSolution'] ?? json['detailedSolution'] ?? '')
          .toString(),
      youtubeSolutionUrl:
          (json['YoutubeSolutionUrl'] ?? json['youtubeSolutionUrl'])?.toString(),
    );
  }
}

int? _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
