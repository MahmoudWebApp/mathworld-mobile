import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/widgets/rich_math_text.dart';

void main() {
  testWidgets('renders mixed text without displaying dollar delimiters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RichMathText(text: r'Find $f(4)$ when $f(x)=2x+3$.'),
        ),
      ),
    );

    expect(find.textContaining(r'$f(4)$'), findsNothing);
    expect(find.byType(RichMathText), findsOneWidget);
  });

  testWidgets('keeps a plain Arabic answer as normal readable text', (
    tester,
  ) async {
    const answer = 'لا توجد إجابة صحيحة';

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: RichMathText(text: answer)),
      ),
    );

    expect(find.text(answer, findRichText: true), findsOneWidget);
  });

  testWidgets('unwraps prose-only Arabic stored inside math delimiters', (
    tester,
  ) async {
    const answer = 'لا توجد إجابة صحيحة';

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: RichMathText(text: r'$لا توجد إجابة صحيحة$'),
        ),
      ),
    );

    expect(find.text(answer, findRichText: true), findsOneWidget);
  });

  testWidgets('renders Arabic inside a LaTeX text command as shaped prose', (
    tester,
  ) async {
    const answer = 'لا توجد إجابة صحيحة';

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar'), Locale('en')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: RichMathText(text: r'$\text{لا توجد إجابة صحيحة}$'),
        ),
      ),
    );

    expect(find.text(answer), findsOneWidget);
    expect(find.textContaining(r'\text'), findsNothing);
  });
  testWidgets('renders the real Arabic multiplication question using \\(\\) TeX',
      (tester) async {
    const question = r'بسّط \(2^{3}\times2^2\) على صورة قوة للعدد 2.';
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('ar'),
      home: Scaffold(body: RichMathText(text: question, isArabic: true)),
    ));

    // A LaTeX widget must be present: no raw \times command in the question.
    expect(find.byType(Math), findsOneWidget);
    expect(find.textContaining(r'\times'), findsNothing);
    expect(find.textContaining(r'\('), findsNothing);
    expect(find.textContaining('بسّط', findRichText: true), findsWidgets);
  });

  testWidgets('renders block TeX delimiters in Arabic worked solutions',
      (tester) async {
    const solution = r'نجمّع الأسس: \[2^{3}\times 2^{2}=2^{5}\] وهذا هو الناتج.';
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('ar'),
      home: Scaffold(body: RichMathText(text: solution, isArabic: true)),
    ));

    expect(find.byType(Math), findsOneWidget);
    expect(find.textContaining(r'\['), findsNothing);
    expect(find.textContaining(r'\times'), findsNothing);
  });

  testWidgets('renders real API question when TeX was double-escaped',
      (tester) async {
    const question = r'بسّط \\(2^{3}\\times2^2\\) على صورة قوة للعدد 2.';
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('ar'),
      home: Scaffold(body: RichMathText(text: question, isArabic: true)),
    ));

    expect(find.byType(Math), findsOneWidget);
    expect(find.textContaining(r'\times'), findsNothing);
    expect(find.textContaining(r'\\('), findsNothing);
    expect(find.textContaining('بسّط', findRichText: true), findsWidgets);
  });

  testWidgets('renders Arabic solution with double-escaped display math',
      (tester) async {
    const solution = r'نجمع الأسس: \\[2^{3}\\times2^2=2^5\\] إذن الناتج.';
    await tester.pumpWidget(const MaterialApp(
      locale: Locale('ar'),
      home: Scaffold(body: RichMathText(text: solution, isArabic: true)),
    ));

    expect(find.byType(Math), findsOneWidget);
    expect(find.textContaining(r'\times'), findsNothing);
    expect(find.textContaining(r'\\['), findsNothing);
  });

  testWidgets('keeps already supported dollar math and renders TeX answers',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(children: [
          RichMathText(text: r'$2^{5}$'),
          RichMathText(text: r'\(2^{8}\)'),
        ]),
      ),
    ));

    expect(find.byType(Math), findsNWidgets(2));
    expect(find.textContaining(r'\('), findsNothing);
  });

  testWidgets('renders relation symbols and radicals in both directions', (tester) async {
    const expressions = [r'a\neq0',r'x\leq2',r'x\geq0',r'x\approx1',r'x\in A',r'x\notin A',r'\frac{1}{2}',r'\sqrt{x}'];
    for (final direction in [TextDirection.ltr,TextDirection.rtl]) {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body:Directionality(textDirection:direction,child:Column(children: [
        for(final expression in expressions) RichMathText(text:'\$'+expression+'\$',isArabic:direction==TextDirection.rtl),
      ])))));
      expect(find.byType(Math),findsNWidgets(expressions.length));
      for(final expression in expressions) {
        expect(find.text(expression),findsNothing,reason:'Raw TeX fallback: '+expression);
      }
      expect(tester.takeException(),isNull);
    }
  });

  testWidgets('renders unwrapped relation commands and aligns Arabic block prose to the start', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [
      RichMathText(text: r'x\approx 1'),
      RichMathText(text: r'x\in A'),
      RichMathText(text: r'x\notin A'),
      RichMathText(text: r'نحسب \[x=2\] ثم نتابع',isArabic:true),
    ]))));
    expect(find.byType(Math), findsNWidgets(4));
    final columns = tester.widgetList<Column>(find.descendant(
      of:find.byType(RichMathText),matching:find.byType(Column)));
    expect(columns.single.crossAxisAlignment,CrossAxisAlignment.start);
    expect(tester.takeException(),isNull);
  });


  testWidgets('keeps signed numeric answers left-to-right in Arabic', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Column(children: [
      RichMathText(text: '-5', isArabic: true, inline: true),
      RichMathText(text: '−12.5', isArabic: true, inline: true),
    ]))));
    final matches=find.byType(Math);
    expect(matches,findsNWidgets(2));
    for(final element in matches.evaluate()){
      expect(Directionality.of(element),TextDirection.ltr);
    }
    expect(tester.takeException(),isNull);
  });

  testWidgets('matrix TeX renders without showing its source', (tester) async {
    await tester.pumpWidget(const MaterialApp(home:Scaffold(body:
      RichMathText(text:r'نحسب المحدد: \[\begin{vmatrix}2&3\\1&4\end{vmatrix}\]',isArabic:true),
    )));
    expect(find.byType(Math),findsOneWidget);
    expect(find.textContaining(r'\begin'),findsNothing);
    expect(tester.takeException(),isNull);
  });

  testWidgets('renders bare determinant with Arabic prose and matrix row separators', (tester) async {
    await tester.pumpWidget(const MaterialApp(home:Scaffold(body:
      RichMathText(text:r'''نحسب المحدد:
\det\begin{pmatrix}2&3\\
1&4\end{pmatrix}
إذن الناتج 5.''',isArabic:true),
    )));
    expect(find.byType(Math),findsOneWidget);
    expect(find.textContaining(r'\begin'),findsNothing);
    expect(find.textContaining('نحسب المحدد',findRichText:true),findsWidgets);
    expect(tester.takeException(),isNull);
  });
}
