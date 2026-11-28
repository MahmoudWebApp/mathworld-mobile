import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart' show rootBundle;
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
    // Reuse the approved MathSuper identity that ships inside the app.
    // Exports remain usable offline even if an older app package omits it.
    pw.ImageProvider? brandMark;
    try {
      final asset = await rootBundle.load('assets/branding/mathworld-mark.png');
      brandMark = pw.MemoryImage(asset.buffer.asUint8List());
    } catch (_) {
      // The MathSuper wordmark still identifies the report.
    }
    final purple = PdfColor.fromInt(0xFF6D28D9);
    final dark = PdfColor.fromInt(0xFF1F2937);
    final muted = PdfColor.fromInt(0xFF475569);
    final light = PdfColor.fromInt(0xFFF7F3FF);
    final pink = PdfColor.fromInt(0xFFDC41A6);
    final track = PdfColor.fromInt(0xFFEDE7F5);
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

    // A compact data-backed chart; use no invented or cached values.
    pw.Widget categoryBar(PremiumCategoryStatistics c) {
      final proportion = c.attemptedProblems <= 0
          ? 0.0
          : (c.solvedProblems / c.attemptedProblems).clamp(0.0, 1.0);
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 5),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(child: pw.Text(
                  arabic ? c.categoryNameAr : c.categoryNameEn,
                  style: pw.TextStyle(fontSize: 10, color: dark))),
                pw.SizedBox(width: 8),
                pw.Text('${(proportion * 100).round()}%',
                  textDirection: pw.TextDirection.ltr,
                  style: pw.TextStyle(fontSize: 9, color: purple,
                    fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              height: 8,
              decoration: pw.BoxDecoration(color: track,
                borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Row(children: [
                if (proportion > 0)
                  pw.Expanded(flex: (proportion * 1000).round(),
                    child: pw.Container(decoration: pw.BoxDecoration(
                      color: purple,
                      borderRadius: pw.BorderRadius.circular(4)))),
                if (proportion < 1)
                  pw.Expanded(flex: ((1 - proportion) * 1000).round(),
                    child: pw.SizedBox()),
              ]),
            ),
          ],
        ),
      );
    }

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
        ],
      ),
    );

    final document = pw.Document(
      title: arabic ? 'MathSuper - تقرير الطالب' : 'MathSuper - Student report',
      author: 'MathSuper', compress: true,
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
            pw.Row(
              children: [
                if (brandMark != null) ...[
                  pw.Container(width: 30, height: 30,
                    child: pw.Image(brandMark, fit: pw.BoxFit.contain)),
                  pw.SizedBox(width: 9),
                ],
                pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MathSuper', textDirection: pw.TextDirection.ltr,
                      style: pw.TextStyle(fontSize: 15, color: purple,
                        fontWeight: pw.FontWeight.bold)),
                    pw.Text(arabic ? 'منصة الرياضيات التفاعلية' : 'Interactive mathematics learning',
                      style: pw.TextStyle(fontSize: 8, color: pink)),
                  ]),
              ],
            ),
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
        if (report.categories.isNotEmpty) ...[
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(13),
            decoration: pw.BoxDecoration(
              color: light, borderRadius: pw.BorderRadius.circular(9)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(arabic ? 'مخطط إنجاز الفئات' : 'Topic completion chart',
                  style: pw.TextStyle(fontSize: 13, color: dark,
                    fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                ...report.categories.take(10).map(categoryBar),
                if (report.categories.length > 10)
                  pw.Text(arabic ? 'أول 10 فئات، والتفاصيل الكاملة أدناه.'
                      : 'First 10 topics; full details below.',
                    style: pw.TextStyle(fontSize: 8, color: muted)),
              ],
            ),
          ),
        ],
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
