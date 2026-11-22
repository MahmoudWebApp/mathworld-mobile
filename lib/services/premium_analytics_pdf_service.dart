import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'premium_analytics_service.dart';

/// Generates a true multipage A4 report from an authenticated Premium API
/// response. The first font load may require a network connection; the font
/// is embedded in the PDF (no broken Arabic fallback squares).
class PremiumAnalyticsPdfService {
  const PremiumAnalyticsPdfService({this.fontLoader});

  /// An explicit loader keeps PDF generation testable offline. Normal app
  /// exports always use embedded Arabic-capable Noto fonts.
  final Future<List<pw.Font>> Function()? fontLoader;

  Future<Uint8List> export(PremiumAnalyticsReport report,
      {required bool arabic}) async {
    final fonts = await (fontLoader?.call() ?? Future.wait([
      PdfGoogleFonts.notoNaskhArabicRegular(),
      PdfGoogleFonts.notoNaskhArabicBold(),
    ]));
    if (fonts.length != 2) {
      throw const FormatException('Two PDF font weights are required');
    }
    pw.MemoryImage? brandMark;
    try {
      final logo = await rootBundle.load('assets/branding/mathworld-mark.png');
      brandMark = pw.MemoryImage(logo.buffer.asUint8List());
    } catch (_) {
      // Printable reports remain available if an asset is unavailable.
    }
    final purple = PdfColor.fromInt(0xFF6D28D9);
    final dark = PdfColor.fromInt(0xFF1F2937);
    final muted = PdfColor.fromInt(0xFF475569);
    final light = PdfColor.fromInt(0xFFF7F3FF);
    final date = report.generatedAtUtc.toUtc().toIso8601String().split('T').first;
    final success = report.attempts == 0
        ? 0.0 : 100 * report.correctAttempts / report.attempts;

    pw.Widget metric(String name, String value) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: light, borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(child: pw.Text(name,
              style: pw.TextStyle(fontSize: 10, color: muted))),
          pw.SizedBox(width: 10),
          pw.Text(value, textDirection: pw.TextDirection.ltr,
            style: pw.TextStyle(color: purple, fontSize: 14,
                fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );

    pw.Widget category(PremiumCategoryStatistics c) => pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 7),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFE5E7EB)),
        borderRadius: pw.BorderRadius.circular(8)),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(arabic ? c.categoryNameAr : c.categoryNameEn,
            style: pw.TextStyle(fontSize: 12, color: dark,
                fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 3),
          pw.Text(arabic ? c.stageNameAr : c.stageNameEn,
            style: pw.TextStyle(color: muted, fontSize: 9)),
          pw.SizedBox(height: 4),
          pw.Text(
            (arabic ? 'محلولة: ' : 'Solved: ') +
                c.solvedProblems.toString() + ' / ' +
                c.attemptedProblems.toString() +
                (arabic ? '    المحاولات: ' : '    Attempts: ') +
                c.attempts.toString() +
                (arabic ? '    النقاط: ' : '    Points: ') +
                c.awardedPoints.toString(),
            style: pw.TextStyle(color: dark, fontSize: 9)),
          pw.SizedBox(height: 8),
          pw.Row(children: [
            pw.Container(
              width: c.attemptedProblems == 0 ? 0 :
                260.0 * c.solvedProblems / c.attemptedProblems,
              height: 8,
              decoration: pw.BoxDecoration(
                color: purple, borderRadius: pw.BorderRadius.circular(4)),
            ),
            pw.Container(
              width: c.attemptedProblems == 0 ? 260.0 :
                260.0 * (c.attemptedProblems - c.solvedProblems) /
                  c.attemptedProblems,
              height: 8,
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFE9DEFA),
                borderRadius: pw.BorderRadius.circular(4)),
            ),
            pw.SizedBox(width: 10),
            pw.Text(c.attemptedProblems == 0 ? '0%' :
              '${(100 * c.solvedProblems / c.attemptedProblems).toStringAsFixed(0)}%',
              style: pw.TextStyle(color: purple, fontSize: 9,
                  fontWeight: pw.FontWeight.bold)),
          ]),
        ],
      ),
    );

    final document = pw.Document(
      title: arabic ? 'MathWorld - تقرير الطالب' : 'MathWorld - Student report',
      author: 'MathWorld', compress: true,
    );

    document.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      maxPages: 250,
      margin: const pw.EdgeInsets.all(32),
      textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      theme: pw.ThemeData.withFont(base: fonts[0], bold: fonts[1]),
      header: (_) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 12),
        decoration: pw.BoxDecoration(border: pw.Border(
          bottom: pw.BorderSide(color: purple, width: 1.5))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Row(children: [
              if (brandMark != null) ...[
                pw.Image(brandMark, width: 28, height: 28),
                pw.SizedBox(width: 9),
              ],
              pw.Text('MathWorld', textDirection: pw.TextDirection.ltr,
                style: pw.TextStyle(fontSize: 16, color: purple,
                    fontWeight: pw.FontWeight.bold)),
            ]),
            pw.Text(date, textDirection: pw.TextDirection.ltr,
              style: pw.TextStyle(fontSize: 9, color: muted)),
          ],
        )),
      footer: (context) => pw.Text(
        context.pageNumber.toString() + ' / ' + context.pagesCount.toString(),
        textDirection: pw.TextDirection.ltr,
        style: pw.TextStyle(fontSize: 9, color: muted)),
      build: (_) => [
        pw.SizedBox(height: 12),
        pw.Text(arabic ? 'تقرير التقدم الشخصي' : 'Personal progress report',
          style: pw.TextStyle(fontSize: 22, color: dark,
              fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Text(
          arabic ? 'الإحصائيات مبنية على محاولات الحل المحفوظة في حسابك.'
              : 'Statistics are based on your saved problem-solving attempts.',
          style: pw.TextStyle(fontSize: 10, color: muted)),
        pw.SizedBox(height: 18),
        metric(arabic ? 'المسائل المجربة' : 'Attempted problems',
            report.attemptedProblems.toString()),
        metric(arabic ? 'المسائل المحلولة' : 'Solved problems',
            report.solvedProblems.toString()),
        metric(arabic ? 'جميع المحاولات' : 'All attempts',
            report.attempts.toString()),
        metric(arabic ? 'دقة المحاولات' : 'Attempt accuracy',
            success.toStringAsFixed(1) + '%'),
        metric(arabic ? 'النقاط المكتسبة' : 'Awarded points',
            report.awardedPoints.toString()),
        pw.SizedBox(height: 14),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: light, borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(arabic ? 'مؤشر النجاح الإجمالي' : 'Overall success rate',
                style: pw.TextStyle(fontSize: 11,
                  fontWeight: pw.FontWeight.bold, color: dark)),
              pw.SizedBox(height: 7),
              pw.Row(children: [
                pw.Container(width: 350.0 * (success / 100).clamp(0.0, 1.0).toDouble(),
                  height: 12, color: purple),
                pw.Container(width: 350.0 * (1 - success / 100).clamp(0.0, 1.0).toDouble(),
                  height: 12, color: PdfColor.fromInt(0xFFE9DEFA)),
                pw.SizedBox(width: 8),
                pw.Text('${success.toStringAsFixed(1)}%',
                  style: pw.TextStyle(color: purple, fontSize: 9)),
              ]),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(arabic ? 'التقدم حسب الفئة' : 'Progress by category',
          style: pw.TextStyle(fontSize: 16, color: dark,
              fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (report.categories.isEmpty)
          pw.Text(arabic ? 'لا توجد محاولات محفوظة بعد.'
                  : 'No saved attempts yet.',
              style: pw.TextStyle(fontSize: 11, color: muted)),
        ...report.categories.map(category),
      ],
    ));
    final bytes = await document.save();
    if (bytes.length < 5 || bytes[0] != 0x25 || bytes[1] != 0x50 ||
        bytes[2] != 0x44 || bytes[3] != 0x46 || bytes[4] != 0x2d) {
      throw const FormatException('Invalid generated PDF');
    }
    return bytes;
  }
}
