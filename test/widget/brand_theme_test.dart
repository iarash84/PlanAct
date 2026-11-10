import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/planact_status_colors.dart';

// Golden text uses Flutter's test font, not proof of native Persian shaping.
double ratio(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  for (final dark in [false, true]) {
    final name = dark ? 'dark' : 'light';
    final theme = dark ? PlanActTheme.dark() : PlanActTheme.light();
    final s = theme.colorScheme;
    test('$name brand and component state contrast', () {
      for (final pair in [
        (s.onPrimary, s.primary),
        (s.onPrimaryContainer, s.primaryContainer),
        (s.onSecondary, s.secondary),
        (s.onSecondaryContainer, s.secondaryContainer),
        (s.onTertiary, s.tertiary),
        (s.onTertiaryContainer, s.tertiaryContainer),
        (s.primary, s.surface),
        (s.onSurface, s.primaryContainer),
      ]) {
        expect(ratio(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      }
      expect(
        ratio(s.primary, s.surfaceContainerHighest),
        greaterThanOrEqualTo(3),
      );
      final disabled = {WidgetState.disabled};
      final filled = theme.filledButtonTheme.style!;
      expect(
        ratio(
          filled.foregroundColor!.resolve(disabled)!,
          filled.backgroundColor!.resolve(disabled)!,
        ),
        greaterThanOrEqualTo(4.5),
      );
      final selected = {WidgetState.selected};
      final segmented = theme.segmentedButtonTheme.style!;
      expect(segmented.backgroundColor!.resolve(selected), s.primaryContainer);
      expect(
        segmented.foregroundColor!.resolve(selected),
        s.onPrimaryContainer,
      );
      expect(theme.chipTheme.selectedColor, s.primaryContainer);
      expect(theme.chipTheme.checkmarkColor, s.onPrimaryContainer);
      expect(
        theme.extension<PlanActStatusColors>(),
        dark ? PlanActStatusColors.dark : PlanActStatusColors.light,
      );
      expect(s.primary, isNot(theme.extension<PlanActStatusColors>()!.success));
    });

    Future<void> pumpGallery(
      WidgetTester tester, {
      VoidCallback? onSubmit,
    }) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Builder(
              builder: (context) => RepaintBoundary(
                key: const Key('brand-gallery'),
                child: Scaffold(
                  appBar: AppBar(title: const Text('پلن‌اکت')),
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text('برنامه، اقدام، نتیجه'),
                      FilledButton(
                        onPressed: onSubmit ?? () {},
                        child: const Text('ثبت'),
                      ),
                      const FilledButton(
                        onPressed: null,
                        child: Text('در حال ذخیره'),
                      ),
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('بازگشت'),
                      ),
                      const TextField(
                        decoration: InputDecoration(labelText: 'عنوان'),
                      ),
                      const SizedBox(height: 16),
                      const Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(label: Text('انتخاب‌شده'), selected: true),
                          ChoiceChip(label: Text('دیگر'), selected: false),
                        ],
                      ),
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('ماه')),
                          ButtonSegment(value: 1, label: Text('هفته')),
                        ],
                        selected: const {0},
                        onSelectionChanged: (_) {},
                      ),
                      TextButton(
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('تأیید'),
                            content: Text(
                              Theme.of(context).colorScheme.primary == s.primary
                                  ? 'تم مشترک'
                                  : 'تم نادرست',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('بستن'),
                              ),
                            ],
                          ),
                        ),
                        child: const Text('نمایش پنجره'),
                      ),
                    ],
                  ),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: 0,
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.today),
                        label: 'امروز',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.calendar_month),
                        label: 'تقویم',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.wallet),
                        label: 'مالی',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    testWidgets('$name shared controls and modal inheritance', (tester) async {
      var calls = 0;
      await pumpGallery(tester, onSubmit: () => calls++);
      await tester.tap(find.text('در حال ذخیره'));
      expect(calls, 0);
      await tester.tap(find.text('ثبت'));
      expect(calls, 1);
      expect(
        tester.getSize(find.byType(FilledButton).first).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.text('نمایش پنجره'));
      await tester.pumpAndSettle();
      expect(find.text('تم مشترک'), findsOneWidget);
      await tester.tap(find.text('بستن'));
      await tester.pumpAndSettle();
      final context = tester.element(find.byKey(const Key('brand-gallery')));
      expect(Directionality.of(context), TextDirection.rtl);
    });

    testWidgets(
      '$name Linux reference golden (Linux only; behavior tested on all hosts)',
      (tester) async {
        await pumpGallery(tester);
        await expectLater(
          find.byKey(const Key('brand-gallery')),
          matchesGoldenFile('goldens/linux/brand_$name.png'),
        );
      },
      // Only the reference host generates/compares these images. Behavior above
      // remains tested on every host. See docs/UI_MIGRATION_VERIFICATION.md.
      skip: !Platform.isLinux,
    );
  }
}
