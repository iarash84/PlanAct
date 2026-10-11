import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/settings/presentation/money_unit_settings_card.dart';

void main() {
  testWidgets(
    'failed settings write keeps effective unit and offers retry feedback',
    (tester) async {
      final database = AppDatabase.forTesting(NativeDatabase.memory());
      final controller = MoneyUnitController(AppSettings(database));
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) =>
              MoneyUnitScope(controller: controller, child: child!),
          home: const Scaffold(body: MoneyUnitSettingsCard()),
        ),
      );
      await database.close();
      await tester.tap(find.text('تومان'));
      await tester.pumpAndSettle();
      expect(controller.value, IranianMoneyUnit.rial);
      expect(controller.saving, isFalse);
      expect(
        find.text('ذخیرهٔ واحد پول انجام نشد؛ دوباره انتخاب کنید.'),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
