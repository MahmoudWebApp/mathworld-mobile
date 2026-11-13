import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/utils/layout_utils.dart';

void main() {
  testWidgets('uses left chevron for forward navigation in Arabic', (
    tester,
  ) async {
    IconData? forwardIcon;
    IconData? backIcon;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            forwardIcon = LayoutUtils.forwardChevron(context);
            backIcon = LayoutUtils.backChevron(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(forwardIcon, Icons.chevron_left_rounded);
    expect(backIcon, Icons.chevron_right_rounded);
  });

  testWidgets('uses right chevron for forward navigation in English', (
    tester,
  ) async {
    IconData? forwardIcon;
    IconData? backIcon;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            forwardIcon = LayoutUtils.forwardChevron(context);
            backIcon = LayoutUtils.backChevron(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(forwardIcon, Icons.chevron_right_rounded);
    expect(backIcon, Icons.chevron_left_rounded);
  });

  testWidgets('locks the explicit Arabic forward icon to LTR rendering', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: LayoutUtils.forwardIcon(context),
          ),
        ),
      ),
    );

    final icon = tester.widget<Icon>(find.byType(Icon));
    expect(icon.icon, Icons.chevron_left_rounded);
    expect(icon.textDirection, TextDirection.ltr);
  });
  testWidgets('Arabic action arrows go forward left and back right', (
    tester,
  ) async {
    IconData? forward;
    IconData? back;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(builder: (context) {
        forward = LayoutUtils.forwardArrow(context);
        back = LayoutUtils.backArrow(context);
        return const SizedBox.shrink();
      }),
    ));
    expect(forward, Icons.arrow_back_rounded);
    expect(back, Icons.arrow_forward_rounded);
  });

  testWidgets('English action arrows go forward right and back left', (
    tester,
  ) async {
    IconData? forward;
    IconData? back;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(builder: (context) {
        forward = LayoutUtils.forwardArrow(context);
        back = LayoutUtils.backArrow(context);
        return const SizedBox.shrink();
      }),
    ));
    expect(forward, Icons.arrow_forward_rounded);
    expect(back, Icons.arrow_back_rounded);
  });

}
