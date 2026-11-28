import 'package:planact/features/reconciliation/application/atomic_occurrence_allocation_repository.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/reconciliation/presentation/relationship_target_browser.dart';
import 'package:planact/features/classification/presentation/tag_badge.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/undo_feedback.dart';
import 'package:planact/features/reconciliation/domain/reconciliation.dart';
import 'package:planact/features/reconciliation/presentation/match_correction_sheet.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';

class TransactionRelationshipPage extends StatefulWidget {
  const TransactionRelationshipPage({
    super.key,
    required this.transactionId,
    required this.flow,
    this.onOpenQueue,
    this.reviewRemaining,
  });
  final int? reviewRemaining;
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
  StableId? _associationDraft;
  bool _associationInitialized = false;
  String? _associationError;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  }

  PinnedMoneyInput? _pinned;
  PinnedMoneyInput get _moneyInput =>
      _pinned ??= PinnedMoneyInput(MoneyUnitScope.of(context));
  final _amount = TextEditingController();
  final _total = TextEditingController();
  OccurrenceAllocationSnapshot? _allocationSnapshot;
  int _selectionRequest = 0;
  bool _selectionLoading = false;
  bool _requiresRefresh = false;
  bool _totalConfirmed = false;
  int _loadRequest = 0;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  bool _leaving = false;
  String? _error;
  String? _amountError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _total.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = ++_loadRequest;
    ++_selectionRequest;
    setState(() {
      _loading = true;
      _allocationSnapshot = null;
      _totalConfirmed = false;
      _error = null;
    });
    try {
      final result = await widget.flow.loadForPage(widget.transactionId);
      if (mounted && request == _loadRequest) {
        setState(() {
          _context = result;
          if (!_associationInitialized) {
            _associationDraft = result.association?.commitmentId;
            _associationInitialized = true;
          }
          _loading = false;
        });
        if (_selected != null) await _loadSelection(_selected!);
      }
    } catch (_) {
      if (mounted && request == _loadRequest) {
        setState(() {
          _loading = false;
          _error = PersianCopy.transactionRelationshipPageLoadMessage;
        });
      }
    }
  }

  String _allocationError(OccurrenceAllocationErrorCode code) {
    final l10n = planActL10n(context);
    return switch (code) {
      OccurrenceAllocationErrorCode.stale =>
        l10n.occurrenceAllocationErrorStale,
      OccurrenceAllocationErrorCode.missing =>
        l10n.occurrenceAllocationErrorMissing,
      OccurrenceAllocationErrorCode.ambiguous =>
        l10n.occurrenceAllocationErrorAmbiguous,
      OccurrenceAllocationErrorCode.currency =>
        l10n.occurrenceAllocationErrorCurrency,
      OccurrenceAllocationErrorCode.capacity =>
        l10n.occurrenceAllocationErrorCapacity,
      OccurrenceAllocationErrorCode.historicalInactive =>
        l10n.occurrenceAllocationErrorInactive,
      OccurrenceAllocationErrorCode.storage =>
        l10n.occurrenceAllocationErrorStorage,
    };
  }

  Future<void> _selectOccurrence(StableId id) async {
    if (_saving) return;
    if (_selected == id) return;
    setState(() {
      _selected = id;
      _total.clear();
      _totalConfirmed = false;
    });
    await _loadSelection(id);
  }

  Future<void> _loadSelection(StableId id) async {
    final request = ++_selectionRequest;
    setState(() {
      _allocationSnapshot = null;
      _selectionLoading = true;
      _requiresRefresh = false;
      _totalConfirmed = false;
      _error = null;
    });
    try {
      final snapshot = await widget.flow.loadOccurrenceAllocation(
        widget.transactionId,
        id,
      );
      if (!mounted || request != _selectionRequest || _selected != id) return;
      setState(() {
        _allocationSnapshot = snapshot;
        _selectionLoading = false;
      });
    } catch (error) {
      if (!mounted || request != _selectionRequest || _selected != id) return;
      setState(() {
        _selectionLoading = false;
        _requiresRefresh = true;
        _error = _allocationError(
          error is OccurrenceAllocationException
              ? error.code
              : OccurrenceAllocationErrorCode.storage,
        );
      });
    }
  }

  Future<void> _save() async {
    if (_saving || _selectionLoading || _requiresRefresh) return;
    final snapshot = _allocationSnapshot;
    if (widget.flow.supportsAtomicAllocation && snapshot == null) return;
    final missing =
        snapshot?.expectationState == OccurrenceExpectationState.missing;
    final total = missing
        ? _moneyInput.parse(
            _total.text,
            currency: snapshot!.transaction.amount.currency,
          )
        : null;
    if (missing && (total == null || total <= 0 || !_totalConfirmed)) {
      setState(
        () => _error = planActL10n(context).occurrenceAllocationTotalRequired,
      );
      return;
    }
    final amount = _moneyInput.parse(
      _amount.text,
      currency: _context!.transaction.amount.currency,
    );
    if (amount == null || amount <= 0) {
      setState(() {
        _error = null;
        _amountError = _amount.text.trim().isEmpty
            ? planActL10n(context).occurrenceAllocationAmountRequired
            : planActL10n(context).occurrenceAllocationAmountInvalid;
      });
      return;
    }
    if (_selected == null) {
      setState(
        () => _error = PersianCopy.transactionRelationshipPageSaveMessage,
      );
      return;
    }
    if (amount >
            (snapshot?.transactionCapacity.minorUnits ??
                _context!.available.minorUnits) ||
        (missing && amount > total!) ||
        (snapshot?.expectationState == OccurrenceExpectationState.ambiguous) ||
        (snapshot?.expectationCapacity != null &&
            amount > snapshot!.expectationCapacity!.minorUnits)) {
      setState(
        () => _error = snapshot == null
            ? PersianCopy.transactionRelationshipPageSaveMessage
            : snapshot.expectationState == OccurrenceExpectationState.ambiguous
            ? _allocationError(OccurrenceAllocationErrorCode.ambiguous)
            : planActL10n(context).occurrenceAllocationAmountOverCapacity,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
      _amountError = null;
    });
    try {
      await widget.flow.confirmSelectedOccurrence(
        snapshot: snapshot,
        transactionId: widget.transactionId,
        occurrenceId: _selected!,
        allocation: Money(
          minorUnits: amount,
          currency: _context!.transaction.amount.currency,
        ),
        total: total == null
            ? null
            : Money(
                minorUnits: total,
                currency: snapshot!.transaction.amount.currency,
              ),
        expectedReview: _context!.review,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        setState(() {
          _saving = false;
          _dirty = true;
        });
        if (widget.reviewRemaining != null &&
            amount < _context!.available.minorUnits) {
          _amount.clear();
          _total.clear();
          setState(() {
            _selected = null;
            _allocationSnapshot = null;
            _totalConfirmed = false;
          });
          await _load();
        } else {
          setState(() => _leaving = true);
          await WidgetsBinding.instance.endOfFrame;
          if (mounted) Navigator.of(context).pop(true);
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _totalConfirmed = false;
          _requiresRefresh = widget.flow.supportsAtomicAllocation;
          _error = error is OccurrenceAllocationException
              ? _allocationError(error.code)
              : PersianCopy.transactionRelationshipPageSaveMessage2;
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
      if (independent && widget.reviewRemaining != null) {
        final messenger = ScaffoldMessenger.of(context);
        final flow = widget.flow;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text(
                PersianCopy.transactionRelationshipPageDecideContent,
              ),
              action: SnackBarAction(
                label: PersianCopy.inboxPageRejectLabel,
                onPressed: () async {
                  try {
                    await flow.reopen(expected: review);
                  } catch (_) {
                    if (messenger.mounted) {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            PersianCopy
                                .transactionRelationshipPageDecideMessage,
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          );
        setState(() {
          _saving = false;
          _leaving = true;
        });
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
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
          matches: previous.matches,
          association: previous.association,
          commitments: previous.commitments,
          transactionTags: previous.transactionTags,
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

  Future<void> _saveAssociation({bool unlink = false}) async {
    final data = _context;
    final expected = data?.association;
    if (_saving || data == null || expected == null) return;
    final target = unlink ? null : _associationDraft;
    if (target == expected.commitmentId || (!unlink && target == null)) return;
    final l10n = planActL10n(context);
    setState(() {
      _saving = true;
      _associationError = null;
    });
    final confirmed = await confirmRecordedAction(
      context,
      unlink
          ? l10n.commitmentAssociationUnlinkConfirm
          : l10n.commitmentAssociationSaveConfirm,
    );
    if (!mounted) return;
    if (!confirmed) {
      setState(() => _saving = false);
      return;
    }
    try {
      final head = await widget.flow.associateCommitment(
        expected: expected,
        transactionId: widget.transactionId,
        commitmentId: target,
      );
      if (!mounted) return;
      setState(() {
        _context = TransactionRelationshipContext(
          transaction: data.transaction,
          account: data.account,
          available: data.available,
          targets: data.targets,
          review: data.review,
          matches: data.matches,
          association: head,
          commitments: data.commitments,
          transactionTags: data.transactionTags,
        );
        _associationDraft = head.commitmentId;
        _saving = false;
        _dirty = true;
      });
      showRecordedActionFeedback(context, l10n.commitmentAssociationSaved);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _associationError = l10n.commitmentAssociationError;
      });
    }
  }

  Widget _associationSection(TransactionRelationshipContext data) {
    final l10n = planActL10n(context);
    final current = data.association!.commitmentId;
    final currentOwner = data.commitments
        .where((c) => c.id == current)
        .firstOrNull;
    final draftAvailable = data.commitments.any(
      (c) => c.id == _associationDraft,
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PlanActSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: PlanActSpacing.md,
          children: [
            Text(
              l10n.commitmentAssociationTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: PlanActSpacing.sm),
            Text(l10n.commitmentAssociationDisclaimer),
            const SizedBox(height: PlanActSpacing.sm),
            Text(
              currentOwner == null
                  ? l10n.commitmentAssociationNone
                  : l10n.commitmentAssociationCurrent(currentOwner.title),
            ),
            const SizedBox(height: PlanActSpacing.md),
            DropdownButtonFormField<StableId>(
              key: ValueKey('association-draft-${_associationDraft?.value}'),
              initialValue: draftAvailable ? _associationDraft : null,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.commitmentAssociationSelect,
              ),
              items: [
                for (final commitment in data.commitments)
                  DropdownMenuItem(
                    value: commitment.id,
                    child: Text(
                      commitment.status == CommitmentStatus.archived
                          ? '${commitment.title} · ${l10n.transactionRelationshipPageBuildSubtitle}'
                          : commitment.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _saving
                  ? null
                  : (value) => setState(() => _associationDraft = value),
            ),
            if (data.commitments.isEmpty) Text(l10n.commitmentAssociationEmpty),
            const SizedBox(height: PlanActSpacing.sm),
            Wrap(
              spacing: PlanActSpacing.sm,
              runSpacing: PlanActSpacing.sm,
              children: [
                FilledButton.tonal(
                  key: const ValueKey('association-save'),
                  onPressed:
                      _saving || !draftAvailable || _associationDraft == current
                      ? null
                      : () => _saveAssociation(),
                  child: Text(
                    current == null
                        ? l10n.commitmentAssociationSave
                        : l10n.commitmentAssociationChange,
                  ),
                ),
                if (current != null)
                  OutlinedButton(
                    key: const ValueKey('association-unlink'),
                    onPressed: _saving
                        ? null
                        : () => _saveAssociation(unlink: true),
                    child: Text(l10n.commitmentAssociationUnlink),
                  ),
              ],
            ),
            if (_associationError != null)
              Semantics(
                liveRegion: true,
                child: Text(
                  _associationError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _missingExpectation() {
    final l10n = planActL10n(context);
    final snapshot = _allocationSnapshot!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: PlanActSpacing.md,
      children: [
        Text(
          l10n.occurrenceAllocationMissingTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          snapshot.suggestedDirection == FinancialExpectationDirection.incoming
              ? l10n.occurrenceAllocationSuggestedIncome
              : l10n.occurrenceAllocationSuggestedExpense,
        ),
        Text(l10n.occurrenceAllocationScope),
        TextField(
          key: const ValueKey('occurrence-expectation-total'),
          controller: _total,
          enabled: !_saving && !_requiresRefresh,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: const [MoneyInputFormatter(decimal: true)],
          onChanged: (_) => setState(() => _totalConfirmed = false),
          decoration: InputDecoration(
            labelText: l10n.occurrenceAllocationTotal(
              _moneyInput.label(snapshot.transaction.amount.currency),
            ),
            helperText: l10n.occurrenceAllocationTotalHelper,
            helperMaxLines: 5,
          ),
        ),
        CheckboxListTile(
          key: const ValueKey('occurrence-expectation-confirm'),
          contentPadding: EdgeInsets.zero,
          value: _totalConfirmed,
          onChanged: _saving || _requiresRefresh
              ? null
              : (value) => setState(() => _totalConfirmed = value == true),
          title: Text(l10n.occurrenceAllocationTotalConfirmation),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Future<void> _back() async {
    if (_saving || _leaving) return;
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    setState(() => _leaving = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) {
      Navigator.of(context)
          .pop(widget.reviewRemaining != null ? null : (_dirty ? true : null));
    }
  }

  Future<void> _removeMatch(TransactionMatch match) async {
    if (_saving ||
        !await confirmRecordedAction(
          context,
          planActL10n(context).matchRemoveMessage,
        ) ||
        !mounted) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.flow.removeMatch(match);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = planActL10n(context).undoConflict;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _saving = false;
      _dirty = true;
    });
    await _load();
    if (mounted) {
      showRecordedActionFeedback(context, planActL10n(context).undoStateSaved);
    }
  }

  Future<void> _correctMatch(TransactionMatch match) async {
    if (_saving || _context == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    TransactionRelationshipContext correctionContext;
    try {
      correctionContext = await widget.flow.load(widget.transactionId);
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = PersianCopy.transactionRelationshipPageLoadMessage;
        });
      }
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => MatchCorrectionSheet(
        flow: widget.flow,
        data: correctionContext,
        original: match,
      ),
    );
    if (saved == true && mounted) {
      setState(() => _dirty = true);
      await _load();
      if (mounted) {
        showRecordedActionFeedback(
          context,
          planActL10n(context).undoStateSaved,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = _context;
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
        body: _loading && data == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(PlanActSpacing.page),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: PlanActSpacing.md,
                  children: [
                    if (_loading) const LinearProgressIndicator(),
                    if (widget.reviewRemaining != null)
                      Text(
                        planActL10n(context).sequentialReviewRemaining(
                          PersianNumbers.format(widget.reviewRemaining!),
                        ),
                      ),
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
                        data.transaction.type == AccountEntryType.income
                            ? planActL10n(context).calendarVisibilityIncome
                            : planActL10n(context).calendarVisibilityExpense,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(relationshipDateLabel(data.transaction.occurredAt)),
                      if (data.transactionTags.isNotEmpty)
                        Wrap(
                          spacing: PlanActSpacing.sm,
                          runSpacing: PlanActSpacing.sm,
                          children: [
                            for (final tag in data.transactionTags)
                              TagBadge(label: tag),
                          ],
                        ),
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
                                  planActL10n(
                                    context,
                                  ).transactionRelationshipPageBuildChildren2)
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
                      if (data.matches.isNotEmpty) ...[
                        ExpansionTile(
                          title: Text(planActL10n(context).matchHistoryTitle),
                          children: [
                            for (final match in data.matches)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: PlanActSpacing.md,
                                ),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                      PlanActSpacing.md,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        for (final allocation
                                            in match.allocations)
                                          Text(
                                            '${data.targets.where((t) => t.occurrence.id == allocation.occurrenceId).firstOrNull?.commitment.title ?? ''} · ${PersianMoneyText.money(allocation.amount, unit: MoneyUnitScope.of(context))}',
                                          ),
                                        if (match.status == MatchStatus.active)
                                          Wrap(
                                            spacing: PlanActSpacing.sm,
                                            children: [
                                              TextButton(
                                                onPressed: _saving
                                                    ? null
                                                    : () => _removeMatch(match),
                                                child: Text(
                                                  planActL10n(context)
                                                      .matchRemoveAction,
                                                ),
                                              ),
                                              if (match.allocations.every(
                                                (a) =>
                                                    a.type ==
                                                    AllocationType.payment,
                                              ))
                                                TextButton(
                                                  onPressed: _saving
                                                      ? null
                                                      : () => _correctMatch(
                                                          match,
                                                        ),
                                                  child: Text(
                                                    planActL10n(context)
                                                        .matchCorrectAction,
                                                  ),
                                                ),
                                            ],
                                          )
                                        else
                                          Text(
                                            planActL10n(context)
                                                .matchHistoryResolved,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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
                              .commitmentAssociationSettlementTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          planActL10n(context)
                              .transactionRelationshipPageBuildChildren10,
                        ),
                        RelationshipTargetBrowser(
                          reader: widget.flow.targetReader,
                          targets: data.targets,
                          currency: data.transaction.amount.currency,
                          selected: _selected,
                          moneyInput: _moneyInput,
                          enabled: !_saving && data.available.minorUnits > 0,
                          onSelected: _selectOccurrence,
                        ),
                        if (_selectionLoading) const LinearProgressIndicator(),
                        if (_allocationSnapshot?.expectationState ==
                            OccurrenceExpectationState.missing)
                          _missingExpectation(),
                        if (_allocationSnapshot?.expectationState ==
                            OccurrenceExpectationState.ambiguous)
                          Text(
                            planActL10n(context)
                                .occurrenceAllocationErrorAmbiguous,
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
                          onChanged: (_) => setState(() => _amountError = null),
                          decoration: InputDecoration(
                            errorText: _amountError,
                            errorMaxLines: 3,
                            helperText: planActL10n(context)
                                .occurrenceAllocationAmountHelper,
                            helperMaxLines: 5,
                            labelText: planActL10n(context)
                                .transactionRelationshipPageBuildLabelText2(
                                  (_moneyInput.label(
                                    data.transaction.amount.currency,
                                  )).toString(),
                                ),
                          ),
                        ),
                        FilledButton(
                          onPressed:
                              _saving ||
                                  data.available.minorUnits == 0 ||
                                  _selectionLoading ||
                                  _requiresRefresh ||
                                  (widget.flow.supportsAtomicAllocation &&
                                      _allocationSnapshot == null) ||
                                  _allocationSnapshot?.expectationState ==
                                      OccurrenceExpectationState.ambiguous ||
                                  (_allocationSnapshot?.expectationState ==
                                          OccurrenceExpectationState.missing &&
                                      !_totalConfirmed)
                              ? null
                              : _save,
                          child: Text(
                            _saving
                                ? planActL10n(context)
                                      .transactionRelationshipPageBuildChildren9
                                : _allocationSnapshot?.expectationState ==
                                      OccurrenceExpectationState.missing
                                ? planActL10n(context)
                                      .occurrenceAllocationConfirm
                                : planActL10n(
                                    context,
                                  ).transactionRelationshipPageBuildChildren13,
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
                    if (data?.association != null) _associationSection(data!),
                  ],
                ),
              ),
      ),
    );
  }
}
