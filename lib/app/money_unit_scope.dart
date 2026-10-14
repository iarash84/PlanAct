import 'package:planact/core/money/money_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/core/money/iranian_money_unit.dart';
export 'package:planact/core/money/iranian_money_unit.dart';

class MoneyUnitController extends ValueNotifier<IranianMoneyUnit> {
  MoneyUnitController(this.settings) : super(IranianMoneyUnit.rial) {
    ready = settings == null;
  }
  final AppSettings? settings;
  bool ready = false;
  bool saving = false;
  Future<void> load() async {
    value = await settings?.readMoneyUnit() ?? IranianMoneyUnit.rial;
    ready = true;
    notifyListeners();
  }

  Future<void> select(IranianMoneyUnit unit) async {
    if (!ready || saving) throw StateError('Money preference unavailable');
    saving = true;
    notifyListeners();
    try {
      if (settings == null) throw StateError('Persistent settings unavailable');
      await settings!.writeMoneyUnit(unit);
      value = unit;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}

class MoneyUnitScope extends InheritedNotifier<MoneyUnitController> {
  const MoneyUnitScope({
    super.key,
    required MoneyUnitController controller,
    required super.child,
  }) : super(notifier: controller);
  static MoneyUnitController? controllerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MoneyUnitScope>()?.notifier;
  static IranianMoneyUnit of(BuildContext context) =>
      controllerOf(context)?.value ?? IranianMoneyUnit.rial;
}

/// A form snapshots this once; rebuilding does not reinterpret its text.
class PinnedMoneyInput {
  PinnedMoneyInput(this.unit);
  final IranianMoneyUnit unit;
  String label(String currency) =>
      currency.trim().toUpperCase() == 'IRR' ? unit.label : currency;
  int? parse(String text, {String currency = 'IRR'}) =>
      (currency.trim().toUpperCase() == 'IRR' ? unit : IranianMoneyUnit.rial)
          .parse(text);
  String inputText(int value, {String currency = 'IRR'}) =>
      MoneyInputFormatter.groupText(
        (currency.trim().toUpperCase() == 'IRR' ? unit : IranianMoneyUnit.rial)
            .inputText(value),
      );
}
