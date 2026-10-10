import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/backup/presentation/recovery_key_dialogs.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'key acknowledgement and cancellation ${dark ? 'dark' : 'light'} RTL large text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        bool? result;
        final clipboardWrites = <Object?>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              clipboardWrites.add(call.arguments);
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: dark ? PlanActTheme.dark() : PlanActTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              ),
            ),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Builder(
                builder: (context) => Scaffold(
                  body: TextButton(
                    onPressed: () async {
                      result = await confirmRecoveryKey(
                        context,
                        'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        final warning = find.textContaining('اگر کلید گم شود');
        expect(warning, findsOneWidget);
        final warningContext = tester.element(warning);
        expect(
          tester.widget<Text>(warning).style,
          Theme.of(warningContext).textTheme.titleLarge,
        );
        expect(tester.widget<Text>(warning).style!.fontWeight, FontWeight.w700);
        expect(clipboardWrites, isEmpty);
        expect(find.textContaining('کلیپ‌بورد'), findsOneWidget);
        final copy = find.widgetWithText(OutlinedButton, 'کپی کلید');
        await tester.ensureVisible(copy);
        await tester.pumpAndSettle();
        expect(Directionality.of(tester.element(copy)), TextDirection.rtl);
        expect(tester.getSize(copy).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(copy).width, greaterThanOrEqualTo(48));
        await tester.tap(copy);
        await tester.pumpAndSettle();
        expect(clipboardWrites, [
          {'text': 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA='},
        ]);
        expect(find.text('کلید کپی شد.'), findsOneWidget);
        expect(
          tester.widget<CheckboxListTile>(find.byType(CheckboxListTile)).value,
          false,
        );
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await tester.ensureVisible(find.byType(CheckboxListTile));
        await tester.tap(find.byType(CheckboxListTile));
        await tester.pump();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
        await tester.tap(find.text('ادامه و ذخیره فایل'));
        await tester.pumpAndSettle();
        expect(result, true);
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNull,
        );
        await tester.tap(find.text('انصراف'));
        await tester.pumpAndSettle();
        expect(result, false);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final dismissWhilePending in [false, true]) {
    testWidgets(
      'copy prevents duplicates and ${dismissWhilePending ? 'ignores disposed completion' : 'reports failure and retries'}',
      (tester) async {
        const key = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=';
        final pending = Completer<Object?>();
        var writes = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method != 'Clipboard.setData') return null;
            expect(call.arguments, {'text': key});
            writes++;
            if (writes == 1) return pending.future;
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: PlanActTheme.light(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => confirmRecoveryKey(context, key),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(writes, 0);
        final copy = find.widgetWithText(OutlinedButton, 'کپی کلید');
        await tester.ensureVisible(copy);
        await tester.pumpAndSettle();
        final callback = tester.widget<OutlinedButton>(copy).onPressed!;
        callback();
        callback();
        await tester.pump();
        expect(writes, 1);
        expect(tester.widget<OutlinedButton>(copy).onPressed, isNull);
        expect(find.text('در حال کپی کلید…'), findsOneWidget);
        if (dismissWhilePending) {
          await tester.tap(find.text('انصراف'));
          await tester.pumpAndSettle();
        }
        pending.completeError(PlatformException(code: 'unavailable'));
        await tester.pumpAndSettle();
        if (dismissWhilePending) {
          expect(find.byType(AlertDialog), findsNothing);
          expect(
            find.text('کپی کلید انجام نشد. دوباره تلاش کنید.'),
            findsNothing,
          );
        } else {
          expect(
            find.text('کپی کلید انجام نشد. دوباره تلاش کنید.'),
            findsOneWidget,
          );
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull,
          );
          await tester.ensureVisible(copy);
          await tester.tap(copy);
          await tester.pumpAndSettle();
          expect(writes, 2);
          expect(find.text('کلید کپی شد.'), findsOneWidget);
          expect(
            tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
            isNull,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('input validates key and legacy warning is explicit', (
    tester,
  ) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () async {
                    result = await requestRecoveryKey(context);
                  },
                  child: const Text('key'),
                ),
                TextButton(
                  onPressed: () => confirmLegacyBackup(context),
                  child: const Text('legacy'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('key'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'wrong');
    await tester.tap(find.text('بازیابی با این کلید'));
    await tester.pumpAndSettle();
    expect(find.text('کلید کامل و دقیق را وارد کنید.'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
    );
    await tester.tap(find.text('بازیابی با این کلید'));
    await tester.pumpAndSettle();
    expect(result, 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=');
    await tester.tap(find.text('legacy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('فایل قدیمی بازنویسی نمی‌شود'), findsOneWidget);
    await tester.tap(find.text('انصراف'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
