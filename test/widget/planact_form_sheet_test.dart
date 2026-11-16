import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';

void main() {
  for (final dark in [false, true]) {
    for (final height in [800.0, 360.0]) {
      for (final keyboard in [0.0, 180.0]) {
        testWidgets(
          'form error/actions retain draft dark=$dark height=$height keyboard=$keyboard',
          (tester) async {
            tester.view.physicalSize = Size(320, height);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final controller = TextEditingController(text: 'پیش‌نویس');
            addTearDown(controller.dispose);
            var saves = 0;
            var cancels = 0;
            const primary = ValueKey('save');
            const field = ValueKey('draft');
            final error = List.filled(
              15,
              'ذخیره نشد؛ دوباره تلاش کنید.',
            ).join(' ');
            var showError = false;
            late StateSetter update;
            await tester.pumpWidget(
              MaterialApp(
                theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(320, height),
                    textScaler: TextScaler.linear(2),
                    viewInsets: EdgeInsets.only(bottom: keyboard),
                  ),
                  child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Align(
                      alignment: Alignment.bottomCenter,
                      child: StatefulBuilder(
                        builder: (context, setState) {
                          update = setState;
                          return PlanActFormSheet(
                            title: 'بررسی و تأیید پیش‌نویس',
                            showDragHandle: true,
                            error: showError ? error : null,
                            primaryKey: primary,
                            primaryLabel: 'تأیید و ذخیرهٔ پیش‌نویس',
                            secondaryLabel: 'انصراف و بازگشت',
                            onPrimary: () => saves++,
                            onSecondary: () => cancels++,
                            child: TextFormField(
                              key: field,
                              controller: controller,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await tester.ensureVisible(find.byKey(field));
            await tester.enterText(find.byKey(field), 'پیش‌نویس ویرایش‌شده');
            update(() => showError = true);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            final errorFinder = find.byKey(
              const ValueKey('planact-form-error'),
            );
            await tester.ensureVisible(errorFinder);
            await tester.pumpAndSettle();
            expect(
              tester
                  .widget<Semantics>(
                    find
                        .ancestor(
                          of: errorFinder,
                          matching: find.byType(Semantics),
                        )
                        .first,
                  )
                  .properties
                  .liveRegion,
              isTrue,
            );
            await tester.ensureVisible(find.byKey(field));
            await tester.pumpAndSettle();
            expect(controller.text, 'پیش‌نویس ویرایش‌شده');
            final save = find.byKey(primary);
            await tester.ensureVisible(save);
            await tester.pumpAndSettle();
            expect(
              tester.getRect(save).bottom,
              lessThanOrEqualTo(height - keyboard),
            );
            expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
            await tester.tap(save);
            final cancel = find.byType(OutlinedButton);
            await tester.ensureVisible(cancel);
            await tester.pumpAndSettle();
            expect(tester.getSize(cancel).height, greaterThanOrEqualTo(48));
            await tester.tap(cancel);
            expect(saves, 1);
            expect(cancels, 1);
            expect(controller.text, 'پیش‌نویس ویرایش‌شده');
            expect(tester.takeException(), isNull);
          },
        );
      }
    }

    testWidgets(
      'normal form keeps actions pinned and loading disables them $dark',
      (tester) async {
        var loading = false;
        late StateSetter update;
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  update = setState;
                  return PlanActFormSheet(
                    title: 'عنوان',
                    isLoading: loading,
                    onPrimary: () {},
                    onSecondary: () {},
                    child: const SizedBox(height: 1200, child: Text('محتوا')),
                  );
                },
              ),
            ),
          ),
        );
        final button = find.byType(FilledButton);
        final before = tester.getRect(button);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
        expect(tester.getRect(button), before);
        update(() => loading = true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.widget<FilledButton>(button).onPressed, isNull);
        expect(
          tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
          isNull,
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
