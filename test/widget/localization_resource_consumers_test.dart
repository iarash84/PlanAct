import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/settings/presentation/settings_page.dart';
import 'package:planact/l10n/generated/app_localizations_fa.dart';

class _AlternateCopy extends AppLocalizationsFa {
  @override
  String get settingsAppearance => 'Alternate appearance';
  @override
  String get settingsThemeLight => 'Alternate light';
  @override
  String get settingsAboutApp => 'Alternate about';
}

class _AlternateDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AlternateDelegate();
  @override
  bool isSupported(Locale locale) => locale.languageCode == 'fa';
  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(_AlternateCopy());
  @override
  bool shouldReload(_AlternateDelegate old) => false;
}

void main() {
  testWidgets(
    'Settings consumes route resources rather than Persian defaults',
    (tester) async {
      tester.view.physicalSize = const Size(400, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fa'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            _AlternateDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: SettingsPage(
            themeMode: ThemeMode.system,
            onThemeModeChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Alternate appearance'), findsOneWidget);
      expect(find.text('Alternate light'), findsOneWidget);
      expect(find.text('Alternate about'), findsOneWidget);
      expect(find.text('حالت نمایش'), findsNothing);
      final context = tester.element(find.byType(SettingsPage));
      expect(Directionality.of(context), TextDirection.rtl);
      expect(planActL10n(context), isA<_AlternateCopy>());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('isolated widgets retain Persian when app delegate is absent', (
    tester,
  ) async {
    late AppLocalizations copy;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            copy = planActL10n(context);
            return Text(copy.commonSave);
          },
        ),
      ),
    );
    expect(copy.localeName, 'fa');
    expect(find.text('ذخیره'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
