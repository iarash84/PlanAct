import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';
import 'package:planact/features/today/application/attention_engine.dart';
import 'package:planact/features/today/presentation/today_page.dart';

void main() {
  for (final brightness in Brightness.values) {
    Widget host(Widget child, double scale) => MaterialApp(
      theme: brightness == Brightness.dark
          ? PlanActTheme.dark()
          : PlanActTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(scale)),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        '$brightness / $scale Calendar toggle retains exact bounds across modes',
        (tester) async {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            host(
              CalendarPage(
                commitments: const [],
                scheduledDates: const {},
                initialDate: JalaliDate(1405, 1, 1),
              ),
              scale,
            ),
          );
          final toggle = find.byKey(const ValueKey('calendar-mode-toggle'));
          final initial = tester.getRect(toggle);
          expect(initial.width, 296);
          await tester.tap(find.text('هفته'));
          await tester.pumpAndSettle();
          expect(tester.getRect(toggle), initial);
          expect(tester.widget<SegmentedButton<bool>>(toggle).selected, {true});
          await tester.tap(find.text('ماه'));
          await tester.pumpAndSettle();
          expect(tester.getRect(toggle), initial);
          expect(tester.widget<SegmentedButton<bool>>(toggle).selected, {
            false,
          });
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      '$brightness Today identity covers attention/today/upcoming without coloring independent reviews',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final commitment = Commitment.create(
          title: 'کلاس موسیقی',
          color: CommitmentColor.violet,
        );
        final legacy = Commitment.create(title: 'تعهد بدون رنگ');
        TodayActionItem item(String id, Commitment? value) => TodayActionItem(
          id: id,
          type: value == null
              ? TodayActionItemType.financialReview
              : TodayActionItemType.occurrence,
          title: value?.title ?? 'تراکنش نیازمند بررسی',
          subtitle: 'نیاز به رسیدگی',
          urgency: 60,
          commitment: value,
        );
        Commitment? opened;
        TodayActionItem? reviewed;
        final review = item('review', null);
        await tester.pumpWidget(
          host(
            TodayPage(
              commitments: [commitment, legacy],
              scheduledDates: const {},
              actionCenter: TodayActionCenter(
                attention: [item('attention', commitment)],
                today: [item('today', commitment), review],
                upcoming: [
                  item('upcoming', commitment),
                  item('legacy', legacy),
                ],
              ),
              onAdd: () {},
              onCommitmentTap: (value) => opened = value,
              onCommitmentArchive: (_) {},
              onReview: (value) => reviewed = value,
            ),
            1,
          ),
        );
        expect(find.byType(CommitmentIdentityMarker), findsNWidgets(4));
        for (final id in ['attention', 'today', 'upcoming', 'legacy']) {
          final marker = find.byKey(ValueKey('today-identity-$id'));
          final container = tester.widget<Container>(
            find.descendant(of: marker, matching: find.byType(Container)),
          );
          final color = id == 'legacy'
              ? CommitmentIdentityPalette.fallback(legacy.id)
              : CommitmentColor.violet;
          expect(
            (container.decoration as BoxDecoration).color,
            CommitmentIdentityPalette.background(color, brightness),
          );
          expect(
            find.descendant(of: marker, matching: find.byType(Semantics)),
            findsWidgets,
          );
        }
        expect(
          find.byKey(const ValueKey('today-identity-review')),
          findsNothing,
        );
        await tester.tap(find.text('تعیین وضعیت').first);
        expect(opened, commitment);
        await tester.tap(find.text('اقدام').last);
        expect(reviewed, review);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
