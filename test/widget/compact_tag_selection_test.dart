import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('1000 tags are lazy; search retains draft selection ($dark)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repository = InMemoryTagRepository();
      for (var i = 0; i < 1000; i++) {
        await repository.getOrCreate('tag$i');
      }
      var selected = <String>{'tag1', 'tag2', 'tag3', 'tag4', 'tag5'};
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: child!,
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) => DraftTagPicker(
                  repository: repository,
                  selected: selected,
                  onChanged: (value) => setState(() => selected = value),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Chip), findsNWidgets(4));
      expect(find.text('و ۲ برچسب دیگر'), findsOneWidget);
      expect(find.text('#tag999'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('tag-selection-open')));
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile).evaluate().length, lessThan(30));
      await tester.tap(find.byIcon(Icons.fullscreen));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.fullscreen_exit), findsOneWidget);
      await tester.tap(find.byIcon(Icons.fullscreen_exit));
      await tester.pumpAndSettle();
      final search = find.byKey(const ValueKey('tag-selection-search'));
      await tester.enterText(search, 'tag999');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.widgetWithText(CheckboxListTile, '#tag999'),
        150,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('tag-selection-results')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.widgetWithText(CheckboxListTile, '#tag999'));
      await tester.pumpAndSettle();
      await tester.enterText(search, 'tag1');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, '#tag1'),
            )
            .value,
        isTrue,
      );
      await tester.enterText(search, 'tag999');
      await tester.pumpAndSettle();
      expect(
        tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
        isTrue,
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(search, 'new explicit tag');
      await tester.pumpAndSettle();
      expect(await repository.list(), hasLength(1000));
      await tester.ensureVisible(find.text('افزودن برچسب «new explicit tag»'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('افزودن برچسب «new explicit tag»'));
      await tester.pumpAndSettle();
      expect(selected, contains('new explicit tag'));
      expect(await repository.list(), hasLength(1000));
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('بستن'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      expect(await repository.list(), hasLength(1000));
      expect(tester.takeException(), isNull);
    });
  }
}
