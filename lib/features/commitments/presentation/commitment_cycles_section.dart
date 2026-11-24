import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';
import 'package:planact/features/commitments/application/commitment_cycles.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/domain/commitment_cycle.dart';

/// Selection is transient; the available cycles and command tokens are durable.
class CommitmentCyclesSection extends StatefulWidget {
  const CommitmentCyclesSection({
    super.key,
    required this.owner,
    required this.repository,
    required this.create,
    required this.revision,
    required this.onSelected,
    required this.onSaved,
  });
  final Commitment owner;
  final CommitmentCyclesRepository repository;
  final CreateCommitmentPlan create;
  final int revision;
  final ValueChanged<CommitmentPlan?> onSelected;
  final Future<void> Function() onSaved;

  @override
  State<CommitmentCyclesSection> createState() =>
      _CommitmentCyclesSectionState();
}

class _CommitmentCyclesSectionState extends State<CommitmentCyclesSection> {
  List<CommitmentPlan> _plans = const [];
  StableId? _selected;
  bool _loading = true;
  bool _busy = false;
  bool _error = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CommitmentCyclesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision ||
        oldWidget.repository != widget.repository) {
      _load();
    }
  }

  Future<void> _load({StableId? select}) async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final plans = await widget.repository.listByCommitmentId(widget.owner.id);
      if (!mounted || request != _request) return;
      final wanted = select ?? _selected;
      final selected =
          plans.where((p) => p.cycle.id == wanted).firstOrNull ??
          plans
              .where((p) => p.cycle.status == CommitmentCycleStatus.active)
              .firstOrNull ??
          plans.lastOrNull;
      setState(() {
        _plans = plans;
        _selected = selected?.cycle.id;
        _loading = false;
      });
      widget.onSelected(selected);
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = true;
      });
      // Never leave stale actionable content behind a failed cycle refresh.
      widget.onSelected(null);
    }
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _finish(CommitmentPlan plan) async {
    setState(() => _busy = true);
    try {
      // Pin before opening the dialog, never regenerate a token at confirmation.
      final token = await widget.repository.cycleSetToken(widget.owner.id);
      if (!mounted) return;
      final date = await showDialog<DateTime>(
        context: context,
        builder: (_) => _CompleteCycleDialog(
          initialDate: plan.cycle.startDate.toLocal(),
          onConfirm: (date) => widget.repository.completeCycle(
            cycleId: plan.cycle.id,
            expectedCycleSet: token,
            completedAt: date,
          ),
        ),
      );
      if (date == null || !mounted) return;
      await _afterCommit();
    } catch (_) {
      if (mounted) _message(planActL10n(context).cycleFailure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _afterCommit({StableId? select}) async {
    // A refresh failure after commit must not invite a duplicate write.
    try {
      await widget.onSaved();
    } catch (_) {
      if (mounted) _message(planActL10n(context).undoRefreshPending);
    }
    if (mounted) await _load(select: select);
  }

  Future<void> _next() async {
    setState(() => _busy = true);
    try {
      final token = await widget.repository.cycleSetToken(widget.owner.id);
      if (!mounted) return;
      final contextToken = NewCommitmentCycleContext(
        commitmentId: widget.owner.id,
        expectedCycleSet: token,
      );
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => QuickCaptureSheet(
          cycleOwner: widget.owner,
          onSave: (CommitmentDraft draft) async {
            final plan = await widget.create(
              title: widget.owner.title,
              newCycle: contextToken,
              startAt: draft.scheduledDates.first,
              frequency: draft.frequency,
              recurrenceCalendar: draft.recurrenceCalendar,
              weekdays: draft.weekdays,
              occurrenceCount: draft.termination == RecurrenceTermination.count
                  ? draft.occurrenceCount
                  : null,
              endDate: draft.termination == RecurrenceTermination.endDate
                  ? draft.endDate
                  : null,
              reminderOffsets: draft.reminderOffsets,
              reminderDelivery: draft.reminderDelivery,
              financialDirection: draft.financialMeaning.expectationDirection,
              financialAmount: draft.financialAmount,
              financialAccountId: draft.financialAccountId,
            );
            if (mounted) {
              if (plan.reminderDeliveryPending) {
                _message(
                  planActL10n(context).planactAppSaveCapturedCommitmentMessage2,
                );
              }
              await _afterCommit(select: plan.cycle.id);
            }
          },
        ),
      );
    } catch (_) {
      if (mounted) _message(planActL10n(context).cycleFailure);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _label(CommitmentPlan plan) {
    final l10n = planActL10n(context);
    final start = PersianDateFormatter.date(
      JalaliDate.fromDateTime(plan.cycle.startDate.toLocal()),
    );
    final end = plan.cycle.actualEndDate;
    return '$start${end == null ? '' : ' — ${PersianDateFormatter.date(JalaliDate.fromDateTime(end.toLocal()))}'} · ${plan.cycle.status == CommitmentCycleStatus.active ? l10n.cycleActive : l10n.cycleHistorical}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final plan = _plans.where((p) => p.cycle.id == _selected).firstOrNull;
    final activeOwner = plan?.commitment.status == CommitmentStatus.active;
    final active = plan?.cycle.status == CommitmentCycleStatus.active;
    final unresolved =
        plan?.occurrences.any(
          (o) => !{
            OccurrenceStatus.completed,
            OccurrenceStatus.cancelled,
            OccurrenceStatus.skipped,
          }.contains(o.status),
        ) ??
        false;
    return Padding(
      padding: const EdgeInsets.only(bottom: PlanActSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_error) ...[
            Text(l10n.cycleLoadError),
            TextButton(
              onPressed: _busy ? null : _load,
              child: Text(l10n.commonRetry),
            ),
          ],
          if (_plans.isNotEmpty && !_error) ...[
            DropdownButtonFormField<StableId>(
              key: ValueKey('cycle-selection-$_selected'),
              initialValue: _selected,
              isExpanded: true,
              decoration: InputDecoration(labelText: l10n.cycleSelect),
              items: [
                for (final item in _plans)
                  DropdownMenuItem(
                    value: item.cycle.id,
                    child: Text(_label(item)),
                  ),
              ],
              selectedItemBuilder: (_) => [
                for (final item in _plans)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      _label(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _busy || _loading
                  ? null
                  : (id) {
                      setState(() => _selected = id);
                      widget.onSelected(
                        _plans.where((p) => p.cycle.id == id).firstOrNull,
                      );
                    },
            ),
            const SizedBox(height: PlanActSpacing.sm),
            if (!activeOwner) Text(l10n.cycleInactiveOwner),
            if (!active) Text(l10n.cycleReadOnly),
            if (activeOwner && active)
              OutlinedButton(
                key: const ValueKey('cycle-finish'),
                onPressed: _busy || _loading || unresolved
                    ? null
                    : () => _finish(plan!),
                child: Text(l10n.cycleFinish),
              ),
            if (activeOwner && active && unresolved)
              Text(l10n.cycleFinishConfirm),
            if (activeOwner &&
                !_plans.any(
                  (p) => p.cycle.status == CommitmentCycleStatus.active,
                ))
              FilledButton(
                key: const ValueKey('cycle-create'),
                onPressed: _busy || _loading ? null : _next,
                child: Text(l10n.cycleCreate),
              ),
          ],
        ],
      ),
    );
  }
}

class _CompleteCycleDialog extends StatefulWidget {
  const _CompleteCycleDialog({
    required this.initialDate,
    required this.onConfirm,
  });
  final DateTime initialDate;
  final Future<Object?> Function(DateTime) onConfirm;
  @override
  State<_CompleteCycleDialog> createState() => _CompleteCycleDialogState();
}

class _CompleteCycleDialogState extends State<_CompleteCycleDialog> {
  DateTime? _date;
  bool _busy = false;
  bool _error = false;
  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return PopScope(
      canPop: !_busy,
      child: AlertDialog(
        title: Text(l10n.cycleFinish),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.cycleFinishConfirm),
              const SizedBox(height: PlanActSpacing.md),
              OutlinedButton(
                key: const ValueKey('cycle-end-date'),
                onPressed: _busy
                    ? null
                    : () async {
                        final date = await showDialog<DateTime>(
                          context: context,
                          builder: (_) => PlanActJalaliDatePicker(
                            initialDate: _date ?? widget.initialDate,
                          ),
                        );
                        if (date != null && mounted) {
                          setState(() => _date = date);
                        }
                      },
                child: Text(
                  _date == null
                      ? l10n.quickCaptureSheetScheduleFieldsLabel3
                      : PersianDateFormatter.date(
                          JalaliDate.fromDateTime(_date!),
                        ),
                ),
              ),
              if (_error)
                Semantics(liveRegion: true, child: Text(l10n.cycleFailure)),
              if (_busy) const LinearProgressIndicator(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const ValueKey('cycle-finish-confirm'),
            onPressed: _busy || _date == null
                ? null
                : () async {
                    setState(() {
                      _busy = true;
                      _error = false;
                    });
                    try {
                      await widget.onConfirm(_date!);
                      if (context.mounted) Navigator.pop(context, _date);
                    } catch (_) {
                      if (mounted) setState(() => _error = true);
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
            child: Text(l10n.cycleFinish),
          ),
        ],
      ),
    );
  }
}
