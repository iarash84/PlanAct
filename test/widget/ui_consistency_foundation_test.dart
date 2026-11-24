import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/planact_typography.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
import 'package:planact/features/settings/presentation/settings_page.dart';
import 'package:planact/features/today/presentation/today_page.dart';

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? PlanActTheme.dark() : PlanActTheme.light();
    final status = theme.extension<PlanActStatusColors>()!;
    final roles = {
      PlanActMessageKind.info: (Icons.info_outline, status.info),
      PlanActMessageKind.empty: (
        Icons.inbox_outlined,
        theme.colorScheme.onSurfaceVariant,
      ),
      PlanActMessageKind.success: (Icons.check_circle_outline, status.success),
      PlanActMessageKind.error: (Icons.error_outline, theme.colorScheme.error),
      PlanActMessageKind.warning: (
        Icons.warning_amber_outlined,
        status.attention,
      ),
    };
    for (final entry in roles.entries) {
      testWidgets('feedback ${entry.key.name}, dark=$dark, RTL large text', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(const Size(320, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        var retries = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Scaffold(
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(PlanActSpacing.page),
                    child: PlanActStateMessage(
                      kind: entry.key,
                      title: 'عنوان وضعیت',
                      message:
                          'پیام فارسی با مبلغ ۱۲۳٬۴۵۶ و PlanAct برای بررسی',
                      action: TextButton(
                        onPressed: () => retries++,
                        child: const Text('تلاش دوباره'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final icon = tester.widget<Icon>(find.byIcon(entry.value.$1));
        expect(icon.color, entry.value.$2);
        if (entry.key != PlanActMessageKind.success) {
          expect(find.byIcon(Icons.check_circle_outline), findsNothing);
        }
        final semantics = tester.widget<Semantics>(
          find
              .descendant(
                of: find.byType(PlanActStateMessage),
                matching: find.byType(Semantics),
              )
              .first,
        );
        expect(
          semantics.properties.liveRegion,
          [
            PlanActMessageKind.error,
            PlanActMessageKind.warning,
            PlanActMessageKind.success,
          ].contains(entry.key),
        );
        await tester.ensureVisible(find.text('تلاش دوباره'));
        await tester.tap(find.text('تلاش دوباره'));
        expect(retries, 1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('legacy error callers keep error semantics and precedence', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PlanActStateMessage(
            message: 'خطا',
            isError: true,
            kind: PlanActMessageKind.success,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });

  testWidgets('Today and Settings ordinary page margins use page token', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayPage(
            commitments: const [],
            scheduledDates: const {},
            onAdd: () {},
            onCommitmentTap: (_) {},
            onCommitmentArchive: (_) {},
            onReview: (_) {},
            bottomContentPadding: 72,
          ),
        ),
      ),
    );
    final todayPadding = tester
        .widget<ListView>(find.byType(ListView).first)
        .padding!
        .resolve(TextDirection.rtl);
    expect(todayPadding.left, PlanActSpacing.page);
    expect(todayPadding.right, PlanActSpacing.page);
    expect(todayPadding.bottom, PlanActSpacing.lg + 72);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            themeMode: ThemeMode.system,
            onThemeModeChanged: (_) {},
          ),
        ),
      ),
    );
    final settings = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView).first,
    );
    expect(settings.padding, const EdgeInsets.all(PlanActSpacing.page));
    expect(tester.takeException(), isNull);
  });

  test('all shared typography roles use bundled family in both themes', () {
    for (final theme in [PlanActTheme.light(), PlanActTheme.dark()]) {
      for (final style in [
        theme.textTheme.bodyLarge,
        theme.textTheme.bodyMedium,
        theme.textTheme.bodySmall,
        theme.textTheme.titleMedium,
        theme.textTheme.titleLarge,
        theme.textTheme.labelLarge,
      ]) {
        expect(style!.fontFamily, PlanActTypography.fontFamily);
      }
      expect(theme.textTheme.bodyLarge!.height, 1.6);
      expect(theme.textTheme.titleMedium!.fontWeight, FontWeight.w600);
    }
  });

  testWidgets('bundled font assets are real TrueType and load offline', (
    tester,
  ) async {
    final loader = FontLoader(PlanActTypography.fontFamily);
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      final data = await rootBundle.load(
        'assets/fonts/vazirmatn/Vazirmatn-$weight.ttf',
      );
      expect(data.getUint32(0), 0x00010000);
      expect(data.lengthInBytes, greaterThan(100000));
      loader.addFont(Future.value(data));
    }
    await loader.load();
    expect(
      await rootBundle.loadString('assets/fonts/vazirmatn/OFL.txt'),
      contains('SIL OPEN FONT LICENSE Version 1.1'),
    );
  });

  test('audited ordinary-page boundaries explicitly use page token', () {
    for (final path in [
      'lib/features/commitments/presentation/checklist_page.dart',
      'lib/features/reconciliation/presentation/relationship_queue_page.dart',
      'lib/features/reconciliation/presentation/transaction_relationship_page.dart',
      'lib/features/finance/presentation/accounts_management_view.dart',
      'lib/features/search/presentation/search_page.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('padding: const EdgeInsets.all(PlanActSpacing.page)'),
        reason: path,
      );
    }
    expect(
      File('lib/features/finance/presentation/finance_page.dart')
          .readAsStringSync(),
      contains(RegExp(r'PlanActSpacing\.page,\r?\n')),
    );
  });
}
