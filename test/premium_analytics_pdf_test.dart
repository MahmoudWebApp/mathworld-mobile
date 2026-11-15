import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:mathworld_mobile/services/premium_analytics_pdf_service.dart';
import 'package:mathworld_mobile/services/premium_analytics_service.dart';

void main() {
  final service = PremiumAnalyticsPdfService(
    // Test English PDF structure without contacting the font CDN.
    fontLoader: () async => [pw.Font.helvetica(), pw.Font.helveticaBold()],
  );

  PremiumAnalyticsReport report({int rows = 0}) => PremiumAnalyticsReport(
        generatedAtUtc: DateTime.utc(2026, 11, 15),
        attemptedProblems: rows,
        solvedProblems: rows,
        attempts: rows,
        correctAttempts: rows,
        incorrectAttempts: 0,
        firstTryCorrect: rows,
        awardedPoints: rows * 10,
        timeSpentSeconds: rows * 20,
        categories: List.generate(rows, (index) => PremiumCategoryStatistics(
          stageId: 1,
          categoryId: index + 1,
          stageNameAr: 'Stage',
          stageNameEn: 'Stage 1',
          categoryNameAr: 'Topic',
          categoryNameEn: 'Topic ${index + 1}',
          attemptedProblems: 1,
          solvedProblems: 1,
          errorNotebookProblems: 0,
          attempts: 1,
          correctAttempts: 1,
          incorrectAttempts: 0,
          firstTryCorrect: 1,
          awardedPoints: 10,
          timeSpentSeconds: 20,
        )),
      );

  void expectPdf(Uint8List bytes) {
    expect(bytes.length, greaterThan(900));
    expect(bytes.take(5).toList(), [37, 80, 68, 70, 45]); // %PDF-
  }

  test('exports a genuine PDF for a Premium report with no attempts', () async {
    expectPdf(await service.export(report(), arabic: false));
  });

  test('supports a larger paginated category report', () async {
    final bytes = await service.export(report(rows: 38), arabic: false);
    expectPdf(bytes);
    expect(bytes.length, greaterThan(2500));
  });
}
