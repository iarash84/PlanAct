import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/features/backup/application/backup_actions.dart';
import 'package:planact/features/backup/presentation/backup_settings_card.dart';

class Actions implements BackupActions {
  int exports = 0;
  int imports = 0;
  bool fail = false;
  Completer<bool>? pending;
  @override
  Future<bool> exportBackup() async {
    exports++;
    return _result();
  }

  @override
  Future<bool> importBackup() async {
    imports++;
    return _result();
  }

  Future<bool> _result() async {
    if (fail) throw StateError('test');
    return pending == null ? true : pending!.future;
  }
}

void main() {
  Future<void> mount(WidgetTester tester, Actions actions) => tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: SingleChildScrollView(
            child: BackupSettingsCard(actions: actions),
          ),
        ),
      ),
    ),
  );
  testWidgets(
    'export requires privacy confirmation and cancellation does nothing',
    (tester) async {
      final actions = Actions();
      await mount(tester, actions);
      await tester.tap(find.text('ذخیره نسخه پشتیبان'));
      await tester.pumpAndSettle();
      expect(actions.exports, 0);
      expect(
        find.textContaining('متن خام پیامک‌ها صادر نمی‌شود'),
        findsOneWidget,
      );
      await tester.tap(find.text('انصراف'));
      await tester.pumpAndSettle();
      expect(actions.exports, 0);
      await tester.tap(find.text('ذخیره نسخه پشتیبان'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تأیید ذخیره'));
      await tester.pumpAndSettle();
      expect(actions.exports, 1);
      expect(find.text('نسخه پشتیبان ذخیره شد.'), findsOneWidget);
    },
  );
  testWidgets('import loading disables actions and displays success', (
    tester,
  ) async {
    final actions = Actions()..pending = Completer<bool>();
    await mount(tester, actions);
    await tester.tap(find.text('بازیابی از فایل'));
    await tester.pumpAndSettle();
    expect(find.textContaining('تمام اطلاعات فعلی'), findsOneWidget);
    await tester.tap(find.text('تأیید بازیابی'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(
      tester
          .widget<ListTile>(find.widgetWithText(ListTile, 'بازیابی از فایل'))
          .enabled,
      false,
    );
    actions.pending!.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('اطلاعات با موفقیت بازیابی شد.'), findsOneWidget);
  });
  testWidgets('failure is visible and retry confirms again', (tester) async {
    final actions = Actions()..fail = true;
    await mount(tester, actions);
    await tester.tap(find.text('بازیابی از فایل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأیید بازیابی'));
    await tester.pumpAndSettle();
    expect(find.textContaining('عملیات انجام نشد'), findsOneWidget);
    await tester.ensureVisible(find.text('تلاش دوباره'));
    await tester.tap(find.text('تلاش دوباره'));
    await tester.pumpAndSettle();
    actions.fail = false;
    await tester.tap(find.text('تأیید بازیابی'));
    await tester.pumpAndSettle();
    expect(actions.imports, 2);
  });
}
