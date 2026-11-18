import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/settings/presentation/about_page.dart';
import 'package:planact/features/settings/presentation/app_version_info.dart';

void main() {
  void metadata() => PackageInfo.setMockInitialValues(
    appName: 'Native name',
    packageName: 'test.planact',
    version: '7.8.9',
    buildNumber: '123',
    buildSignature: '',
  );

  Future<void> reveal(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('navigation-drawer-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    testWidgets('drawer About and version at 320dp/2x, dark=$dark', (
      tester,
    ) async {
      metadata();
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      tester.platformDispatcher.platformBrightnessTestValue = dark
          ? Brightness.dark
          : Brightness.light;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      await tester.pumpWidget(const PlanActApp());
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'تقویم'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('shell-menu')));
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(Drawer))),
        TextDirection.rtl,
      );
      expect(
        Theme.of(tester.element(find.byType(Drawer))).brightness,
        dark ? Brightness.dark : Brightness.light,
      );
      expect(tester.takeException(), isNull);
      await reveal(tester, find.text('نسخه: ۷.۸.۹\nشمارهٔ ساخت: ۱۲۳'));
      expect(find.text('Native name'), findsNothing);
      final about = find.byKey(const ValueKey('navigation-about'));
      await tester.ensureVisible(about);
      await tester.pumpAndSettle();
      expect(tester.getSize(about).height, greaterThanOrEqualTo(48));
      await tester.tap(about);
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing);
      expect(find.byType(AboutPage), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(AboutPage), findsNothing);
      expect(find.widgetWithText(AppBar, 'تقویم'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('shell-menu')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('navigation-close')));
      await tester.pumpAndSettle();
      expect(find.byType(Drawer), findsNothing);
      expect(find.widgetWithText(AppBar, 'تقویم'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('shared version metadata waits, retries and survives rebuild', (
    tester,
  ) async {
    final pending = Completer<PackageInfo>();
    var calls = 0;
    Future<PackageInfo> load() {
      calls++;
      if (calls == 1) return pending.future;
      return Future.value(
        PackageInfo(
          appName: 'Native',
          packageName: 'test',
          version: '9.1.2',
          buildNumber: '',
        ),
      );
    }

    Widget app() => MaterialApp(
      locale: const Locale('fa'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: PlanActTheme.light(),
      home: Scaffold(body: AppVersionInfo(loadPackageInfo: load)),
    );
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.text('در حال خواندن اطلاعات نسخه…'), findsOneWidget);
    await tester.pumpWidget(app());
    expect(calls, 1);
    pending.completeError(StateError('unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('خواندن اطلاعات نسخه انجام نشد.'), findsOneWidget);
    await tester.tap(find.text('تلاش دوباره'));
    await tester.pumpAndSettle();
    expect(find.textContaining('نسخه: ۹.۱.۲'), findsOneWidget);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });
}
