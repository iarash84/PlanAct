import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/features/reports/presentation/reports_page.dart';
import 'package:planact/features/settings/presentation/settings_page.dart';

class _Repository extends InMemoryCommitmentRepository {
  int writes = 0;

  @override
  Future<void> save(Commitment commitment) async {
    writes++;
    await super.save(commitment);
  }
}

Widget _host({
  required Widget home,
  required bool dark,
  TextDirection direction = TextDirection.rtl,
  bool reducedMotion = false,
}) => MaterialApp(
  theme: (dark ? PlanActTheme.dark() : PlanActTheme.light()).copyWith(
    platform: TargetPlatform.android,
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
    child: Directionality(textDirection: direction, child: child!),
  ),
  home: home,
);

// Measure rendered content rather than the implementation's animation values.
Future<void> _expectEntry(
  WidgetTester tester,
  Finder page, {
  bool reducedMotion = false,
  TextDirection direction = TextDirection.rtl,
}) async {
  await tester.pump();
  // Routes first lay out offstage for Hero measurement. Reveal the first
  // visible frame without advancing animation time.
  await tester.pump();
  if (reducedMotion) {
    expect(tester.getTopLeft(page).dx, closeTo(0, .01));
  }
  await tester.pump(const Duration(milliseconds: 30));
  final first = tester.getTopLeft(page).dx;
  await tester.pump(const Duration(milliseconds: 30));
  final second = tester.getTopLeft(page).dx;
  if (reducedMotion) {
    expect(first, closeTo(0, .01));
    expect(second, closeTo(0, .01));
  } else if (direction == TextDirection.rtl) {
    expect(first, lessThan(0));
    expect(second, greaterThan(first));
    expect(second, lessThan(0));
  } else {
    expect(first, greaterThan(0));
    expect(second, lessThan(first));
    expect(second, greaterThan(0));
  }
  await tester.pumpAndSettle();
  expect(tester.getTopLeft(page).dx, closeTo(0, .01));
}

Future<void> _expectExit(
  WidgetTester tester,
  Finder page, {
  bool reducedMotion = false,
  TextDirection direction = TextDirection.rtl,
}) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 30));
  final first = tester.getTopLeft(page).dx;
  await tester.pump(const Duration(milliseconds: 30));
  final second = tester.getTopLeft(page).dx;
  if (reducedMotion) {
    expect(first, closeTo(0, .01));
    expect(second, closeTo(0, .01));
  } else if (direction == TextDirection.rtl) {
    expect(first, lessThan(0));
    expect(second, lessThan(first));
  } else {
    expect(first, greaterThan(0));
    expect(second, greaterThan(first));
  }
  await tester.pumpAndSettle();
  expect(page, findsNothing);
}

void main() {
  for (final dark in [false, true]) {
    for (final direction in TextDirection.values) {
      testWidgets('shared Android push/pop dark=$dark direction=$direction', (
        tester,
      ) async {
        const pageKey = ValueKey('destination');
        await tester.pumpWidget(
          _host(
            dark: dark,
            direction: direction,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          const Scaffold(key: pageKey, body: SizedBox.expand()),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        final page = find.byKey(pageKey);
        await _expectEntry(tester, page, direction: direction);
        Navigator.of(tester.element(page)).pop();
        await _expectExit(tester, page, direction: direction);
        expect(find.text('open'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    for (final reducedMotion in [false, true]) {
      testWidgets(
        'More links enter from left and pop left dark=$dark reduced=$reducedMotion',
        (tester) async {
          final repository = _Repository();
          final smsCalls = <String>[];
          const channel = MethodChannel('planact/sms');
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (call) async {
              smsCalls.add(call.method);
              return false;
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(channel, null),
          );
          await tester.pumpWidget(
            _host(
              dark: dark,
              reducedMotion: reducedMotion,
              home: HomeShell(repository: repository),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('بیشتر').last);
          await tester.pumpAndSettle();
          for (final destination in [
            ('گزارش‌ها', ReportsPage),
            ('صندوق ورودی', InboxPage),
            ('تنظیمات', SettingsPage),
          ]) {
            final link = find.widgetWithText(ListTile, destination.$1);
            await tester.ensureVisible(link);
            await tester.tap(link);
            final page = find.byType(destination.$2);
            await _expectEntry(tester, page, reducedMotion: reducedMotion);
            expect(Directionality.of(tester.element(page)), TextDirection.rtl);
            await tester.tap(find.byType(BackButton));
            await _expectExit(tester, page, reducedMotion: reducedMotion);
            expect(link, findsOneWidget);
            expect(find.widgetWithText(AppBar, 'بیشتر'), findsOneWidget);
          }
          expect(repository.writes, 0);
          expect(smsCalls, everyElement('hasAccess'));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
