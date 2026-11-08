import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'inline draft tags are optional, bounded and reversible ($dark)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = InMemoryTagRepository();
        for (var i = 0; i < 8; i++) {
          await repository.getOrCreate('برچسب $i');
        }
        var selected = <String>{};
        var enabled = true;
        late StateSetter update;
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
                  builder: (context, setState) {
                    update = setState;
                    return DraftTagPicker(
                      repository: repository,
                      selected: selected,
                      enabled: enabled,
                      inlineSuggestions: true,
                      onChanged: (value) => setState(() => selected = value),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('برچسب‌ها · اختیاری'), findsOneWidget);
        expect(find.text('همهٔ برچسب‌ها'), findsOneWidget);
        expect(find.byType(FilterChip), findsNWidgets(3));
        expect(selected, isEmpty);
        expect(
          tester
              .widgetList<FilterChip>(find.byType(FilterChip))
              .every((chip) => !chip.selected),
          isTrue,
        );
        await tester.tap(find.byType(FilterChip).first);
        await tester.pumpAndSettle();
        expect(selected, hasLength(1));
        expect(
          await repository.tagsFor('unsaved', TaggableType.accountEntry),
          isEmpty,
        );
        update(() => enabled = false);
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilterChip>(find.byType(FilterChip).first).onSelected,
          isNull,
        );
        update(() => enabled = true);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(FilterChip).first);
        await tester.pumpAndSettle();
        expect(selected, isEmpty);
        expect(await repository.list(), hasLength(8));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
