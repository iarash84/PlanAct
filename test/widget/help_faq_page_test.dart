import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/help/presentation/help_faq_page.dart';

void main() {
  Widget app() => MaterialApp(
    locale: const Locale('fa'),
    supportedLocales: const [Locale('fa')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: PlanActTheme.light(),
    home: const PlanActApp(),
  );

  testWidgets('More page includes help FAQ and opens a readable RTL route', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('بیشتر').last);
    await tester.pumpAndSettle();

    final helpTitle = find.text('راهنما و سوالات متداول');
    expect(helpTitle, findsOneWidget);
    await tester.tap(helpTitle.first);
    await tester.pumpAndSettle();

    expect(find.byType(HelpFaqPage), findsOneWidget);
    expect(find.byType(ExpansionTile), findsWidgets);
    final tiles = tester.widgetList<ExpansionTile>(find.byType(ExpansionTile));
    for (final tile in tiles) {
      expect(tile.initiallyExpanded, isFalse);
    }
    final firstQuestion = find.text('پلن‌اکت برای چه کاری است؟');
    expect(firstQuestion, findsOneWidget);
    expect(Directionality.of(tester.element(firstQuestion)), TextDirection.rtl);
    expect(tester.takeException(), isNull);
  });
}
