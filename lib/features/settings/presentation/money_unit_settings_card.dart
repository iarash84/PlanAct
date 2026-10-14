import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';

class MoneyUnitSettingsCard extends StatefulWidget {
  const MoneyUnitSettingsCard({super.key});
  @override
  State<MoneyUnitSettingsCard> createState() => _MoneyUnitSettingsCardState();
}

class _MoneyUnitSettingsCardState extends State<MoneyUnitSettingsCard> {
  String? _error;
  Future<void> _select(
    MoneyUnitController controller,
    IranianMoneyUnit unit,
  ) async {
    setState(() => _error = null);
    try {
      await controller.select(unit);
    } catch (_) {
      if (mounted) {
        setState(() => _error = PersianCopy.moneyUnitSettingsCardSelectMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = MoneyUnitScope.controllerOf(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              planActL10n(context).moneyUnitSettingsCardBuildChildren,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(planActL10n(context).moneyUnitSettingsCardBuildChildren2),
            const SizedBox(height: 12),
            SegmentedButton<IranianMoneyUnit>(
              segments: [
                ButtonSegment(
                  value: IranianMoneyUnit.rial,
                  label: Text(planActL10n(context).currencyRial),
                ),
                ButtonSegment(
                  value: IranianMoneyUnit.toman,
                  label: Text(planActL10n(context).currencyToman),
                ),
              ],
              selected: {controller?.value ?? IranianMoneyUnit.rial},
              onSelectionChanged:
                  controller == null || !controller.ready || controller.saving
                  ? null
                  : (units) => _select(controller, units.first),
            ),
            if (controller?.saving ?? false) const LinearProgressIndicator(),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
