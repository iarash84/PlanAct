import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/features/finance/domain/finance.dart';

/// The supported entry points exposed by the global add action.
enum QuickAddAction { expense, income, transfer, commitment, note }

class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  static Future<QuickAddAction?> show(BuildContext context) =>
      showModalBottomSheet<QuickAddAction>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        builder: (_) => const QuickAddSheet(),
      );

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              planActL10n(context).commonQuickAdd,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _ActionTile(
              key: const ValueKey('quick-add-expense'),
              icon: Icons.remove_circle_outline,
              title: planActL10n(context).inboxPageBuildTitle3,
              subtitle: planActL10n(context).quickAddSheetBuildSubtitle,
              onTap: () => Navigator.pop(context, QuickAddAction.expense),
            ),
            _ActionTile(
              key: const ValueKey('quick-add-income'),
              icon: Icons.add_circle_outline,
              title: planActL10n(context).inboxPageBuildTitle4,
              subtitle: planActL10n(context).quickAddSheetBuildSubtitle2,
              onTap: () => Navigator.pop(context, QuickAddAction.income),
            ),
            _ActionTile(
              key: const ValueKey('quick-add-transfer'),
              icon: Icons.swap_horiz,
              title: planActL10n(context).smsReviewEditorBuildChildren5,
              subtitle: planActL10n(context).quickAddSheetBuildSubtitle3,
              onTap: () => Navigator.pop(context, QuickAddAction.transfer),
            ),
            _ActionTile(
              key: const ValueKey('quick-add-commitment'),
              icon: Icons.add_task,
              title: planActL10n(context).calendarPageMarkerPainterText,
              subtitle: planActL10n(context).quickAddSheetBuildSubtitle4,
              onTap: () => Navigator.pop(context, QuickAddAction.commitment),
            ),
            _ActionTile(
              key: const ValueKey('quick-add-note'),
              icon: Icons.note_alt_outlined,
              title: planActL10n(context).calendarNoteLabel,
              subtitle: planActL10n(context).calendarNoteAddSubtitle,
              onTap: () => Navigator.pop(context, QuickAddAction.note),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    onTap: onTap,
  );
}

class QuickFinancialEntrySheet extends StatefulWidget {
  const QuickFinancialEntrySheet({
    super.key,
    required this.accounts,
    required this.income,
    this.tagRepository,
    this.onSave,
  });
  final TagRepository? tagRepository;
  final Future<void> Function(QuickFinancialEntry entry)? onSave;
  final List<FinancialAccount> accounts;
  final bool income;

  @override
  State<QuickFinancialEntrySheet> createState() =>
      _QuickFinancialEntrySheetState();
}

class _QuickFinancialEntrySheetState extends State<QuickFinancialEntrySheet> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  }

  PinnedMoneyInput? _pinned;
  PinnedMoneyInput get _moneyInput =>
      _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late FinancialAccount _account = widget.accounts.first;
  String? _error;
  bool _saving = false;
  Set<String> _tags = {};
  bool _moreOptions = false;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String _dateLabel(BuildContext context) => _selectedDate == null
      ? planActL10n(context).quickFinancialCurrentDate
      : PersianDateFormatter.date(JalaliDate.fromDateTime(_selectedDate!));

  String _timeLabel(BuildContext context) => _selectedTime == null
      ? planActL10n(context).quickFinancialCurrentTime
      : PersianNumbers.format(
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        );

  Future<void> _pickDate() async {
    final selected = await showDialog<DateTime>(
      context: context,
      builder: (_) =>
          PlanActJalaliDatePicker(initialDate: _selectedDate ?? DateTime.now()),
    );
    if (mounted && selected != null) {
      setState(() => _selectedDate = selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (mounted && selected != null) {
      setState(() => _selectedTime = selected);
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = _moneyInput.parse(_amount.text, currency: _account.currency);
    if (amount == null || amount <= 0) {
      setState(() => _error = PersianCopy.financePageResultOnPrimary2);
      return;
    }
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final entry = QuickFinancialEntry(
      account: _account,
      amount: amount,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      income: widget.income,
      tags: Set.unmodifiable(_tags),
      selectedDate: _selectedDate,
      selectedTime: _selectedTime,
    );
    try {
      await widget.onSave?.call(entry);
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context, widget.onSave == null ? entry : null);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = PersianCopy.quickAddSheetSubmitMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: PlanActFormSheet(
      title: widget.income
          ? planActL10n(context).quickAddSheetBuildTitle
          : planActL10n(context).quickAddSheetBuildTitle2,
      primaryLabel: planActL10n(context).financePageResultPrimaryLabel,
      onPrimary: _submit,
      isLoading: _saving,
      error: _error,
      primaryKey: const ValueKey('quick-financial-save'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('quick-financial-amount'),
            controller: _amount,
            enabled: !_saving,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: const [MoneyInputFormatter(decimal: true)],

            decoration: InputDecoration(
              labelText: planActL10n(context).financePageResultLabelText(
                (_moneyInput.label(_account.currency)).toString(),
              ),
            ),
          ),
          const SizedBox(height: PlanActSpacing.sm),
          DropdownButtonFormField<FinancialAccount>(
            key: const ValueKey('quick-financial-account'),
            initialValue: _account,
            decoration: InputDecoration(
              labelText: planActL10n(context).quickAddSheetBuildLabelText,
            ),
            items: widget.accounts
                .map(
                  (account) => DropdownMenuItem(
                    value: account,
                    child: Text(account.name),
                  ),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() => _account = value ?? _account),
          ),
          const SizedBox(height: PlanActSpacing.sm),
          TextField(
            key: const ValueKey('quick-financial-note'),
            controller: _note,
            enabled: !_saving,
            decoration: InputDecoration(
              labelText: widget.income
                  ? planActL10n(context).quickAddSheetBuildLabelText2
                  : planActL10n(context).quickAddSheetBuildLabelText3,
            ),
          ),
          const SizedBox(height: PlanActSpacing.sm),
          DraftTagPicker(
            repository: widget.tagRepository,
            selected: _tags,
            enabled: !_saving,
            onChanged: (tags) => setState(() => _tags = tags),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey('quick-financial-more-options'),
              onPressed: _saving
                  ? null
                  : () => setState(() => _moreOptions = !_moreOptions),
              child: Semantics(
                expanded: _moreOptions,
                child: Text(
                  _moreOptions
                      ? planActL10n(context).quickFinancialLessOptions
                      : planActL10n(context).planactAppBuildTooltip,
                ),
              ),
            ),
          ),
          if (_selectedDate != null || _selectedTime != null)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text('${_dateLabel(context)}، ${_timeLabel(context)}'),
            ),
          AnimatedSize(
            duration: PlanActMotion.duration(context),
            curve: PlanActMotion.curve,
            alignment: AlignmentDirectional.topStart,
            child: !_moreOptions
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        key: const ValueKey('quick-financial-date'),
                        onPressed: _saving ? null : _pickDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(_dateLabel(context)),
                      ),
                      const SizedBox(height: PlanActSpacing.sm),
                      OutlinedButton.icon(
                        key: const ValueKey('quick-financial-time'),
                        onPressed: _saving ? null : _pickTime,
                        icon: const Icon(Icons.schedule_outlined),
                        label: Text(_timeLabel(context)),
                      ),
                      if (_selectedDate != null || _selectedTime != null)
                        TextButton(
                          key: const ValueKey('quick-financial-reset-time'),
                          onPressed: _saving
                              ? null
                              : () => setState(() {
                                  _selectedDate = null;
                                  _selectedTime = null;
                                }),
                          child: Text(
                            planActL10n(context).quickFinancialResetTime,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

class QuickFinancialEntry {
  const QuickFinancialEntry({
    required this.account,
    required this.amount,
    required this.note,
    required this.income,
    this.tags = const {},
    this.selectedDate,
    this.selectedTime,
  });
  final FinancialAccount account;
  final int amount;
  final String? note;
  final bool income;
  final Set<String> tags;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;

  DateTime resolveOccurredAt(DateTime now) {
    if (selectedDate == null && selectedTime == null) return now;
    final date = selectedDate ?? now;
    return DateTime(
      date.year,
      date.month,
      date.day,
      selectedTime?.hour ?? now.hour,
      selectedTime?.minute ?? now.minute,
      selectedTime == null ? now.second : 0,
      selectedTime == null ? now.millisecond : 0,
      selectedTime == null ? now.microsecond : 0,
    );
  }
}

class QuickTransferSheet extends StatefulWidget {
  const QuickTransferSheet({super.key, required this.accounts});
  final List<FinancialAccount> accounts;

  @override
  State<QuickTransferSheet> createState() => _QuickTransferSheetState();
}

class _QuickTransferSheetState extends State<QuickTransferSheet> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  }

  PinnedMoneyInput? _pinned;
  PinnedMoneyInput get _moneyInput =>
      _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  final _amount = TextEditingController();
  late FinancialAccount _from = widget.accounts.first;
  late FinancialAccount _to = widget.accounts.length > 1
      ? widget.accounts[1]
      : widget.accounts.first;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = _moneyInput.parse(_amount.text, currency: _from.currency);
    if (amount == null || amount <= 0) {
      setState(() => _error = PersianCopy.financePageResultOnPrimary2);
      return;
    }
    if (_from.id == _to.id) {
      setState(() => _error = PersianCopy.quickAddSheetSubmitMessage2);
      return;
    }
    if (_saving) return;
    setState(() => _saving = true);
    Navigator.pop(context, QuickTransfer(from: _from, to: _to, amount: amount));
  }

  @override
  Widget build(BuildContext context) => PlanActFormSheet(
    title: planActL10n(context).quickAddSheetBuildTitle3,
    primaryLabel: planActL10n(context).quickAddSheetBuildPrimaryLabel,
    onPrimary: _submit,
    isLoading: _saving,
    error: _error,
    primaryKey: const ValueKey('quick-transfer-save'),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [MoneyInputFormatter(decimal: true)],

          decoration: InputDecoration(
            labelText: planActL10n(context).financePageResultLabelText(
              (_moneyInput.label(_from.currency)).toString(),
            ),
          ),
        ),
        const SizedBox(height: PlanActSpacing.sm),
        DropdownButtonFormField<FinancialAccount>(
          initialValue: _from,
          decoration: InputDecoration(
            labelText: planActL10n(context).quickAddSheetBuildLabelText4,
          ),
          items: widget.accounts
              .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
              .toList(),
          onChanged: (v) => setState(() => _from = v ?? _from),
        ),
        const SizedBox(height: PlanActSpacing.sm),
        DropdownButtonFormField<FinancialAccount>(
          initialValue: _to,
          decoration: InputDecoration(
            labelText: planActL10n(context).quickAddSheetBuildLabelText5,
          ),
          items: widget.accounts
              .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
              .toList(),
          onChanged: (v) => setState(() => _to = v ?? _to),
        ),
      ],
    ),
  );
}

class QuickTransfer {
  const QuickTransfer({
    required this.from,
    required this.to,
    required this.amount,
  });
  final FinancialAccount from;
  final FinancialAccount to;
  final int amount;
}
