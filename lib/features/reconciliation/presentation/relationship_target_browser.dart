import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/classification/presentation/tag_badge.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/relationship_target_reader.dart';
import 'package:planact/features/reconciliation/presentation/relationship_target_paging.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/scheduling/presentation/occurrence_status_label.dart';

String relationshipCommitmentStatus(
  BuildContext context,
  CommitmentStatus status,
) {
  final l = planActL10n(context);
  return switch (status) {
    CommitmentStatus.active => l.planactAppCommitmentStatusActive,
    CommitmentStatus.paused => l.planactAppCommitmentStatusPaused,
    CommitmentStatus.completed => l.planactAppCommitmentStatusCompleted,
    CommitmentStatus.archived => l.planactAppCommitmentStatusArchived,
    CommitmentStatus.cancelled => l.searchCancelled,
  };
}

String relationshipDateLabel(Object value) {
  final date = relationshipTargetInstant(value);
  final jalali = JalaliDate.fromDateTime(date);
  final label =
      '${PersianDateFormatter.date(jalali)} ${PersianNumbers.format(jalali.year)}';
  return value is DateTime
      ? '$label · ${PersianNumbers.format('${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}')}'
      : label;
}

class RelationshipTargetCard extends StatelessWidget {
  const RelationshipTargetCard({
    super.key,
    required this.target,
    this.selected = false,
    this.onTap,
  });
  final RelationshipTarget target;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final l = planActL10n(context);
    final money = [
      (l.relationshipExpected, target.expected),
      (l.relationshipAllocated, target.allocated),
      (l.relationshipOutstanding, target.outstanding),
    ];
    return Semantics(
      selected: selected,
      button: onTap != null,
      child: Card(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(PlanActSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PlanActSpacing.sm,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommitmentIdentityMarker(commitment: target.commitment),
                    const SizedBox(width: PlanActSpacing.sm),
                    Expanded(
                      child: Text(
                        target.commitment.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                    ),
                  ],
                ),
                if (selected) Text(l.relationshipSelected),
                Text(
                  relationshipDateLabel(target.occurrence.currentScheduledAt),
                ),
                Text(
                  '${occurrenceStatusLabel(target.occurrence.status)} · ${relationshipCommitmentStatus(context, target.commitment.status)}',
                ),
                if (target.commitment.description?.isNotEmpty == true)
                  Text(target.commitment.description!),
                if (target.cycleLabel != null)
                  Text('${l.relationshipCycle}: ${target.cycleLabel}'),
                for (final item in money)
                  if (item.$2 != null)
                    Text(
                      '${item.$1}: ${PersianMoneyText.money(item.$2!, unit: MoneyUnitScope.of(context))}',
                    ),
                if (target.commitment.tags.isNotEmpty)
                  Wrap(
                    spacing: PlanActSpacing.sm,
                    runSpacing: PlanActSpacing.sm,
                    children: [
                      for (final tag in target.commitment.tags)
                        TagBadge(label: tag),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Owns transient browsing state only. Selection is independent of each query page.
class RelationshipTargetBrowser extends StatefulWidget {
  const RelationshipTargetBrowser({
    super.key,
    required this.reader,
    required this.targets,
    required this.currency,
    required this.selected,
    required this.onSelected,
    required this.enabled,
    required this.moneyInput,
  });
  final RelationshipTargetReader? reader;
  final List<RelationshipTarget> targets;
  final String currency;
  final StableId? selected;
  final ValueChanged<StableId> onSelected;
  final bool enabled;
  final PinnedMoneyInput moneyInput;
  @override
  State<RelationshipTargetBrowser> createState() =>
      _RelationshipTargetBrowserState();
}

class _RelationshipTargetBrowserState extends State<RelationshipTargetBrowser> {
  RelationshipTargetPage? _result;
  RelationshipTarget? _selection;
  int _request = 0;
  int _page = 0;
  String _search = '';
  bool _loading = true;
  bool _failed = false;
  bool _invalid = false;
  LocalDate? _from, _to;
  OccurrenceStatus? _occurrence;
  CommitmentStatus? _owner;
  StableId? _cycle;
  RelationshipTargetSort _sort = RelationshipTargetSort.dateAscending;
  final _minimum = TextEditingController();
  final _maximum = TextEditingController();
  int? _min, _max;
  final Map<StableId, String> _cycles = {};
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RelationshipTargetBrowser oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targets != widget.targets ||
        oldWidget.reader != widget.reader ||
        oldWidget.currency != widget.currency) {
      _load();
    }
    if (widget.selected == null) _selection = null;
  }

  @override
  void dispose() {
    _request++;
    _minimum.dispose();
    _maximum.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final query = RelationshipTargetQuery(
      query: _search,
      page: _page,
      from: _from,
      to: _to,
      minimumOutstanding: _min,
      maximumOutstanding: _max,
      occurrenceStatus: _occurrence,
      commitmentStatus: _owner,
      cycleId: _cycle,
      sort: _sort,
    );
    try {
      final result = widget.reader == null
          ? pageLocalRelationshipTargets(widget.targets, query)
          : await widget.reader!.read(query, widget.currency);
      RelationshipTarget? selection;
      final id = widget.selected;
      if (id != null) {
        selection = result.items
            .where((t) => t.occurrence.id == id)
            .firstOrNull;
        selection ??= widget.reader == null
            ? widget.targets.where((t) => t.occurrence.id == id).firstOrNull
            : (await widget.reader!.byIds([id], widget.currency)).firstOrNull;
      }
      if (!mounted || request != _request) return;
      if (_page > 0 && _page * 20 >= result.total) {
        _page = result.total == 0 ? 0 : (result.total - 1) ~/ 20;
        await _load();
        return;
      }
      setState(() {
        _result = result;
        _loading = false;
        if (widget.selected == id) _selection = selection;
        for (final c in result.cycles) {
          _cycles[c.id] = c.label;
        }
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _change(VoidCallback update) {
    setState(() {
      update();
      _page = 0;
    });
    _load();
  }

  Future<void> _pick(bool from) async {
    final existing = from ? _from : _to;
    final date = await showDialog<DateTime>(
      context: context,
      builder: (_) => PlanActJalaliDatePicker(
        initialDate: existing == null
            ? DateTime.now()
            : DateTime(existing.year, existing.month, existing.day),
      ),
    );
    if (!mounted || date == null) return;
    setState(() {
      if (from) {
        _from = LocalDate(date.year, date.month, date.day);
      } else {
        _to = LocalDate(date.year, date.month, date.day);
      }
    });
  }

  void _apply() {
    final min = _minimum.text.isEmpty
        ? null
        : widget.moneyInput.parse(_minimum.text, currency: widget.currency);
    final max = _maximum.text.isEmpty
        ? null
        : widget.moneyInput.parse(_maximum.text, currency: widget.currency);
    final invalid =
        (_minimum.text.isNotEmpty && (min == null || min < 0)) ||
        (_maximum.text.isNotEmpty && (max == null || max < 0)) ||
        (min != null && max != null && min > max) ||
        (_from != null &&
            _to != null &&
            _from!.toUtcDateForCalculation().isAfter(
              _to!.toUtcDateForCalculation(),
            ));
    setState(() => _invalid = invalid);
    if (!invalid) {
      _change(() {
        _min = min;
        _max = max;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = planActL10n(context);
    final total = _result?.total ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PlanActSpacing.md,
      children: [
        if (_selection != null && widget.selected != null) ...[
          Text(
            l.relationshipSelected,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          RelationshipTargetCard(
            key: const ValueKey('relationship-selected'),
            target: _selection!,
            selected: true,
          ),
        ],
        TextField(
          key: const ValueKey('relationship-search'),
          enabled: widget.enabled,
          decoration: InputDecoration(labelText: l.relationshipSearch),
          onChanged: (v) => _change(() => _search = v),
        ),
        ExpansionTile(
          title: Text(l.relationshipFilters),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: PlanActSpacing.md,
              children: [
                Wrap(
                  spacing: PlanActSpacing.sm,
                  runSpacing: PlanActSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: widget.enabled ? () => _pick(true) : null,
                      child: Text(
                        _from == null
                            ? l.relationshipFrom
                            : '${l.relationshipFrom}: ${relationshipDateLabel(_from!)}',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: widget.enabled ? () => _pick(false) : null,
                      child: Text(
                        _to == null
                            ? l.relationshipTo
                            : '${l.relationshipTo}: ${relationshipDateLabel(_to!)}',
                      ),
                    ),
                  ],
                ),
                TextField(
                  key: const ValueKey('relationship-minimum'),
                  controller: _minimum,
                  enabled: widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [MoneyInputFormatter(decimal: true)],
                  decoration: InputDecoration(
                    labelText:
                        '${l.relationshipMinimum} (${widget.moneyInput.label(widget.currency)})',
                  ),
                ),
                TextField(
                  key: const ValueKey('relationship-maximum'),
                  controller: _maximum,
                  enabled: widget.enabled,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [MoneyInputFormatter(decimal: true)],
                  decoration: InputDecoration(
                    labelText:
                        '${l.relationshipMaximum} (${widget.moneyInput.label(widget.currency)})',
                  ),
                ),
                DropdownButtonFormField<OccurrenceStatus>(
                  key: ValueKey('occurrence-$_occurrence'),
                  initialValue: _occurrence,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.relationshipOccurrenceStatus,
                  ),
                  items: [
                    DropdownMenuItem(child: Text(l.relationshipAll)),
                    for (final s in OccurrenceStatus.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(occurrenceStatusLabel(s)),
                      ),
                  ],
                  onChanged: widget.enabled
                      ? (v) => _change(() => _occurrence = v)
                      : null,
                ),
                DropdownButtonFormField<CommitmentStatus>(
                  key: ValueKey('owner-$_owner'),
                  initialValue: _owner,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.relationshipCommitmentStatus,
                  ),
                  items: [
                    DropdownMenuItem(child: Text(l.relationshipAll)),
                    for (final s in CommitmentStatus.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(relationshipCommitmentStatus(context, s)),
                      ),
                  ],
                  onChanged: widget.enabled
                      ? (v) => _change(() => _owner = v)
                      : null,
                ),
                DropdownButtonFormField<StableId>(
                  key: ValueKey('cycle-$_cycle'),
                  initialValue: _cycle,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.relationshipCycle),
                  items: [
                    DropdownMenuItem(child: Text(l.relationshipAll)),
                    for (final c in _cycles.entries)
                      DropdownMenuItem(
                        value: c.key,
                        child: Text(
                          c.value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: widget.enabled
                      ? (v) => _change(() => _cycle = v)
                      : null,
                ),
                if (_invalid)
                  Text(
                    l.relationshipInvalidRange,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Wrap(
                  spacing: PlanActSpacing.sm,
                  children: [
                    FilledButton.tonal(
                      onPressed: widget.enabled ? _apply : null,
                      child: Text(l.relationshipApplyFilters),
                    ),
                    TextButton(
                      onPressed: widget.enabled
                          ? () => _change(() {
                              _from = null;
                              _to = null;
                              _min = null;
                              _max = null;
                              _minimum.clear();
                              _maximum.clear();
                              _occurrence = null;
                              _owner = null;
                              _cycle = null;
                              _invalid = false;
                            })
                          : null,
                      child: Text(l.relationshipClearFilters),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        DropdownButtonFormField<RelationshipTargetSort>(
          initialValue: _sort,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.relationshipSort),
          items: [
            for (final s in RelationshipTargetSort.values)
              DropdownMenuItem(
                value: s,
                child: Text(switch (s) {
                  RelationshipTargetSort.dateAscending =>
                    l.relationshipDateAscending,
                  RelationshipTargetSort.dateDescending =>
                    l.relationshipDateDescending,
                  RelationshipTargetSort.amountAscending =>
                    l.relationshipAmountAscending,
                  RelationshipTargetSort.amountDescending =>
                    l.relationshipAmountDescending,
                }),
              ),
          ],
          onChanged: widget.enabled
              ? (v) {
                  if (v != null) _change(() => _sort = v);
                }
              : null,
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_failed)
          Semantics(
            liveRegion: true,
            child: Column(
              children: [
                Text(l.relationshipTargetError),
                TextButton(
                  onPressed: _load,
                  child: Text(l.inboxPageBuildTooltip),
                ),
              ],
            ),
          )
        else if (!_loading) ...[
          if (total == 0) Text(l.transactionRelationshipPageBuildChildren12),
          for (final target in _result?.items ?? <RelationshipTarget>[])
            RelationshipTargetCard(
              key: ValueKey(
                'relationship-target-${target.occurrence.id.value}',
              ),
              target: target,
              selected: widget.selected == target.occurrence.id,
              onTap: !widget.enabled
                  ? null
                  : () {
                      setState(() => _selection = target);
                      widget.onSelected(target.occurrence.id);
                    },
            ),
          Text(
            l.relationshipPageSummary(
              PersianNumbers.format(total == 0 ? 0 : _page + 1),
              PersianNumbers.format((total + 19) ~/ 20),
              PersianNumbers.format(total),
            ),
          ),
          Wrap(
            spacing: PlanActSpacing.sm,
            runSpacing: PlanActSpacing.sm,
            children: [
              OutlinedButton(
                onPressed: widget.enabled && _page > 0
                    ? () {
                        _page--;
                        _load();
                      }
                    : null,
                child: Text(l.relationshipPrevious),
              ),
              OutlinedButton(
                onPressed: widget.enabled && (_page + 1) * 20 < total
                    ? () {
                        _page++;
                        _load();
                      }
                    : null,
                child: Text(l.relationshipNext),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
