import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/presentation/undo_feedback.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';

class MatchCorrectionSheet extends StatefulWidget {
  const MatchCorrectionSheet({
    super.key,
    required this.flow,
    required this.data,
    required this.original,
  });
  final ContextualReconciliation flow;
  final TransactionRelationshipContext data;
  final TransactionMatch original;
  @override
  State<MatchCorrectionSheet> createState() => _MatchCorrectionSheetState();
}

class _MatchCorrectionSheetState extends State<MatchCorrectionSheet> {
  PinnedMoneyInput? _money;
  final List<TextEditingController> _amounts = [];
  late final List<StableId> _targets = widget.original.allocations
      .map((a) => a.occurrenceId)
      .toList();
  bool _saving = false;
  String? _error;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_money != null) return;
    _money = PinnedMoneyInput(MoneyUnitScope.of(context));
    for (final a in widget.original.allocations) {
      _amounts.add(
        TextEditingController(
          text: _money!.inputText(
            a.amount.minorUnits,
            currency: a.amount.currency,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _amounts) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (widget.original.allocations.any(
      (a) => a.type != AllocationType.payment,
    )) {
      setState(() => _error = planActL10n(context).undoConflict);
      return;
    }
    final values = _amounts
        .map(
          (c) => _money!.parse(
            c.text,
            currency: widget.original.transactionAmount.currency,
          ),
        )
        .toList();
    if (values.any((v) => v == null || v <= 0) ||
        values.fold<int>(0, (sum, v) => sum + (v ?? 0)) >
            widget.data.available.minorUnits +
                widget.original.allocatedMinorUnits) {
      setState(
        () =>
            _error = planActL10n(context)
                .transactionRelationshipPageSaveMessage,
      );
      return;
    }
    if (!await confirmRecordedAction(
          context,
          planActL10n(context).matchCorrectMessage,
        ) ||
        !mounted) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.flow.correctMatch(
        original: widget.original,
        occurrenceIds: _targets,
        allocations: [
          for (final v in values)
            Money(
              minorUnits: v!,
              currency: widget.original.transactionAmount.currency,
            ),
        ],
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = planActL10n(context).undoConflict;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: PlanActFormSheet(
      title: planActL10n(context).matchCorrectAction,
      primaryLabel: planActL10n(context).commonSave,
      isLoading: _saving,
      error: _error,
      onPrimary: _save,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _targets.length; i++) ...[
            DropdownButtonFormField<StableId>(
              initialValue: _targets[i],
              isExpanded: true,
              decoration: InputDecoration(
                labelText: planActL10n(context).matchTargetLabel,
              ),
              items: [
                for (final target in widget.data.targets)
                  DropdownMenuItem(
                    value: target.occurrence.id,
                    child: Text(
                      '${target.commitment.title} · ${_date(target.occurrence.currentScheduledAt)}',
                    ),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (id) {
                      if (id != null) setState(() => _targets[i] = id);
                    },
            ),
            TextField(
              controller: _amounts[i],
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: const [MoneyInputFormatter(decimal: true)],
              decoration: InputDecoration(
                labelText:
                    '${planActL10n(context).matchAmountLabel} (${_money!.label(widget.original.transactionAmount.currency)})',
              ),
            ),
            const SizedBox(height: PlanActSpacing.md),
          ],
        ],
      ),
    ),
  );

  String _date(Object value) {
    final date = value is LocalDate
        ? DateTime(value.year, value.month, value.day)
        : (value as DateTime).toLocal();
    final jalali = JalaliDate.fromDateTime(date);
    return '${PersianDateFormatter.date(jalali)} ${PersianNumbers.format(jalali.year)}'
        '${value is DateTime ? ' · ${PersianNumbers.format(date.hour.toString().padLeft(2, '0'))}:${PersianNumbers.format(date.minute.toString().padLeft(2, '0'))}' : ''}';
  }
}
