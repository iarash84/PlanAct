import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/theme_preset.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/domain/calendar_transaction.dart';
import 'package:planact/features/calendar/domain/calendar_visibility.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/calendar/presentation/calendar_transaction_tile.dart';
import 'package:planact/features/calendar/presentation/week_timeline_view.dart';
import 'package:planact/features/classification/domain/tag.dart';
import 'package:planact/features/classification/presentation/tag_badge.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_identity_icon.dart';

import '../unit/calendar_transaction_test.dart' show calendarEntry;

void main() {
  const day = JalaliDate(1405, 8, 23);
  final account = FinancialAccount(
    id: StableId.generate(),
    name: 'حساب روزمره با نام طولانی',
    currency: 'IRR',
    type: FinancialAccountType.bank,
    bank: IranianBank.mellat,
  );
  final tag = Tag(
    id: StableId.generate(),
    label: 'خرید',
    createdAt: DateTime(2026),
  );
  final items = [
    for (final kind in CalendarTransactionKind.values)
      CalendarTransaction(
        entry: calendarEntry(switch (kind) {
          CalendarTransactionKind.income => AccountEntryType.income,
          CalendarTransactionKind.expense => AccountEntryType.expense,
          CalendarTransactionKind.transfer => AccountEntryType.transferOut,
        }, day.toDateTime().add(const Duration(hours: 14))),
        kind: kind,
        reversed: kind == CalendarTransactionKind.expense,
        accounts: [account],
        tags: [tag],
      ),
  ];
  for (final dark in [false, true]) {
    for (final preset in ThemePreset.values) {
      for (final first in items) {
        testWidgets('Month expense frames follow preset, income stays green: '
            '${first.kind}, dark=$dark, preset=$preset', (tester) async {
          await tester.binding.setSurfaceSize(const Size(320, 1600));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final ordered = [first, ...items.where((item) => item != first)];
          await tester.pumpWidget(
            MaterialApp(
              theme: dark
                  ? PlanActTheme.dark(preset: preset)
                  : PlanActTheme.light(preset: preset),
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(2)),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(
                    body: CalendarPage(
                      commitments: const [],
                      scheduledDates: const {},
                      initialDate: day,
                      visibility: const CalendarVisibility(
                        income: true,
                        expense: true,
                        transfers: true,
                      ),
                      transactionLoader: (start, end) async => ordered,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final dayFinder = find.byKey(ValueKey('calendar-day-${day.day}'));
          for (final item in ordered.take(2)) {
            final marker = find.byKey(
              ValueKey('month-transaction-${day.day}-${item.entry.id.value}'),
            );
            expect(marker, findsOneWidget);
            final container = tester.widget<Container>(marker);
            final decoration = container.decoration! as BoxDecoration;
            final roles = PlanActStatusColors.of(tester.element(marker));
            final incoming = item.kind == CalendarTransactionKind.income;
            final expense = item.kind == CalendarTransactionKind.expense;
            final scheme = Theme.of(tester.element(marker)).colorScheme;
            expect(
              decoration.color,
              expense
                  ? scheme.secondaryContainer
                  : incoming
                  ? roles.successContainer
                  : roles.attentionContainer,
            );
            expect(
              (decoration.border! as Border).top.color,
              expense
                  ? scheme.secondary
                  : incoming
                  ? roles.success
                  : roles.attention,
            );
            final text = tester.widget<Text>(
              find.descendant(of: marker, matching: find.byType(Text)),
            );
            expect(
              text.style!.color,
              expense
                  ? scheme.onSecondaryContainer
                  : incoming
                  ? roles.success
                  : roles.attention,
            );
            expect(text.maxLines, 2);
            final cellRect = tester.getRect(dayFinder);
            final markerRect = tester.getRect(marker);
            expect(markerRect.left, greaterThanOrEqualTo(cellRect.left));
            expect(markerRect.right, lessThanOrEqualTo(cellRect.right));
            expect(markerRect.bottom, lessThanOrEqualTo(cellRect.bottom));
          }
          expect(
            find.byKey(
              ValueKey(
                'month-transaction-${day.day}-${ordered.last.entry.id.value}',
              ),
            ),
            findsNothing,
          );
          expect(
            find.descendant(of: dayFinder, matching: find.text('+۱')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
    for (final mode in ['month', 'month-wide', 'week-agenda', 'week-wide']) {
      testWidgets(
        '$mode separated financial cards with durable metadata, dark=$dark',
        (tester) async {
          final wide = mode.endsWith('wide');
          await tester.binding.setSurfaceSize(Size(wide ? 1800 : 320, 1600));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          CalendarTransaction? opened;
          final content = mode.startsWith('month')
              ? CalendarPage(
                  commitments: const [],
                  scheduledDates: const {},
                  initialDate: day,
                  visibility: const CalendarVisibility(
                    income: true,
                    expense: true,
                    transfers: true,
                  ),
                  transactionLoader: (start, end) async => items,
                  onTransactionTap: (item) => opened = item,
                )
              : WeekTimelineView(
                  date: day,
                  commitments: const [],
                  occurrences: const {},
                  holidays: IranianHolidayProvider(),
                  transactionLoader: (start, end) async => items,
                  onTransactionTap: (item) => opened = item,
                );
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
              home: MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(wide ? 1 : 2),
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Scaffold(body: content),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final tiles = find.byType(CalendarTransactionTile);
          if (mode.startsWith('month')) {
            await tester.scrollUntilVisible(
              find.byKey(
                ValueKey('calendar-transaction-${items.first.entry.id.value}'),
              ),
              400,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
          }
          // Inspect each lazily built card instead of requiring the entire
          // enlarged list to coexist inside the viewport/cache extent.
          for (var i = 0; i < items.length; i++) {
            final cardFinder = find.byKey(
              ValueKey('calendar-transaction-${items[i].entry.id.value}'),
            );
            if (mode.startsWith('month')) {
              await tester.scrollUntilVisible(
                cardFinder,
                200,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.pumpAndSettle();
            }
            expect(
              find.descendant(of: cardFinder, matching: find.byType(TagBadge)),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: cardFinder,
                matching: find.byType(AccountIdentityIcon),
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: cardFinder,
                matching: find.text('حساب روزمره با نام طولانی · ملت'),
              ),
              findsOneWidget,
            );
            final card = tester.widget<Card>(
              find.descendant(of: cardFinder, matching: find.byType(Card)),
            );
            final theme = Theme.of(tester.element(cardFinder));
            // User contract: detail cards inherit the ordinary app card, not
            // the financial marker palette. Check resolved rendering as well.
            expect(card.color, isNull);
            expect(card.shape, isNull);
            final surface = tester.widget<Material>(
              find
                  .descendant(of: cardFinder, matching: find.byType(Material))
                  .first,
            );
            expect(surface.color, theme.cardTheme.color);
            expect(surface.shape, theme.cardTheme.shape);
            if (i > 0) {
              final previous = find.byKey(
                ValueKey('calendar-transaction-${items[i - 1].entry.id.value}'),
              );
              if (previous.evaluate().isNotEmpty) {
                expect(
                  tester.getTopLeft(cardFinder).dy -
                      tester.getBottomLeft(previous).dy,
                  greaterThanOrEqualTo(PlanActSpacing.sm),
                );
              }
            }
          }
          final target = find.byKey(
            ValueKey('calendar-transaction-${items[1].entry.id.value}'),
          );
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          // Tap the title rather than a potentially offscreen center of a tall card.
          await tester.ensureVisible(
            find.descendant(
              of: tiles,
              matching: find.text('هزینهٔ ثبت‌شده · برگشت‌خورده؛ فقط تاریخچه'),
            ),
          );
          await tester.tap(
            find.descendant(
              of: tiles,
              matching: find.text('هزینهٔ ثبت‌شده · برگشت‌خورده؛ فقط تاریخچه'),
            ),
          );
          expect(opened, items[1]);
          expect(
            find.byKey(const ValueKey('week-header-scroll')),
            mode == 'week-wide' ? findsOneWidget : findsNothing,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
