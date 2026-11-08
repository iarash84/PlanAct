import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/settings/presentation/settings_page.dart';

Future<void> tap(WidgetTester tester, Finder finder) async {
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.3);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  for (final dark in [false, true]) {
    testWidgets('Settings opens shared durable tag manager, dark=$dark', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final tags = DriftTagRepository(database);
      final original = await tags.getOrCreate('آموزش');
      await tester.pumpWidget(
        PlanActApp(repository: DriftCommitmentRepository(database)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_horiz).last);
      await tester.pumpAndSettle();
      await tap(tester, find.text('تنظیمات'));
      final l10n = planActL10n(tester.element(find.byType(SettingsPage)));
      await tap(
        tester,
        find.text(dark ? l10n.settingsThemeDark : l10n.settingsThemeLight),
      );
      final link = find.text(l10n.tagControlsContentChildren);
      await tap(tester, link);
      expect(find.text('#آموزش'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text('#آموزش'))),
        TextDirection.rtl,
      );
      expect(
        Theme.of(tester.element(find.text('#آموزش'))).brightness,
        dark ? Brightness.dark : Brightness.light,
      );
      // Opening and dismissing management must not change durable tags.
      Navigator.of(tester.element(find.byType(TextField))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
      expect((await tags.list()).single.id, original.id);
      await tap(tester, link);
      await tester.enterText(find.byType(TextField), 'سلامت');
      await tap(tester, find.text(l10n.tagControlsContentLabel));
      expect((await tags.list()).map((tag) => tag.label), contains('سلامت'));
      expect(find.text('#سلامت'), findsOneWidget);
      Navigator.of(tester.element(find.byType(TextField))).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(SettingsPage))).pop();
      await tester.pumpAndSettle();
      // The original Finance entry remains and reads the same durable tag.
      await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined).last);
      await tester.pumpAndSettle();
      await tap(tester, find.text(l10n.tagControlsContentChildren));
      final panel = find.byType(BottomSheet);
      expect(
        find.descendant(of: panel, matching: find.text('#سلامت')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: panel, matching: find.text('#آموزش')),
        findsOneWidget,
      );
      expect(await tags.list(), hasLength(2));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
