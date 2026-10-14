import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

class TransactionRelationshipPage extends StatefulWidget {
  const TransactionRelationshipPage({
    super.key,
    required this.transactionId,
    required this.flow,
    this.onOpenQueue,
  });
  final StableId transactionId;
  final ContextualReconciliation flow;
  final Future<void> Function()? onOpenQueue;
  @override
  State<TransactionRelationshipPage> createState() =>
      _TransactionRelationshipPageState();
}

class _TransactionRelationshipPageState
    extends State<TransactionRelationshipPage> {
  TransactionRelationshipContext? _context;
  StableId? _selected;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  }

  PinnedMoneyInput? _pinned;
  PinnedMoneyInput get _moneyInput =>
      _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  final _amount = TextEditingController();
  String _query = '';
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _leaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.flow.load(widget.transactionId);
      if (mounted) {
        setState(() {
          _context = result;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = PersianCopy.transactionRelationshipPageLoadMessage;
        });
      }
    }
  }

  Future<void> _save() async {
    final amount = _moneyInput.parse(
      _amount.text,
      currency: _context!.transaction.amount.currency,
    );
    if (_selected == null ||
        amount == null ||
        amount <= 0 ||
        amount > _context!.available.minorUnits) {
      setState(
        () => _error = PersianCopy.transactionRelationshipPageSaveMessage,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.flow.confirm(
        transactionId: widget.transactionId,
        occurrenceId: _selected!,
        minorUnits: amount,
        expectedReview: _context!.review,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        setState(() => _saving = false);
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = PersianCopy.transactionRelationshipPageSaveMessage2;
        });
      }
    }
  }

  Future<void> _decide({
    required bool independent,
    RelationshipReview? expected,
  }) async {
    if (_saving) return;
    final snapshot = expected ?? _context?.review;
    if (snapshot == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final review = independent
          ? await widget.flow.markIndependent(expected: snapshot)
          : await widget.flow.reopen(expected: snapshot);
      if (!mounted) return;
      final previous = _context!;
      setState(() {
        _saving = false;
        _dirty = true;
        _context = TransactionRelationshipContext(
          transaction: previous.transaction,
          account: previous.account,
          available: previous.available,
          targets: previous.targets,
          review: review,
        );
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              independent
                  ? PersianCopy.transactionRelationshipPageDecideContent
                  : PersianCopy.transactionRelationshipPageDecideContent2,
            ),
            action: SnackBarAction(
              label: PersianCopy.inboxPageRejectLabel,
              onPressed: () =>
                  _decide(independent: !independent, expected: review),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = PersianCopy.transactionRelationshipPageDecideMessage;
      });
    }
  }

  Future<void> _back() async {
    if (_saving || _leaving) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    setState(() => _leaving = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop(_dirty ? true : null);
  }

  String _date(RelationshipTarget target) {
    final value = target.occurrence.currentScheduledAt;
    final date = value is DateTime
        ? value.toLocal()
        : value is LocalDate
        ? DateTime(value.year, value.month, value.day)
        : null;
    if (date == null) return PersianCopy.transactionRelationshipPageDateMessage;
    final jalali = JalaliDate.fromDateTime(date);
    final label =
        '${PersianDateFormatter.date(jalali)} ${PersianNumbers.format(jalali.year)}';
    return value is DateTime
        ? '$label · ${PersianNumbers.format(date.hour.toString().padLeft(2, '0'))}:${PersianNumbers.format(date.minute.toString().padLeft(2, '0'))}'
        : label;
  }

  @override
  Widget build(BuildContext context) {
    final data = _context;
    final targets =
        data?.targets
            .where((t) => t.commitment.title.contains(_query))
            .toList() ??
        <RelationshipTarget>[];
    return PopScope(
      canPop: !_saving && (!_dirty || _leaving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_saving) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            planActL10n(context).transactionRelationshipPageBuildTitle,
          ),
          leading: Navigator.of(context).canPop()
              ? BackButton(onPressed: _saving ? null : _back)
              : null,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(PlanActSpacing.lg),
                children: [
                  if (widget.onOpenQueue != null)
                    OutlinedButton.icon(
                      onPressed: _saving
                          ? null
                          : () async {
                              await widget.onOpenQueue!();
                              if (mounted) {
                                _dirty = true;
                                await _load();
                              }
                            },
                      icon: const Icon(Icons.playlist_add_check),
                      label: Text(
                        planActL10n(context).relationshipQueuePageBuildTitle,
                      ),
                    ),
                  if (data != null) ...[
                    Text(
                      data.transaction.note ??
                          planActL10n(context)
                              .relationshipQueuePageBuildSemanticLabel,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      planActL10n(context)
                          .transactionRelationshipPageBuildChildren(
                            (PersianMoneyText.money(
                              data.transaction.amount,
                              unit: MoneyUnitScope.of(context),
                            )).toString(),
                          ),
                    ),
                    Text(
                      planActL10n(
                        context,
                      ).transactionRelationshipPageBuildChildren3(
                        (data.account?.name ??
                                planActL10n(context)
                                    .transactionRelationshipPageBuildChildren2)
                            .toString(),
                      ),
                    ),
                    Text(
                      planActL10n(context)
                          .transactionRelationshipPageBuildChildren4(
                            (PersianMoneyText.money(
                              data.available,
                              unit: MoneyUnitScope.of(context),
                            )).toString(),
                          ),
                    ),
                    const SizedBox(height: PlanActSpacing.lg),
                    if (data.review?.isIndependent == true) ...[
                      Text(
                        planActL10n(context)
                            .transactionRelationshipPageBuildChildren5,
                      ),
                      Text(
                        planActL10n(context)
                            .transactionRelationshipPageBuildChildren6,
                      ),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => _decide(independent: false),
                        child: Text(
                          planActL10n(context)
                              .relationshipQueuePageBuildChildren11,
                        ),
                      ),
                    ] else if (data.review != null &&
                        data.available.minorUnits > 0) ...[
                      Text(
                        planActL10n(context)
                            .transactionRelationshipPageBuildChildren7,
                      ),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => _decide(independent: true),
                        child: Text(
                          planActL10n(context)
                              .transactionRelationshipPageBuildChildren8,
                        ),
                      ),
                    ],
                    if (_saving) ...[
                      const LinearProgressIndicator(),
                      Text(
                        planActL10n(context)
                            .transactionRelationshipPageBuildChildren9,
                      ),
                    ],
                    if (data.review?.isIndependent != true) ...[
                      Text(
                        planActL10n(context)
                            .transactionRelationshipPageBuildChildren10,
                      ),
                      TextField(
                        decoration: InputDecoration(
                          labelText: planActL10n(context)
                              .transactionRelationshipPageBuildLabelText,
                        ),
                        enabled: !_saving,
                        onChanged: (v) => setState(() => _query = v.trim()),
                      ),
                      if (data.targets.isEmpty)
                        Text(
                          planActL10n(context)
                              .transactionRelationshipPageBuildChildren11,
                        ),
                      if (data.targets.isNotEmpty && targets.isEmpty)
                        Text(
                          planActL10n(context)
                              .transactionRelationshipPageBuildChildren12,
                        ),
                      for (final target in targets)
                        ListTile(
                          selected: _selected == target.occurrence.id,
                          leading: Icon(
                            _selected == target.occurrence.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                          ),
                          title: Text(target.commitment.title),
                          subtitle: Text(
                            planActL10n(
                              context,
                            ).weekTimelineViewAgendaDelegate2(
                              (_date(target)).toString(),
                              (target.commitment.status ==
                                          CommitmentStatus.archived
                                      ? planActL10n(
                                          context,
                                        ).transactionRelationshipPageBuildSubtitle
                                      : '')
                                  .toString(),
                            ),
                          ),
                          onTap: _saving || data.available.minorUnits == 0
                              ? null
                              : () => setState(
                                  () => _selected = target.occurrence.id,
                                ),
                        ),
                      TextField(
                        controller: _amount,
                        enabled: !_saving && data.available.minorUnits > 0,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: const [
                          MoneyInputFormatter(decimal: true),
                        ],
                        decoration: InputDecoration(
                          labelText: planActL10n(context)
                              .transactionRelationshipPageBuildLabelText2(
                                (_moneyInput.label(
                                  data.transaction.amount.currency,
                                )).toString(),
                              ),
                        ),
                      ),
                      const SizedBox(height: PlanActSpacing.md),
                      FilledButton(
                        onPressed: _saving || data.available.minorUnits == 0
                            ? null
                            : _save,
                        child: Text(
                          _saving
                              ? planActL10n(context)
                                    .transactionRelationshipPageBuildChildren9
                              : planActL10n(context)
                                    .transactionRelationshipPageBuildChildren13,
                        ),
                      ),
                    ],
                    if (data.available.minorUnits == 0)
                      Text(
                        planActL10n(context)
                            .transactionRelationshipPageBuildChildren14,
                      ),
                  ],
                  if (_error != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  TextButton(
                    onPressed: _saving ? null : _load,
                    child: Text(planActL10n(context).inboxPageBuildTooltip),
                  ),
                ],
              ),
      ),
    );
  }
}
