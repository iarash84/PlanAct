import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/tag_identity_colors.dart';
import 'package:planact/features/classification/presentation/tag_badge.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/classification/presentation/tag_selection.dart';

void main() {
  test('normalized names reproduce identity without mutable state', () {
    for (final brightness in Brightness.values) {
      expect(
        TagIdentityColors.forLabel(' # Work ', brightness),
        TagIdentityColors.forLabel('work', brightness),
      );
      final names = ['خرید', 'خانه', 'سلامت', 'آموزش', 'سفر', 'کار'];
      final colors = names
          .map((n) => TagIdentityColors.forLabel(n, brightness))
          .toList();
      expect(colors.toSet().length, names.length);
      expect(
        names.reversed
            .map((n) => TagIdentityColors.forLabel(n, brightness))
            .toList(),
        colors.reversed.toList(),
      );
      final samples = List.generate(
        2000,
        (i) => TagIdentityColors.forLabel('برچسب$i', brightness),
      );
      expect(
        List.generate(
          2000,
          (i) => TagIdentityColors.forLabel('برچسب${1999 - i}', brightness),
        ),
        samples.reversed.toList(),
      );
      for (final pair in [...colors, ...samples]) {
        final a = pair.foreground.computeLuminance();
        final b = pair.container.computeLuminance();
        final contrast = ((a > b ? a : b) + .05) / ((a < b ? a : b) + .05);
        expect(contrast, greaterThanOrEqualTo(4.5));
      }
    }
  });

  for (final dark in [false, true]) {
    testWidgets(
      'read-only, draft and selection retain the same identity ($dark)',
      (tester) async {
        final theme = dark ? PlanActTheme.dark() : PlanActTheme.light();
        var selected = false;
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: [
                    const TagLabels(labels: ['کار']),
                    CompactTagSelection(labels: const ['کار'], onOpen: () {}),
                    StatefulBuilder(
                      builder: (context, setState) => TagBadge(
                        label: 'کار',
                        selectable: true,
                        selected: selected,
                        onSelected: (value) => setState(() => selected = value),
                      ),
                    ),
                    const TagSummaryText(text: 'انتخاب: #کار', labels: ['کار']),
                  ],
                ),
              ),
            ),
          ),
        );
        final colors = TagIdentityColors.forLabel('کار', theme.brightness);
        for (final chip in tester.widgetList<Chip>(find.byType(Chip))) {
          expect(chip.backgroundColor, colors.container);
          expect(chip.labelStyle?.color, colors.foreground);
        }
        final before = tester.widget<FilterChip>(find.byType(FilterChip));
        expect(before.backgroundColor, colors.container);
        expect(before.selectedColor, colors.container);
        await tester.tap(find.byType(FilterChip));
        await tester.pumpAndSettle();
        expect(selected, isTrue);
        expect(
          tester.widget<FilterChip>(find.byType(FilterChip)).checkmarkColor,
          colors.foreground,
        );
        final rich = tester.widget<Text>(
          find.byWidgetPredicate((w) => w is Text && w.textSpan != null),
        );
        final span = (rich.textSpan! as TextSpan).children!
            .whereType<TextSpan>()
            .firstWhere((s) => s.text == '#کار');
        expect(span.style?.color, colors.foreground);
        expect(span.style?.backgroundColor, colors.container);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
