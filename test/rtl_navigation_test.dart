import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mathworld_mobile/utils/layout_utils.dart';
import 'package:mathworld_mobile/widgets/premium_button.dart';

void main() {
  for (final data in [
    (locale: const Locale('ar'), rtl: true),
    (locale: const Locale('en'), rtl: false),
  ]) {
    testWidgets('semantic arrows and pagination follow ${data.locale.languageCode}',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        locale: data.locale,
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(children: [
              LayoutUtils.backIcon(context),
              LayoutUtils.forwardIcon(context),
              LayoutUtils.previousPageIcon(context),
              LayoutUtils.nextPageIcon(context),
              PremiumButton(
                label: 'Next',
                leadingIcon: Icons.arrow_forward_rounded,
                onPressed: () {},
              ),
            ]),
          ),
        ),
      ));

      final icons = tester.widgetList<Icon>(find.byType(Icon)).toList();
      expect(icons[0].icon,
          data.rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded);
      expect(icons[1].icon,
          data.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded);
      expect(icons[2].icon,
          data.rtl ? Icons.chevron_right_rounded : Icons.chevron_left_rounded);
      expect(icons[3].icon,
          data.rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded);
      expect(icons[4].icon,
          data.rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded);
      for (final icon in icons) {
        expect(icon.textDirection, TextDirection.ltr);
      }
    });
  }
}
