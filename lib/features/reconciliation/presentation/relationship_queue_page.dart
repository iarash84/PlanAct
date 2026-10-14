import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/reconciliation/application/bulk_relationship_review.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

class RelationshipQueuePage extends StatefulWidget {
  const RelationshipQueuePage({
    super.key,
    required this.queue,
    required this.onOpen,
    required this.onDataChanged,
  });
  final RelationshipQueue queue;
  final Future<void> Function(StableId) onOpen;
  final Future<void> Function() onDataChanged;
  @override
  State<RelationshipQueuePage> createState() => _RelationshipQueuePageState();
}

class _RelationshipQueuePageState extends State<RelationshipQueuePage> {
  List<RelationshipQueueItem> _items = [];
  final Map<StableId, RelationshipQueueItem> _selection = {};
  final Map<StableId, RelationshipQueueItem> _failures = {};
  final Set<StableId> _committed = {};
  int _page = 0, _generation = 0, _attempted = 0, _succeeded = 0;
  String _query = '';
  AccountEntryType? _type;
  bool _independent = false, _hasNext = false, _loading = true;
  String? _error;
  StableId? _active;
  BulkRelationshipReview? _runner;
  bool get _running => _runner != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _runner?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
      _selection.clear();
    });
    try {
      final result = await widget.queue.load(
        page: _page,
        query: _query,
        type: _type,
        independent: _independent,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = result.items;
        _hasNext = result.hasNext;
        _loading = false;
        // Local success suppression only bridges an in-flight read. Fresh
        // durable state (including explicit reopening) wins once run ends.
        if (!_running) _committed.clear();
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = PersianCopy.relationshipQueuePageLoadMessage;
      });
    }
  }

  void _filter(VoidCallback change) {
    setState(() {
      change();
      _page = 0;
      _selection.clear();
    });
    _load();
  }

  Future<void> _confirm({bool retry = false}) async {
    if (_running) return;
    final snapshots = List<RelationshipQueueItem>.unmodifiable(
      retry ? _failures.values : _selection.values,
    );
    if (snapshots.isEmpty) return;
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(PersianCopy.relationshipQueuePageApprovedTitle),
        content: Text(
          PersianCopy.relationshipQueuePageApprovedContent3(
            (PersianNumbers.format(snapshots.length)).toString(),
            (retry
                    ? PersianCopy.relationshipQueuePageApprovedContent2
                    : PersianCopy.relationshipQueuePageApprovedContent)
                .toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(PersianCopy.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(PersianCopy.relationshipQueuePageApprovedActions),
          ),
        ],
      ),
    );
    if (!mounted || approved != true || _running) return;
    final runner = BulkRelationshipReview(widget.queue.reviews);
    setState(() {
      _runner = runner;
      _attempted = 0;
      _succeeded = 0;
      _failures.clear();
      _selection.clear();
    });
    await runner.run(
      snapshots,
      onStarted: (item) {
        if (mounted) setState(() => _active = item.transaction.id);
      },
      onFinished: (item, result) {
        if (!mounted) return;
        setState(() {
          _attempted++;
          _active = null;
          if (result == null) {
            _failures[item.transaction.id] = item;
          } else {
            _succeeded++;
            _committed.add(item.transaction.id);
          }
        });
      },
    );
    if (!mounted) return;
    setState(() {
      _runner = null;
      _active = null;
    });
    await _load();
    try {
      await widget.onDataChanged();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = PersianCopy.relationshipQueuePageConfirmMessage,
        );
      }
    }
  }

  Future<void> _open(RelationshipQueueItem item) async {
    await widget.onOpen(item.transaction.id);
    if (mounted) await _load();
  }

  Future<void> _reopen(RelationshipQueueItem item) async {
    if (_active == item.transaction.id) return;
    setState(() => _active = item.transaction.id);
    try {
      final review = await widget.queue.reviews.decideReview(
        expected: item.review,
        decision: RelationshipReviewDecision.reopened,
        recordedAt: DateTime.now().toUtc(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(PersianCopy.relationshipQueuePageReopenContent),
          action: SnackBarAction(
            label: PersianCopy.inboxPageRejectLabel,
            onPressed: () => _undoReopen(review),
          ),
        ),
      );
      await _load();
      await widget.onDataChanged();
    } catch (_) {
      if (mounted) {
        setState(() => _error = PersianCopy.relationshipQueuePageReopenMessage);
      }
    } finally {
      if (mounted) setState(() => _active = null);
    }
  }

  Future<void> _undoReopen(RelationshipReview review) async {
    try {
      await widget.queue.reviews.decideReview(
        expected: review,
        decision: RelationshipReviewDecision.independent,
        recordedAt: DateTime.now().toUtc(),
      );
      if (mounted) await _load();
      await widget.onDataChanged();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = PersianCopy.relationshipQueuePageUndoReopenMessage,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items
        .where((item) => !_committed.contains(item.transaction.id))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(planActL10n(context).relationshipQueuePageBuildTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(PlanActSpacing.lg),
        children: [
          Text(planActL10n(context).relationshipQueuePageBuildChildren),
          TextField(
            decoration: InputDecoration(
              labelText: planActL10n(context)
                  .relationshipQueuePageBuildLabelText,
            ),
            onChanged: (value) => _filter(() => _query = value.trim()),
          ),
          Wrap(
            spacing: PlanActSpacing.sm,
            children: [
              ChoiceChip(
                label: Text(
                  planActL10n(context).relationshipQueuePageBuildLabel,
                ),
                selected: _type == null,
                onSelected: (_) => _filter(() => _type = null),
              ),
              ChoiceChip(
                label: Text(planActL10n(context).inboxPageBuildTitle4),
                selected: _type == AccountEntryType.income,
                onSelected: (_) =>
                    _filter(() => _type = AccountEntryType.income),
              ),
              ChoiceChip(
                label: Text(planActL10n(context).inboxPageBuildTitle3),
                selected: _type == AccountEntryType.expense,
                onSelected: (_) =>
                    _filter(() => _type = AccountEntryType.expense),
              ),
              FilterChip(
                label: Text(
                  planActL10n(context).relationshipQueuePageBuildLabel2,
                ),
                selected: _independent,
                onSelected: (value) => _filter(() => _independent = value),
              ),
            ],
          ),
          Text(
            planActL10n(context).relationshipQueuePageBuildChildren2(
              (PersianNumbers.format(_page + 1)).toString(),
              (PersianNumbers.format(BulkRelationshipReview.pageSize))
                  .toString(),
            ),
          ),
          Wrap(
            spacing: PlanActSpacing.sm,
            children: [
              TextButton(
                onPressed: _page == 0
                    ? null
                    : () {
                        setState(() => _page--);
                        _load();
                      },
                child: Text(
                  planActL10n(context).inboxPageBulkControlsChildren7,
                ),
              ),
              TextButton(
                onPressed: !_hasNext
                    ? null
                    : () {
                        setState(() => _page++);
                        _load();
                      },
                child: Text(
                  planActL10n(context).inboxPageBulkControlsChildren8,
                ),
              ),
              TextButton(
                onPressed: _load,
                child: Text(planActL10n(context).inboxPageBuildTooltip),
              ),
              if (!_independent)
                TextButton(
                  onPressed: _running || _loading
                      ? null
                      : () => setState(() {
                          _selection.clear();
                          for (final item in visible) {
                            if (item.selectable) {
                              _selection[item.transaction.id] = item;
                            }
                          }
                        }),
                  child: Text(
                    planActL10n(context).relationshipQueuePageBuildChildren3,
                  ),
                ),
              if (_selection.isNotEmpty)
                TextButton(
                  onPressed: () => setState(_selection.clear),
                  child: Text(
                    planActL10n(context).relationshipQueuePageBuildChildren4,
                  ),
                ),
              if (!_independent)
                FilledButton(
                  onPressed: _running || _selection.isEmpty ? null : _confirm,
                  child: Text(
                    planActL10n(context).relationshipQueuePageBuildChildren5(
                      (PersianNumbers.format(_selection.length)).toString(),
                    ),
                  ),
                ),
            ],
          ),
          if (_running || _attempted > 0)
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_running) const LinearProgressIndicator(),
                  Text(
                    planActL10n(context).relationshipQueuePageBuildChildren6(
                      (PersianNumbers.format(_attempted)).toString(),
                      (PersianNumbers.format(_succeeded)).toString(),
                      (PersianNumbers.format(_failures.length)).toString(),
                    ),
                  ),
                  if (_running)
                    TextButton(
                      onPressed: () {
                        _runner?.cancel();
                        setState(() {});
                      },
                      child: Text(
                        planActL10n(context).inboxPageBulkControlsChildren11,
                      ),
                    ),
                  if (!_running && _failures.isNotEmpty)
                    TextButton(
                      onPressed: () => _confirm(retry: true),
                      child: Text(
                        planActL10n(context)
                            .relationshipQueuePageBuildChildren7,
                      ),
                    ),
                ],
              ),
            ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_error == null && visible.isEmpty)
            Text(planActL10n(context).relationshipQueuePageBuildChildren8),
          if (!_loading && _error == null)
            for (final item in visible)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: item.selectable
                          ? Checkbox(
                              value: _selection.containsKey(
                                item.transaction.id,
                              ),
                              semanticLabel: planActL10n(context)
                                  .relationshipQueuePageBuildSemanticLabel2(
                                    (item.transaction.note ??
                                            planActL10n(
                                              context,
                                            ).relationshipQueuePageBuildSemanticLabel)
                                        .toString(),
                                  ),
                              onChanged: _running
                                  ? null
                                  : (value) => setState(() {
                                      if (value == true) {
                                        _selection[item.transaction.id] = item;
                                      } else {
                                        _selection.remove(item.transaction.id);
                                      }
                                    }),
                            )
                          : const Icon(Icons.check_circle_outline),
                      title: Text(
                        item.transaction.note ??
                            planActL10n(context)
                                .relationshipQueuePageBuildSemanticLabel,
                      ),
                      subtitle: Text(
                        planActL10n(context)
                            .relationshipQueuePageBuildSubtitle2(
                              (item.transaction.type == AccountEntryType.income
                                      ? planActL10n(context)
                                            .inboxPageBuildTitle4
                                      : planActL10n(context)
                                            .inboxPageBuildTitle3)
                                  .toString(),
                              (PersianMoneyText.amount(
                                item.review.remainderMinorUnits,
                                item.review.transactionAmount.currency,
                                unit: MoneyUnitScope.of(context),
                              )).toString(),
                              (item.review.isIndependent
                                      ? planActL10n(context)
                                            .relationshipQueuePageBuildSubtitle
                                      : '')
                                  .toString(),
                            ),
                      ),
                    ),
                    if (_active == item.transaction.id)
                      const LinearProgressIndicator(),
                    if (_failures.containsKey(item.transaction.id))
                      Text(
                        planActL10n(context)
                            .relationshipQueuePageBuildChildren9,
                      ),
                    Wrap(
                      spacing: PlanActSpacing.sm,
                      children: [
                        TextButton(
                          onPressed: _active == item.transaction.id
                              ? null
                              : () => _open(item),
                          child: Text(
                            planActL10n(context)
                                .relationshipQueuePageBuildChildren10,
                          ),
                        ),
                        if (item.review.isIndependent)
                          TextButton(
                            onPressed: _active == item.transaction.id
                                ? null
                                : () => _reopen(item),
                            child: Text(
                              planActL10n(context)
                                  .relationshipQueuePageBuildChildren11,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
