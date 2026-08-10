import 'package:flutter/material.dart';
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
}
