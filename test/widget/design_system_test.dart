import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';

double contrast(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  for (final dark in [false, true]) {
    final theme = dark ? PlanActTheme.dark() : PlanActTheme.light();
    final name = dark ? 'dark' : 'light';
    test('$name brand and status foregrounds meet normal text contrast', () {
      final scheme = theme.colorScheme;
      final status = theme.extension<PlanActStatusColors>()!;
      final pairs = [
        (scheme.onPrimary, scheme.primary),
        (scheme.onPrimaryContainer, scheme.primaryContainer),
        (scheme.onSurface, scheme.surface),
        (scheme.onSurfaceVariant, scheme.surfaceContainer),
        (scheme.onError, scheme.error),
        (status.success, status.successContainer),
        (status.attention, status.attentionContainer),
        (status.danger, status.dangerContainer),
        (status.info, status.infoContainer),
        (status.inactive, status.inactiveContainer),
        for (final color in [
          status.success,
          status.attention,
          status.danger,
          status.info,
          status.inactive,
        ])
          (color, scheme.surface),
      ];
      for (final pair in pairs) {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
      expect(status.copyWith().info, status.info);
      expect(status.lerp(status, .5).info, status.info);
    });

    Widget host(Widget child, {double scale = 2}) => MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(320, 640),
          textScaler: TextScaler.linear(scale),
          disableAnimations: true,
        ),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );

    testWidgets('$name narrow RTL calendar preserves targets and scaled text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
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
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final targets = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.button == true,
      );
      expect(targets, findsWidgets);
      for (final element in targets.evaluate()) {
        final size = tester.getSize(find.byWidget(element.widget));
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('$name date picker and form wrap without scaled overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(PlanActJalaliDatePicker(initialDate: DateTime(2026, 3, 21))),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byKey(const ValueKey('capture-date-1'))).width,
        greaterThanOrEqualTo(48),
      );
      await tester.pumpWidget(
        host(
          PlanActFormSheet(
            title: 'ثبت تعهد',
            error: 'ذخیره انجام نشد؛ دوباره تلاش کنید.',
            primaryLabel: 'ذخیره و ادامه',
            onPrimary: () {},
            onSecondary: () {},
            child: const TextField(
              decoration: InputDecoration(labelText: 'عنوان تعهد'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('ذخیره و ادامه'), findsOneWidget);
    });

    testWidgets('$name reduced motion resolves to final state', (tester) async {
      Duration? duration;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              duration = PlanActMotion.duration(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(duration, Duration.zero);
    });
  }
}
