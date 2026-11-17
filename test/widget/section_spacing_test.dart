import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
import 'package:planact/features/today/presentation/today_page.dart';
import 'package:planact/features/calendar/presentation/calendar_visibility_controller.dart';
import 'package:planact/features/settings/presentation/calendar_visibility_settings.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/presentation/sms_automatic_sync_card.dart';
import 'package:planact/features/inbox/presentation/sms_sync_controller.dart';
import 'package:planact/features/reminders/presentation/reminder_permissions_card.dart';
import 'package:planact/features/settings/presentation/money_unit_settings_card.dart';
import 'package:planact/features/settings/presentation/settings_page.dart';
import 'package:planact/l10n/generated/app_localizations_fa.dart';

import '../fixtures/sms_provider.dart';

void main() {
  final copy = AppLocalizationsFa();

  void expectGap(WidgetTester tester, Finder first, Finder second, double gap) {
    expect(
      tester.getRect(second).top - tester.getRect(first).bottom,
      greaterThanOrEqualTo(gap),
    );
  }

  Future<void> show(
    WidgetTester tester,
    Widget child,
    bool dark,
    double scale,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: child!,
          ),
        ),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final dark in [false, true]) {
    for (final width in [320.0, 800.0]) {
      for (final scale in [1.0, 2.0]) {
        final variant = 'dark=$dark width=$width scale=$scale';
        testWidgets('SMS first-run and setup spacing: $variant', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final db = AppDatabase.forTesting(NativeDatabase.memory());
          final repo = DriftInboxRepository(db);
          final inbox = InboxUseCases(repo);
          final source = TestSmsProvider();
          final controller = SmsSyncController(inbox: inbox, source: source);
          addTearDown(() async {
            controller.dispose();
            await source.events.close();
            await db.close();
          });
          await controller.refresh(checkAccess: true);
          await show(
            tester,
            SingleChildScrollView(
              child: SmsAutomaticSyncCard(
                controller: controller,
                inbox: inbox,
                source: source,
                onCheck: () async => fail('Disabled manual check must not run'),
                onChanged: () async {},
              ),
            ),
            dark,
            scale,
          );
          final setup = find.widgetWithText(FilledButton, copy.smsSetupOpen);
          final check = find.widgetWithText(
            OutlinedButton,
            copy.smsCheckNewMessages,
          );
          expectGap(
            tester,
            find.text(copy.smsSetupDescription),
            setup,
            PlanActSpacing.sm,
          );
          expectGap(tester, setup, check, PlanActSpacing.sm);
          expect(tester.widget<OutlinedButton>(check).onPressed, isNull);
          await tester.ensureVisible(setup);
          await tester.tap(setup);
          await tester.pumpAndSettle();
          final chips = find.byType(ChoiceChip);
          expect(chips, findsNWidgets(3));
          expectGap(
            tester,
            find.descendant(
              of: find.byType(AlertDialog),
              matching: find.text(copy.smsSetupDescription),
            ),
            chips.first,
            PlanActSpacing.sm,
          );
          for (var index = 1; index < 3; index++) {
            final previous = tester.getRect(chips.at(index - 1));
            final next = tester.getRect(chips.at(index));
            if (next.top > previous.top) {
              expect(
                next.top - previous.bottom,
                greaterThanOrEqualTo(PlanActSpacing.sm),
              );
            }
          }
          expect(source.reads, 0);
          expect(await repo.readManualSmsScan(), isNull);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });

        testWidgets('Today conditional section spacing: $variant', (
          tester,
        ) async {
          await tester.binding.setSurfaceSize(Size(width, 3000));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          await show(
            tester,
            TodayPage(
              commitments: const [],
              scheduledDates: const {},
              smsSyncError: copy.smsAutomaticSyncFailed,
              error: copy.commonUnknown,
              onAdd: () {},
              onCommitmentTap: (_) {},
              onCommitmentArchive: (_) {},
              onReview: (_) {},
              onOpenRelationshipQueue: () {},
            ),
            dark,
            scale,
          );
          final messages = find.byType(PlanActStateMessage);
          final queue = find.widgetWithText(
            OutlinedButton,
            copy.relationshipQueuePageBuildTitle,
          );
          expectGap(tester, messages.first, queue, PlanActSpacing.lg);
          expectGap(tester, queue, messages.last, PlanActSpacing.lg);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });

        testWidgets('independent Settings sections: $variant', (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 900));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final visibility = CalendarVisibilityController(null);
          addTearDown(visibility.dispose);
          for (final optional in [false, true]) {
            await show(
              tester,
              SettingsPage(
                themeMode: ThemeMode.system,
                onThemeModeChanged: (_) {},
                calendarVisibility: optional ? visibility : null,
                onManageTags: optional ? () {} : null,
                onBackgroundChanged: optional ? (_) async {} : null,
                onShowArchivedAccountsChanged: optional ? (_) async {} : null,
                enableReminders: optional ? () async => true : null,
              ),
              dark,
              scale,
            );
            final general = find.text(copy.commonGeneral);
            final money = find.byType(MoneyUnitSettingsCard);
            if (optional) {
              final calendar = find.byType(CalendarVisibilitySettings);
              expectGap(tester, money, calendar, PlanActSpacing.lg);
              expectGap(tester, calendar, general, PlanActSpacing.lg);
            } else {
              expectGap(tester, money, general, PlanActSpacing.lg);
            }
            final column = tester.widget<Column>(
              find
                  .descendant(
                    of: find.byType(SingleChildScrollView).first,
                    matching: find.byType(Column),
                  )
                  .first,
            );
            final cards = column.children.whereType<Card>().toList();
            for (var index = 1; index < cards.length; index++) {
              expectGap(
                tester,
                find.byWidget(cards[index - 1]),
                find.byWidget(cards[index]),
                PlanActSpacing.lg,
              );
            }
            if (optional) {
              expectGap(
                tester,
                find.byType(ReminderPermissionsCard),
                find.text(copy.settingsAbout),
                PlanActSpacing.lg,
              );
            }
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox.shrink());
          }
        });
      }
    }
  }
}
