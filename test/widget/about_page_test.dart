import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/settings/presentation/about_page.dart';

void main() {
  void metadata() => PackageInfo.setMockInitialValues(
    appName: 'Internal native name',
    packageName: 'test.planact',
    version: '2.3.4',
    buildNumber: '57',
    buildSignature: '',
  );

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Widget app({
    bool dark = false,
    double scale = 1,
    Widget home = const AboutPage(),
  }) => MaterialApp(
    locale: const Locale('fa'),
    supportedLocales: const [Locale('fa')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: home,
  );

  testWidgets('metadata loading, failure and retry do not hide content', (
    tester,
  ) async {
    final pending = Completer<PackageInfo>();
    var calls = 0;
    Future<PackageInfo> load() async {
      calls++;
      if (calls == 1) return pending.future;
      return PackageInfo(
        appName: 'Native',
        packageName: 'test',
        version: '9.8.7',
        buildNumber: '42',
      );
    }

    await tester.pumpWidget(app(home: AboutPage(loadPackageInfo: load)));
    await tester.pump();
    await reveal(tester, find.text('در حال خواندن اطلاعات نسخه…'));
    pending.completeError(StateError('unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('خواندن اطلاعات نسخه انجام نشد.'), findsOneWidget);
    await tester.tap(find.text('تلاش دوباره'));
    await tester.pumpAndSettle();
    expect(find.text('نسخه: ۹.۸.۷\nشمارهٔ ساخت: ۴۲'), findsOneWidget);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings opens About and back preserves Settings', (
    tester,
  ) async {
    metadata();
    await tester.pumpWidget(const PlanActApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('بیشتر').last);
    await tester.pumpAndSettle();
    await reveal(tester, find.text('تنظیمات'));
    await tester.tap(find.text('تنظیمات'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('درباره پلن‌اکت'));
    await tester.tap(find.text('درباره پلن‌اکت'));
    await tester.pumpAndSettle();
    expect(find.byType(AboutPage), findsOneWidget);
    expect(find.text('پلن‌اکت'), findsOneWidget);
    expect(find.text('Internal native name'), findsNothing);
    expect(
      Directionality.of(tester.element(find.text('پلن‌اکت'))),
      TextDirection.rtl,
    );
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('تنظیمات'), findsOneWidget);
    expect(find.byType(AboutPage), findsNothing);
  });

  for (final dark in [false, true]) {
    testWidgets(
      '320dp 2x text scrolls to metadata and full license, dark=$dark',
      (tester) async {
        metadata();
        tester.view.physicalSize = const Size(320, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(dark: dark, scale: 2));
        await tester.pumpAndSettle();
        await reveal(tester, find.text('نسخه: ۲.۳.۴\nشمارهٔ ساخت: ۵۷'));
        await reveal(tester, find.text('مشاهدهٔ مجوزها'));
        expect(tester.takeException(), isNull);
        if (dark) return;
        await tester.tap(find.text('مشاهدهٔ مجوزها'));
        await tester.pumpAndSettle();
        expect(find.byType(LicensePage), findsOneWidget);
        await reveal(tester, find.text('PlanAct'));
        await tester.tap(find.text('PlanAct'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Copyright (c) 2026 Iarash'), findsWidgets);
        expect(
          find.textContaining('PolyForm Noncommercial License 1.0.0'),
          findsWidgets,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  test('bundled app license exactly preserves repository terms', () {
    expect(
      File('assets/licenses/planact.txt').readAsBytesSync(),
      File('LICENSE').readAsBytesSync(),
    );
  });
}
