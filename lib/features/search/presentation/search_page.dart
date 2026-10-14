import 'dart:async';

import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/account_information_card.dart';
import 'package:planact/features/finance/presentation/transaction_direction.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/search/application/search_reader.dart';
import 'package:planact/features/search/domain/search.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.reader,
    required this.onOpenCommitment,
    required this.onOpenNote,
  });
  final SearchReader reader;
  final Future<void> Function(Commitment) onOpenCommitment;
  final Future<void> Function(CalendarNote) onOpenNote;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  final _scroll = ScrollController();
  Timer? _debounce;
  List<SearchDocument> _documents = const [];
  List<SearchDocument> _results = const [];
  SearchKind? _kind;
  bool _loading = true;
  bool _failed = false;
  bool _openFailed = false;
  bool _opening = false;
  int _readRevision = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _readRevision++;
    _debounce?.cancel();
    _query.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final revision = ++_readRevision;
    setState(() {
      _loading = true;
      _failed = false;
      _openFailed = false;
    });
    try {
      final documents = await widget.reader.read();
      if (!mounted || revision != _readRevision) return;
      setState(() {
        _documents = documents;
        _results = searchDocuments(documents, _query.text, kind: _kind);
        _loading = false;
      });
    } catch (_) {
      if (!mounted || revision != _readRevision) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _search({bool resetScroll = true}) {
    _debounce?.cancel();
    setState(() {
      _results = searchDocuments(_documents, _query.text, kind: _kind);
      _openFailed = false;
    });
    if (resetScroll && _scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _open(SearchDocument document) async {
    if (_opening) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _opening = true;
      _openFailed = false;
    });
    try {
      switch (document.target) {
        case CommitmentSearchTarget(:final value):
          await widget.onOpenCommitment(value);
        case NoteSearchTarget(:final value):
          await widget.onOpenNote(value);
        case TransactionSearchTarget() || AccountSearchTarget():
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => _FinancialSearchDetails(document: document),
            ),
          );
      }
      if (mounted) await _load();
    } catch (_) {
      if (mounted) setState(() => _openFailed = true);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.searchTitle),
        actions: [
          IconButton(
            tooltip: l10n.searchRefresh,
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: PlanActSpacing.contentWidth,
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(PlanActSpacing.lg),
                  child: TextField(
                    key: const ValueKey('global-search-query'),
                    controller: _query,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: l10n.searchFieldLabel,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.searchClear,
                              onPressed: () {
                                _query.clear();
                                _search();
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _debounce?.cancel();
                      _debounce = Timer(
                        const Duration(milliseconds: 180),
                        () => _search(),
                      );
                    },
                    onSubmitted: (_) => _search(),
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    controller: _scroll,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PlanActSpacing.lg,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                spacing: PlanActSpacing.sm,
                                runSpacing: PlanActSpacing.xs,
                                children: [
                                  for (final kind in [
                                    null,
                                    ...SearchKind.values,
                                  ])
                                    FilterChip(
                                      key: ValueKey(
                                        'search-filter-${kind?.name ?? 'all'}',
                                      ),
                                      label: Text(
                                        kind == null
                                            ? l10n.searchAll
                                            : searchKindLabel(context, kind),
                                      ),
                                      selected: _kind == kind,
                                      onSelected: (_) {
                                        _kind = kind;
                                        _search();
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: PlanActSpacing.md),
                              if (_loading) const LinearProgressIndicator(),
                              if (_failed)
                                PlanActStateMessage(
                                  message: l10n.searchReadError,
                                  isError: true,
                                  action: TextButton(
                                    onPressed: _load,
                                    child: Text(l10n.commonRetry),
                                  ),
                                ),
                              if (_openFailed)
                                PlanActStateMessage(
                                  message: l10n.searchOpenError,
                                  isError: true,
                                  action: TextButton(
                                    onPressed: _load,
                                    child: Text(l10n.commonRetry),
                                  ),
                                ),
                              if (!_failed && !_loading)
                                if (normalizeSearchText(_query.text).isEmpty)
                                  PlanActStateMessage(
                                    message: l10n.searchGuidance,
                                  )
                                else if (_results.isEmpty)
                                  PlanActStateMessage(
                                    message: l10n.searchNoResults,
                                  )
                                else
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      l10n.searchResultCount(
                                        PersianNumbers.format(_results.length),
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                      if (!_failed)
                        SliverList.builder(
                          itemCount: _results.length,
                          itemBuilder: (context, index) {
                            final doc = _results[index];
                            return ListTile(
                              key: ValueKey(
                                'search-result-${doc.target.kind.name}-${doc.target.id}',
                              ),
                              enabled: !_opening && !_loading,
                              leading: switch (doc.target) {
                                CommitmentSearchTarget(:final value) =>
                                  CommitmentIdentityMarker(commitment: value),
                                TransactionSearchTarget(:final value) =>
                                  TransactionDirectionIcon(entry: value),
                                NoteSearchTarget(:final value) => Icon(
                                  Icons.note_alt_outlined,
                                  color: CommitmentIdentityPalette.foreground(
                                    value.color,
                                    Theme.of(context).brightness,
                                  ),
                                ),
                                AccountSearchTarget() => const Icon(
                                  Icons.account_balance_wallet_outlined,
                                ),
                              },
                              title: Text(
                                doc.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                [
                                  searchKindLabel(context, doc.target.kind),
                                  searchTargetSummary(context, doc.target),
                                  if (doc.description.isNotEmpty)
                                    doc.description,
                                ].join('\n'),
                                maxLines: 6,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _open(doc),
                            );
                          },
                        ),
                      const SliverToBoxAdapter(
                        child: SizedBox(height: PlanActSpacing.xl),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String searchKindLabel(BuildContext context, SearchKind kind) {
  final l10n = planActL10n(context);
  return switch (kind) {
    SearchKind.commitment => l10n.searchCommitments,
    SearchKind.transaction => l10n.searchTransactions,
    SearchKind.note => l10n.searchNotes,
    SearchKind.account => l10n.searchAccounts,
  };
}

String _date(DateTime value) {
  final date = JalaliDate.fromDateTime(value);
  return '${PersianDateFormatter.date(date)} ${PersianNumbers.format(date.year)}';
}

String searchTargetSummary(BuildContext context, SearchTarget target) {
  final l10n = planActL10n(context);
  return switch (target) {
    CommitmentSearchTarget(:final value) => switch (value.status) {
      CommitmentStatus.active => l10n.planactAppCommitmentStatusActive,
      CommitmentStatus.paused => l10n.planactAppCommitmentStatusPaused,
      CommitmentStatus.archived => l10n.planactAppCommitmentStatusArchived,
      CommitmentStatus.completed => l10n.planactAppCommitmentStatusCompleted,
      CommitmentStatus.cancelled => l10n.searchCancelled,
    },
    NoteSearchTarget(:final value) => _date(
      DateTime(value.date.year, value.date.month, value.date.day),
    ),
    AccountSearchTarget(:final value) =>
      value.status == FinancialAccountStatus.archived
          ? l10n.planactAppCommitmentStatusArchived
          : l10n.planactAppCommitmentStatusActive,
    TransactionSearchTarget(:final value, :final account) => [
      transactionLabel(value),
      account.name,
      PersianMoneyText.money(
        value.signedAmount,
        unit: MoneyUnitScope.of(context),
      ),
      _date(value.occurredAt.toLocal()),
    ].join(l10n.commonListSeparator),
  };
}

class _FinancialSearchDetails extends StatelessWidget {
  const _FinancialSearchDetails({required this.document});
  final SearchDocument document;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(searchKindLabel(context, document.target.kind))),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: PlanActSpacing.contentWidth,
          ),
          child: ListView(
            padding: const EdgeInsets.all(PlanActSpacing.page),
            children: [
              Text(
                document.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: PlanActSpacing.md),
              SelectableText(searchTargetSummary(context, document.target)),
              if (document.description.isNotEmpty)
                SelectableText(document.description),
              if (document.target case AccountSearchTarget(
                :final value,
                :final entries,
              ))
                AccountInformationCard(
                  account: value,
                  balance: rebuildBalance(value, entries),
                  operations: const SizedBox.shrink(),
                ),
              if (document.target case TransactionSearchTarget(
                :final value,
              )) ...[
                if (value.referenceId case final reference?)
                  SelectableText(reference),
                const SizedBox(height: PlanActSpacing.md),
                Text(planActL10n(context).searchFinancialReadOnly),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}
