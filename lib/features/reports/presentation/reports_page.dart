import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reports/application/reports_reader.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/reports/presentation/report_bar_chart.dart';
import 'package:planact/features/reports/presentation/financial_report_chart.dart';
import 'package:planact/features/reports/domain/financial_chart_projections.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/presentation/occurrence_status_label.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

String personalReportLabel(PersonalReportKind kind) => switch (kind) {
  PersonalReportKind.overview =>
    PersianCopy.reportsPagePersonalReportKindOverview,
  PersonalReportKind.performance =>
    PersianCopy.reportsPagePersonalReportKindPerformance,
  PersonalReportKind.attention =>
    PersianCopy.reportsPagePersonalReportKindAttention,
  PersonalReportKind.cashFlow =>
    PersianCopy.reportsPagePersonalReportKindCashFlow,
  PersonalReportKind.settlement =>
    PersianCopy.reportsPagePersonalReportKindSettlement,
  PersonalReportKind.packages =>
    PersianCopy.reportsPagePersonalReportKindPackages,
  PersonalReportKind.topic => PersianCopy.reportsPagePersonalReportKindTopic,
  PersonalReportKind.upcoming =>
    PersianCopy.reportsPagePersonalReportKindUpcoming,
  PersonalReportKind.changes =>
    PersianCopy.reportsPagePersonalReportKindChanges,
  PersonalReportKind.accounts =>
    PersianCopy.reportsPagePersonalReportKindAccounts,
  PersonalReportKind.recurringFinance =>
    PersianCopy.reportsPagePersonalReportKindRecurringFinance,
};

class ReportsPage extends StatefulWidget {
  const ReportsPage({
    super.key,
    required this.reader,
    this.now,
    this.onOpenCommitment,
    this.onOpenTransaction,
  });
  final ReportsReader reader;
  final DateTime? now;
  final Future<void> Function(Commitment)? onOpenCommitment;
  final Future<void> Function(StableId)? onOpenTransaction;
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  PersonalReportKind _kind = PersonalReportKind.overview;
  ReportSnapshot? _snapshot;
  bool _loading = true;
  String? _error;
  late DateTime _from, _to;
  final Set<StableId> _tags = {}, _excludedTags = {};
  ReportTagMode _tagMode = ReportTagMode.any;
  ReportTagSource _tagSource = ReportTagSource.direct;
  ReportGrouping _grouping = ReportGrouping.month;
  StableId? _commitment, _cycle, _account;
  CommitmentKind? _commitmentKind;
  OccurrenceStatus? _status;
  AccountEntryType? _entryType;
  AccountEntrySource? _source;
  ReportSettlementState? _settlement;
  String? _category, _currency;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();
  bool _originalDate = false;
  int _generation = 0;
  DateTime get _now => widget.now ?? DateTime.now();
  bool get _financial => [
    PersonalReportKind.cashFlow,
    PersonalReportKind.accounts,
  ].contains(_kind);
  bool get _combined => [
    PersonalReportKind.overview,
    PersonalReportKind.topic,
    PersonalReportKind.attention,
  ].contains(_kind);
  ReportFilter get _filter => ReportFilter(
    from: _from,
    to: _to,
    tags: {..._tags},
    excludedTags: {..._excludedTags},
    tagMode: _tagMode,
    tagSource: _tagSource,
    commitmentId: _commitment,
    cycleId: _cycle,
    commitmentKind: _commitmentKind,
    occurrenceStatus: _status,
    accountId: _account,
    category: _category,
    entryType: _entryType,
    currency: _currency,
    source: _source,
    settlementState: _settlement,
    query: _query,
    originalDate: _originalDate,
  );

  @override
  void initState() {
    super.initState();
    final today = JalaliDate.fromDateTime(_now);
    final first = JalaliDate(today.year, today.month, 1);
    _from = first.toDateTime();
    _to = first.addMonths(1).addDays(-1).toDateTime();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await widget.reader.read(
        _filter,
        now: _now,
        includePreviews: _kind == PersonalReportKind.upcoming,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = PersianCopy.reportsPageLoadMessage;
      });
    }
  }

  void _clearDimensions() {
    _commitment = null;
    _cycle = null;
    _account = null;
    _status = null;
    _commitmentKind = null;
    _entryType = null;
    _category = null;
    _currency = null;
    _source = null;
    _settlement = null;
    _tagSource = ReportTagSource.direct;
    _originalDate = false;
  }

  Future<void> _pickDate(bool start) async {
    final value = await showDialog<DateTime>(
      context: context,
      builder: (_) => PlanActJalaliDatePicker(initialDate: start ? _from : _to),
    );
    if (value == null || !mounted) return;
    final from = start ? value : _from;
    final to = start ? _to : value;
    if (to.isBefore(from) || ReportFilter(from: from, to: to).dayCount > 366) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(PersianCopy.reportsPagePickDateContent)),
      );
      return;
    }
    setState(() {
      _from = from;
      _to = to;
    });
    await _load();
  }

  void _preset(String preset) {
    final today = JalaliDate.fromDateTime(_now);
    final month = JalaliDate(today.year, today.month, 1);
    late JalaliDate start, end;
    switch (preset) {
      case PersianCopy.commonToday:
        start = today;
        end = today;
      case PersianCopy.reportsPagePresetMessage:
        start = today.addDays(1 - today.weekDay);
        end = start.addDays(6);
      case PersianCopy.reportsPagePresetMessage2:
        start = month.addMonths(-1);
        end = month.addDays(-1);
      case PersianCopy.reportsPagePresetMessage3:
        start = today;
        end = today.addDays(29);
      default:
        start = month;
        end = month.addMonths(1).addDays(-1);
    }
    setState(() {
      _from = start.toDateTime();
      _to = end.toDateTime();
    });
    _load();
  }

  String _date(Object value) {
    final date = JalaliDate.fromDateTime(reportDate(value));
    return '${PersianDateFormatter.shortDate(date)} ${PersianNumbers.format(date.year)}';
  }

  String _money(int amount, String? currency) => currency == null
      ? PersianCopy.inboxPageAmountMessage(
          (PersianNumbers.format(
            MoneyInputFormatter.groupText(amount.toString()),
          )).toString(),
        )
      : PersianMoneyText.amount(
          amount,
          currency,
          unit: MoneyUnitScope.of(context),
        );
  Future<void> _open(Future<void> Function()? action) async {
    if (action == null) return;
    await action();
    if (mounted) await _load();
  }

  Widget _select<T>(
    String label,
    T? value,
    Map<T, String> choices,
    void Function(T?) changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: PlanActSpacing.md),
    child: DropdownButtonFormField<T>(
      key: ValueKey('$label:${value.toString()}'),
      initialValue: value,
      isExpanded: true,
      itemHeight: null,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: const Text(PersianCopy.relationshipQueuePageBuildLabel),
        ),
        ...choices.entries.map(
          (e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)),
        ),
      ],
      onChanged: _loading ? null : (v) => setState(() => changed(v)),
    ),
  );

  Widget _filters(ReportSnapshot data) => ExpansionTile(
    key: const PageStorageKey('report-filters'),
    title: const Text(PersianCopy.reportsPageFiltersTitle),
    subtitle: Text(
      PersianCopy.reportsPageFiltersSubtitle2(
        (PersianNumbers.format(_tags.length)).toString(),
        (_query.isEmpty ? PersianCopy.reportsPageFiltersSubtitle : _query)
            .toString(),
      ),
    ),
    childrenPadding: const EdgeInsets.all(PlanActSpacing.lg),
    children: [
      TextField(
        key: const PageStorageKey('report-search'),
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: PersianCopy.reportsPageFiltersLabelText,
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
      const SizedBox(height: PlanActSpacing.md),
      _select<ReportTagMode>(
        PersianCopy.reportsPageFiltersChildren,
        _tagMode,
        const {
          ReportTagMode.any: PersianCopy.reportsPageFiltersChildren2,
          ReportTagMode.all: PersianCopy.reportsPageFiltersChildren3,
          ReportTagMode.untagged: PersianCopy.reportsPageFiltersChildren4,
        },
        (v) => _tagMode = v ?? ReportTagMode.any,
      ),
      if (data.tags.isEmpty)
        const Text(PersianCopy.reportsPageFiltersChildren5),
      if (_tagMode != ReportTagMode.untagged)
        Wrap(
          spacing: PlanActSpacing.sm,
          children: [
            for (final tag in data.tags)
              FilterChip(
                label: Text(tag.displayLabel),
                selected: _tags.contains(tag.id),
                onSelected: _loading
                    ? null
                    : (v) => setState(() {
                        if (v) {
                          _tags.add(tag.id);
                          _excludedTags.remove(tag.id);
                        } else {
                          _tags.remove(tag.id);
                        }
                      }),
              ),
          ],
        ),
      ExpansionTile(
        key: const PageStorageKey('report-excluded-tags'),
        title: const Text(PersianCopy.reportsPageFiltersTitle2),
        children: [
          Wrap(
            spacing: PlanActSpacing.sm,
            children: [
              for (final tag in data.tags)
                FilterChip(
                  label: Text(
                    PersianCopy.reportsPageFiltersLabel(
                      (tag.displayLabel).toString(),
                    ),
                  ),
                  selected: _excludedTags.contains(tag.id),
                  onSelected: _loading
                      ? null
                      : (v) => setState(() {
                          if (v) {
                            _excludedTags.add(tag.id);
                            _tags.remove(tag.id);
                          } else {
                            _excludedTags.remove(tag.id);
                          }
                        }),
                ),
            ],
          ),
        ],
      ),
      if (!_financial) ...[
        _select<StableId>(
          PersianCopy.calendarPageMarkerPainterText,
          _commitment,
          {for (final c in data.commitments) c.id: c.title},
          (v) {
            _commitment = v;
            _cycle = null;
          },
        ),
        _select<StableId>(PersianCopy.reportsPageFiltersChildren6, _cycle, {
          for (final c in data.cycles.where(
            (c) => _commitment == null || c.commitmentId == _commitment,
          ))
            c.id: PersianCopy.reportsPageFiltersChildren7(
              (data.commitments
                          .where((o) => o.id == c.commitmentId)
                          .firstOrNull
                          ?.title ??
                      PersianCopy.calendarPageMarkerPainterText)
                  .toString(),
              (_date(c.startDate)).toString(),
            ),
        }, (v) => _cycle = v),
        _select<CommitmentKind>(
          PersianCopy.reportsPageFiltersChildren8,
          _commitmentKind,
          const {
            CommitmentKind.oneOff: PersianCopy.planactAppCommitmentKindOneOff,
            CommitmentKind.recurring:
                PersianCopy.planactAppCommitmentKindRecurring,
          },
          (v) => _commitmentKind = v,
        ),
        if (_kind != PersonalReportKind.packages)
          _select<OccurrenceStatus>(
            PersianCopy.reportsPageFiltersChildren9,
            _status,
            {
              for (final s in OccurrenceStatus.values)
                s: occurrenceStatusLabel(s),
            },
            (v) => _status = v,
          ),
      ],
      if (_financial ||
          _kind == PersonalReportKind.settlement ||
          _kind == PersonalReportKind.recurringFinance) ...[
        _select<StableId>(PersianCopy.quickAddSheetBuildLabelText, _account, {
          for (final a in data.accounts) a.id: a.name,
        }, (v) => _account = v),
        _select<String>(PersianCopy.reportsPageFiltersChildren10, _currency, {
          for (final c in {
            ...data.accounts.map((a) => a.currency),
            ...data.entries.map((e) => e.amount.currency),
          })
            c: c,
        }, (v) => _currency = v),
        if (_kind != PersonalReportKind.accounts)
          _select<AccountEntryType>(
            PersianCopy.reportsPageFiltersChildren11,
            _entryType,
            const {
              AccountEntryType.income: PersianCopy.financePageResultCategory,
              AccountEntryType.expense:
                  PersianCopy.reportsPageFiltersChildren12,
              AccountEntryType.refund:
                  PersianCopy.transactionDirectionAccountEntryTypeRefund,
            },
            (v) => _entryType = v,
          ),
      ],
      if (_kind == PersonalReportKind.cashFlow) ...[
        _select<String>(PersianCopy.financePageBuildFiltersHint2, _category, {
          for (final c
              in data.entries
                  .map((e) => e.category)
                  .whereType<String>()
                  .toSet())
            c: c,
        }, (v) => _category = v),
        _select<AccountEntrySource>(
          PersianCopy.reportsPageFiltersChildren13,
          _source,
          const {
            AccountEntrySource.manual: PersianCopy.reportsPageFiltersChildren14,
            AccountEntrySource.sms: PersianCopy.reportsPageFiltersChildren15,
            AccountEntrySource.import: PersianCopy.reportsPageFiltersChildren16,
          },
          (v) => _source = v,
        ),
      ],
      if (_kind == PersonalReportKind.cashFlow ||
          _kind == PersonalReportKind.topic)
        _select<ReportTagSource>(
          PersianCopy.reportsPageFiltersChildren17,
          _tagSource,
          const {
            ReportTagSource.direct: PersianCopy.reportsPageFiltersChildren18,
            ReportTagSource.relatedAllocation:
                PersianCopy.reportsPageFiltersChildren19,
          },
          (v) => _tagSource = v ?? ReportTagSource.direct,
        ),
      if (_kind == PersonalReportKind.settlement)
        _select<ReportSettlementState>(
          PersianCopy.reportsPageFiltersChildren20,
          _settlement,
          {
            for (final s in ReportSettlementState.values)
              s: _settlementLabel(s),
          },
          (v) => _settlement = v,
        ),
      if (_kind == PersonalReportKind.changes)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(PersianCopy.reportsPageFiltersTitle3),
          value: _originalDate,
          onChanged: (v) => setState(() => _originalDate = v),
        ),
      TextButton(
        onPressed: _loading
            ? null
            : () => setState(() {
                _clearDimensions();
                _tags.clear();
                _excludedTags.clear();
                _tagMode = ReportTagMode.any;
                _query = '';
                _searchController.clear();
              }),
        child: const Text(PersianCopy.reportsPageFiltersChildren21),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final data = _snapshot;
    final report = data == null
        ? null
        : buildPersonalReport(data, _filter, kind: _kind, now: _now);
    return Scaffold(
      appBar: AppBar(
        title: Text(planActL10n(context).planactAppBuildTitle3),
        actions: [
          IconButton(
            tooltip: planActL10n(context).reportsPageBuildTooltip,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: PlanActSpacing.contentWidth,
          ),
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              key: const PageStorageKey('reports-list'),
              padding: const EdgeInsets.all(PlanActSpacing.page),
              children: [
                DropdownButtonFormField<PersonalReportKind>(
                  initialValue: _kind,
                  isExpanded: true,
                  itemHeight: null,
                  decoration: InputDecoration(
                    labelText: planActL10n(context).reportsPageBuildLabelText,
                  ),
                  items: [
                    for (final k in PersonalReportKind.values)
                      DropdownMenuItem(
                        value: k,
                        child: Text(personalReportLabel(k)),
                      ),
                  ],
                  onChanged: _loading
                      ? null
                      : (v) {
                          setState(() {
                            _kind = v ?? _kind;
                            _clearDimensions();
                          });
                          _load();
                        },
                ),
                const SizedBox(height: PlanActSpacing.md),
                Wrap(
                  spacing: PlanActSpacing.sm,
                  runSpacing: PlanActSpacing.xs,
                  children: [
                    for (final p in [
                      planActL10n(context).commonToday,
                      planActL10n(context).reportsPagePresetMessage,
                      planActL10n(context).reportsPageBuildChildren,
                      planActL10n(context).reportsPagePresetMessage2,
                      planActL10n(context).reportsPagePresetMessage3,
                    ])
                      ActionChip(
                        label: Text(p),
                        onPressed: _loading ? null : () => _preset(p),
                      ),
                  ],
                ),
                const SizedBox(height: PlanActSpacing.sm),
                Wrap(
                  spacing: PlanActSpacing.sm,
                  runSpacing: PlanActSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: _loading ? null : () => _pickDate(true),
                      child: Text(
                        planActL10n(
                          context,
                        ).reportsPageBuildChildren2((_date(_from)).toString()),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _loading ? null : () => _pickDate(false),
                      child: Text(
                        planActL10n(context)
                            .reportsPageBuildChildren3((_date(_to)).toString()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PlanActSpacing.sm),
                Text(
                  planActL10n(context).reportsPageBuildChildren4,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PlanActSpacing.md),
                SizedBox(
                  height: PlanActSpacing.xs,
                  child: _loading ? const LinearProgressIndicator() : null,
                ),
                if (_error != null) ...[
                  PlanActStateMessage(
                    message: _error!,
                    isError: true,
                    action: TextButton(
                      onPressed: _load,
                      child: Text(planActL10n(context).commonRetry),
                    ),
                  ),
                ],
                if (data != null && _error == null) ...[
                  _filters(data),
                  if (_tags.isNotEmpty || _excludedTags.isNotEmpty)
                    Text(
                      planActL10n(context).reportsPageBuildChildren5(
                        (data.tags
                                .where((t) => _tags.contains(t.id))
                                .map((t) => t.displayLabel)
                                .join(planActL10n(context).commonListSeparator))
                            .toString(),
                        (data.tags
                                .where((t) => _excludedTags.contains(t.id))
                                .map((t) => t.displayLabel)
                                .join(planActL10n(context).commonListSeparator))
                            .toString(),
                      ),
                    ),
                  if (!_loading && report != null) ..._content(report, data),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(PersonalReport report, ReportSnapshot data) {
    final widgets = <Widget>[];
    if (_combined ||
        [
          PersonalReportKind.performance,
          PersonalReportKind.upcoming,
          PersonalReportKind.changes,
        ].contains(_kind)) {
      widgets.add(const Text(PersianCopy.reportsPageContentMessage));
      final resolved = report.occurrences.where((r) => r.resolved).length;
      widgets.add(
        ReportBarChart(
          title: PersianCopy.reportsPageContentTitle,
          data: [
            for (final status in OccurrenceStatus.values)
              if (report.occurrences.any((r) => r.occurrence.status == status))
                ReportBarDatum(
                  occurrenceStatusLabel(status),
                  report.occurrences
                      .where((r) => r.occurrence.status == status)
                      .length,
                  PersianNumbers.format(
                    report.occurrences
                        .where((r) => r.occurrence.status == status)
                        .length,
                  ),
                ),
          ],
        ),
      );
      widgets.add(
        Text(
          PersianCopy.reportsPageContentMessage2(
            (PersianNumbers.format(report.occurrences.length)).toString(),
            (PersianNumbers.format(resolved)).toString(),
          ),
        ),
      );
      for (final status in OccurrenceStatus.values) {
        final rows = report.occurrences
            .where((r) => r.occurrence.status == status)
            .toList();
        if (rows.isNotEmpty) {
          widgets.add(
            _section(
              '${occurrenceStatusLabel(status)}: ${PersianNumbers.format(rows.length)}',
              rows.map(_occurrenceTile).toList(),
            ),
          );
        }
      }
      if (report.occurrences.isEmpty) {
        widgets.add(const Text(PersianCopy.reportsPageContentMessage3));
      }
    }
    if (_combined || _kind == PersonalReportKind.cashFlow) {
      if (_kind == PersonalReportKind.cashFlow) {
        widgets.addAll(_cashCharts(report, data));
      }
      widgets.add(const Text(PersianCopy.reportsPageContentMessage4));
      if (_tagSource == ReportTagSource.relatedAllocation ||
          _commitment != null ||
          _cycle != null) {
        widgets.add(const Text(PersianCopy.reportsPageContentMessage5));
      }
      for (final total in report.cashTotals.entries) {
        final rows = report.movements
            .where(
              (m) =>
                  m.entry.amount.currency == total.key &&
                  [
                    AccountEntryType.income,
                    AccountEntryType.expense,
                    AccountEntryType.refund,
                  ].contains(m.cashType),
            )
            .toList();
        widgets.add(
          _section(
            PersianCopy.reportsPageContentMessage6((total.key).toString()),
            [
              _moneyChart(PersianCopy.reportsPageContentMessage7, total.key, {
                PersianCopy.financePageBuildFiltersItems2: total.value.incoming,
                PersianCopy.financePageBuildFiltersItems3: total.value.outgoing,
                PersianCopy.reportsPageContentMessage8: total.value.net,
              }),
              Text(
                PersianCopy.financePageBuildSummaryChildren2(
                  (_money(total.value.incoming, total.key)).toString(),
                ),
              ),
              Text(
                PersianCopy.financePageBuildSummaryChildren3(
                  (_money(total.value.outgoing, total.key)).toString(),
                ),
              ),
              Text(
                PersianCopy.financePageBuildSummaryChildren4(
                  (_money(total.value.net, total.key)).toString(),
                ),
              ),
              ...rows.map((m) => _movementTile(m, data)),
            ],
            expanded: true,
          ),
        );
      }
      if (report.cashTotals.isEmpty) {
        widgets.add(const Text(PersianCopy.reportsPageContentMessage9));
      }
      widgets.add(
        _select<ReportGrouping>(
          PersianCopy.reportsPageContentMessage10,
          _grouping,
          const {
            ReportGrouping.day: PersianCopy.reportsPageContentMessage11,
            ReportGrouping.month: PersianCopy.reportsPageContentMessage12,
            ReportGrouping.category: PersianCopy.financePageBuildFiltersHint2,
            ReportGrouping.account: PersianCopy.quickAddSheetBuildLabelText,
          },
          (v) => _grouping = v ?? ReportGrouping.month,
        ),
      );
      final groups = <String, List<ReportMovement>>{};
      for (final m in report.movements) {
        if (![
          AccountEntryType.income,
          AccountEntryType.expense,
          AccountEntryType.refund,
        ].contains(m.cashType)) {
          continue;
        }
        final jalali = JalaliDate.fromDateTime(m.entry.occurredAt.toLocal());
        final label = switch (_grouping) {
          ReportGrouping.day => _date(m.entry.occurredAt),
          ReportGrouping.month => PersianDateFormatter.month(jalali),
          ReportGrouping.category =>
            m.category ?? PersianCopy.financeReportsKeyMessage,
          ReportGrouping.account =>
            data.accounts
                    .where((a) => a.id == m.entry.accountId)
                    .firstOrNull
                    ?.name ??
                PersianCopy.quickAddSheetBuildLabelText,
        };
        (groups['$label — ${m.entry.amount.currency}'] ??= []).add(m);
      }
      for (final currency in report.cashTotals.keys) {
        final values = <String, int>{};
        for (final group in groups.entries) {
          if (group.value.first.entry.amount.currency != currency) continue;
          final total = ReportCashTotal();
          for (final movement in group.value) {
            total.add(movement);
          }
          values[group.key] = total.net;
        }
        widgets.add(
          _moneyChart(
            PersianCopy.reportsPageContentMessage13((currency).toString()),
            currency,
            values,
          ),
        );
      }
      for (final group in groups.entries) {
        final total = ReportCashTotal();
        for (final m in group.value) {
          total.add(m);
        }
        widgets.add(
          _section(
            PersianCopy.reportsPageContentMessage14(
              (group.key).toString(),
              (_money(
                total.net,
                group.value.first.entry.amount.currency,
              )).toString(),
            ),
            [
              _moneyChart(
                PersianCopy.reportsPageContentMessage15,
                group.value.first.entry.amount.currency,
                {
                  PersianCopy.financePageBuildFiltersItems2: total.incoming,
                  PersianCopy.financePageBuildFiltersItems3: total.outgoing,
                  PersianCopy.reportsPageContentMessage8: total.net,
                },
              ),
              ...group.value.map((m) => _movementTile(m, data)),
            ],
          ),
        );
      }
    }
    if (_combined ||
        [
          PersonalReportKind.settlement,
          PersonalReportKind.recurringFinance,
          PersonalReportKind.upcoming,
        ].contains(_kind)) {
      widgets.add(const Text(PersianCopy.reportsPageContentMessage16));
      final groups = <String, List<ReportSettlement>>{};
      for (final s in report.settlements) {
        if (_kind == PersonalReportKind.recurringFinance &&
            !isRecurringExpense(s)) {
          continue;
        }
        final key = PersianCopy.reportsPageFiltersChildren7(
          (s.expectation.direction == FinancialExpectationDirection.incoming
                  ? PersianCopy.financePageResultCategory
                  : PersianCopy.reportsPageFiltersChildren12)
              .toString(),
          (s.expectation.currency ?? PersianCopy.smsReviewEditorBuildChildren3)
              .toString(),
        );
        (groups[key] ??= []).add(s);
      }
      for (final group in groups.entries) {
        final expected = group.value.fold(
          0,
          (sum, s) => sum + s.expectation.amount,
        );
        final remaining = group.value.fold(0, (sum, s) => sum + s.remaining);
        final allocated = group.value.fold(0, (sum, s) => sum + s.allocated);
        final currency = group.value.first.expectation.currency;
        widgets.add(
          _section(group.key, [
            FinancialReportChart(
              title: PersianCopy.reportsPageContentTitle2,
              labels: const [PersianCopy.reportsPageContentLabels],
              style: FinancialChartStyle.stacked,
              format: (v) => _money(v, currency),
              series: [
                for (final state in FinancialDueState.values)
                  FinancialChartSeries(
                    switch (state) {
                      FinancialDueState.settled =>
                        PersianCopy.reportsPageFinancialDueStateSettled,
                      FinancialDueState.partial =>
                        PersianCopy.reportsPageFinancialDueStatePartial,
                      FinancialDueState.pending =>
                        PersianCopy.reportsPageFinancialDueStatePending,
                      FinancialDueState.overdue =>
                        PersianCopy.reportsPageFinancialDueStateOverdue,
                    },
                    [
                      group.value
                          .where((s) => financialDueState(s, _now) == state)
                          .fold<int>(
                            0,
                            (sum, s) =>
                                sum +
                                (state == FinancialDueState.settled
                                    ? s.expectation.amount
                                    : s.remaining),
                          ),
                    ],
                  ),
              ],
            ),
            if (_kind == PersonalReportKind.recurringFinance)
              ..._recurringCharts(group.value, currency),
            for (final state in FinancialDueState.values)
              Text(
                PersianCopy.reportsPageContentMessage17(
                  (switch (state) {
                    FinancialDueState.settled =>
                      PersianCopy.reportsPageFinancialDueStateSettled,
                    FinancialDueState.partial =>
                      PersianCopy.reportsPageFinancialDueStatePartial2,
                    FinancialDueState.pending =>
                      PersianCopy.reportsPageFinancialDueStatePending,
                    FinancialDueState.overdue =>
                      PersianCopy.reportsPageFinancialDueStateOverdue,
                  }).toString(),
                  (PersianNumbers.format(
                    group.value
                        .where((s) => financialDueState(s, _now) == state)
                        .length,
                  )).toString(),
                ),
              ),
            _moneyChart(PersianCopy.reportsPageContentMessage18, currency, {
              PersianCopy.reportsPageContentMessage19: expected,
              PersianCopy.reportsPageContentMessage20: allocated,
              PersianCopy.reportsPageContentMessage21: remaining,
            }),
            Text(
              PersianCopy.reportsPageContentMessage22(
                (_money(expected, currency)).toString(),
                (_money(allocated, currency)).toString(),
                (_money(remaining, currency)).toString(),
              ),
            ),
            for (final s in group.value)
              ListTile(
                title: Text(s.row.commitment.title),
                subtitle: Text(
                  PersianCopy.reportsPageContentSubtitle2(
                    (_date(s.row.occurrence.currentScheduledAt)).toString(),
                    (_settlementLabel(s.state)).toString(),
                    (_money(s.expectation.amount, currency)).toString(),
                    (_money(s.remaining, currency)).toString(),
                    (s.excess > 0
                            ? PersianCopy.reportsPageContentSubtitle(
                                (_money(s.excess, currency)).toString(),
                              )
                            : '')
                        .toString(),
                  ),
                ),
                onTap: widget.onOpenCommitment == null
                    ? null
                    : () => _open(
                        () => widget.onOpenCommitment!(s.row.commitment),
                      ),
              ),
          ], expanded: true),
        );
      }
      if (groups.isEmpty) {
        widgets.add(const Text(PersianCopy.reportsPageContentMessage23));
      }
    }
    if (_kind == PersonalReportKind.packages ||
        _kind == PersonalReportKind.topic) {
      widgets.add(
        Text(PersianCopy.reportsPageContentMessage24((_date(_to)).toString())),
      );
      for (final p in report.packages) {
        widgets.add(
          _section(
            PersianCopy.reportsPageContentMessage25(
              (p.commitment.title).toString(),
              (_date(p.plan.validFrom)).toString(),
            ),
            [
              if (p.hasRecordedGrant)
                ReportBarChart(
                  title: PersianCopy.reportsPageContentTitle3,
                  data: [
                    for (final e in {
                      PersianCopy.reportsPageContentData: p.balance.granted,
                      PersianCopy.reportsPageContentData2: p.balance.consumed,
                      PersianCopy.reportsPageContentMessage21:
                          p.balance.remaining,
                    }.entries)
                      ReportBarDatum(
                        e.key,
                        e.value,
                        '${PersianNumbers.format(e.value)} ${_unit(p.plan.unitType)}',
                      ),
                  ],
                ),
              Text(
                PersianCopy.reportsPageContentMessage26(
                  (PersianNumbers.format(p.plan.totalUnits)).toString(),
                  (_unit(p.plan.unitType)).toString(),
                ),
              ),
              if (p.hasRecordedGrant)
                Text(
                  PersianCopy.reportsPageContentMessage27(
                    (PersianNumbers.format(p.balance.granted)).toString(),
                    (PersianNumbers.format(p.balance.consumed)).toString(),
                    (PersianNumbers.format(p.balance.remaining)).toString(),
                    (_unit(p.plan.unitType)).toString(),
                  ),
                ),
              if (!p.hasRecordedGrant)
                const Text(PersianCopy.reportsPageContentMessage28),
              Text(
                PersianCopy.reportsPageContentMessage30(
                  (p.plan.plannedExpiry == null
                          ? PersianCopy.reportsPageContentMessage29
                          : _date(p.plan.plannedExpiry!))
                      .toString(),
                ),
              ),
              if (p.plan.plannedExpiry != null &&
                  reportDate(p.plan.plannedExpiry!).isBefore(_to))
                const Text(PersianCopy.reportsPageContentMessage31),
              Text(
                PersianCopy.reportsPageContentMessage34(
                  (p.cycle.plannedEndDate == null
                          ? PersianCopy.reportsPageContentMessage32
                          : _date(p.cycle.plannedEndDate!))
                      .toString(),
                  (p.cycle.actualEndDate == null
                          ? PersianCopy.reportsPageContentMessage33
                          : _date(p.cycle.actualEndDate!))
                      .toString(),
                ),
              ),
              if (p.movements.isEmpty)
                const Text(PersianCopy.reportsPageContentMessage35),
              for (final e in p.movements)
                ListTile(
                  title: Text(
                    '${_ledgerLabel(e.type)}: ${PersianNumbers.format(e.units)} ${_unit(p.plan.unitType)}',
                  ),
                  subtitle: Text(
                    PersianCopy.weekTimelineViewAgendaDelegate2(
                      (_date(e.occurredAt)).toString(),
                      (e.note == null
                              ? ''
                              : PersianCopy.reportsPageContentSubtitle3(
                                  (e.note).toString(),
                                ))
                          .toString(),
                    ),
                  ),
                ),
            ],
            expanded: true,
          ),
        );
      }
      if (report.packages.isEmpty) {
        widgets.add(const Text(PersianCopy.reportsPageContentMessage36));
      }
    }
    if (_kind == PersonalReportKind.upcoming) {
      widgets.add(
        ReportBarChart(
          title: PersianCopy.reportsPageContentTitle4,
          data: [
            ReportBarDatum(
              PersianCopy.reportsPageContentData3,
              report.occurrences.length,
              PersianNumbers.format(report.occurrences.length),
            ),
            ReportBarDatum(
              PersianCopy.reportsPageContentData4,
              report.previews.length,
              PersianNumbers.format(report.previews.length),
            ),
          ],
        ),
      );
      widgets.add(
        _section(
          PersianCopy.reportsPageContentMessage37(
            (PersianNumbers.format(report.previews.length)).toString(),
          ),
          [
            const Text(PersianCopy.reportsPageContentMessage38),
            for (final p in report.previews)
              ListTile(
                title: Text(
                  data.commitments
                      .where((c) => c.id == p.commitmentId)
                      .first
                      .title,
                ),
                subtitle: Text(
                  PersianCopy.reportsPageContentSubtitle4(
                    (_date(p.slot.date)).toString(),
                  ),
                ),
              ),
          ],
          expanded: true,
        ),
      );
      if (report.previews.isNotEmpty) {
        widgets.add(const Text(PersianCopy.reportsPageContentMessage39));
      }
    }
    if (_kind == PersonalReportKind.attention) {
      widgets.add(
        ReportBarChart(
          title: PersianCopy.reportsPageContentTitle5,
          data: [
            ReportBarDatum(
              PersianCopy.reportsPageContentData5,
              report.occurrences.length,
              PersianNumbers.format(report.occurrences.length),
            ),
            ReportBarDatum(
              PersianCopy.reportsPageContentData6,
              report.unreviewed.length,
              PersianNumbers.format(report.unreviewed.length),
            ),
          ],
        ),
      );
      widgets.add(
        _section(
          PersianCopy.reportsPageContentMessage40(
            (PersianNumbers.format(report.unreviewed.length)).toString(),
          ),
          [
            for (final m in report.movements.where(
              (m) => report.unreviewed.containsKey(m.entry.id),
            ))
              ListTile(
                title: Text(
                  m.entry.note ?? PersianCopy.reportsPageContentTitle6,
                ),
                subtitle: Text(
                  PersianCopy.reportsPageContentSubtitle5(
                    (_money(
                      report.unreviewed[m.entry.id]!.remainderMinorUnits,
                      m.entry.amount.currency,
                    )).toString(),
                    (_date(m.entry.occurredAt)).toString(),
                  ),
                ),
                onTap: widget.onOpenTransaction == null
                    ? null
                    : () => _open(() => widget.onOpenTransaction!(m.entry.id)),
              ),
          ],
          expanded: true,
        ),
      );
    }
    if (_kind == PersonalReportKind.accounts) {
      widgets.add(const Text(PersianCopy.reportsPageContentMessage41));
      for (final a in report.accounts) {
        widgets.add(
          _section(a.account.name, [
            _moneyChart(
              PersianCopy.reportsPageContentMessage42,
              a.account.currency,
              {
                PersianCopy.reportsPageContentMessage43: a.opening,
                PersianCopy.reportsPageContentMessage44: a.movement,
                PersianCopy.reportsPageContentMessage45: a.closing,
              },
            ),
            FinancialReportChart(
              title: PersianCopy.reportsPageContentTitle7,
              style: FinancialChartStyle.line,
              labels: accountBalanceSeries(
                data,
                a.account.id,
                _filter,
              ).map((p) => _date(p.date)).toList(),
              series: [
                FinancialChartSeries(
                  PersianCopy.reportsPageContentSeries,
                  accountBalanceSeries(
                    data,
                    a.account.id,
                    _filter,
                  ).map((p) => p.amount).toList(),
                ),
              ],
              format: (v) => _money(v, a.account.currency),
            ),
            Text(
              PersianCopy.reportsPageContentMessage46(
                (_money(a.opening, a.account.currency)).toString(),
              ),
            ),
            Text(
              PersianCopy.reportsPageContentMessage47(
                (_money(a.movement, a.account.currency)).toString(),
              ),
            ),
            Text(
              PersianCopy.reportsPageContentMessage48(
                (_money(a.closing, a.account.currency)).toString(),
              ),
            ),
            const Text(PersianCopy.reportsPageContentMessage49),
            ...report.movements
                .where((m) => m.entry.accountId == a.account.id)
                .map((m) => _movementTile(m, data)),
          ], expanded: true),
        );
      }
      if (report.accounts.isEmpty) {
        widgets.add(const Text(PersianCopy.reportsPageContentMessage50));
      }
    }
    return widgets;
  }

  List<Widget> _cashCharts(PersonalReport report, ReportSnapshot data) {
    final previousFilter = precedingPeriod(_filter);
    final previous = buildPersonalReport(
      data,
      previousFilter,
      kind: PersonalReportKind.cashFlow,
      now: _now,
    );
    final result = <Widget>[
      Text(
        PersianCopy.reportsPageResultMessage(
          (_date(previousFilter.from)).toString(),
          (_date(previousFilter.to)).toString(),
        ),
      ),
    ];
    for (final currency in {
      ...report.cashTotals.keys,
      ...previous.cashTotals.keys,
    }) {
      final current = report.cashTotals[currency] ?? ReportCashTotal();
      final old = previous.cashTotals[currency] ?? ReportCashTotal();
      result.add(
        FinancialReportChart(
          title: PersianCopy.reportsPageCashChartsTitle((currency).toString()),
          style: FinancialChartStyle.grouped,
          labels: const [
            PersianCopy.reportsPageCashChartsLabels,
            PersianCopy.reportsPageCashChartsLabels2,
          ],
          series: [
            FinancialChartSeries(PersianCopy.financePageBuildFiltersItems2, [
              old.incoming,
              current.incoming,
            ]),
            FinancialChartSeries(PersianCopy.financePageBuildFiltersItems3, [
              old.outgoing,
              current.outgoing,
            ]),
            FinancialChartSeries(PersianCopy.reportsPageContentMessage8, [
              old.net,
              current.net,
            ]),
          ],
          format: (v) => _money(v, currency),
        ),
      );
      final months = monthlyCashTotals(report.movements, currency, _filter);
      final keys = months.keys.toList()..sort();
      result.add(
        FinancialReportChart(
          title: PersianCopy.reportsPageCashChartsTitle2((currency).toString()),
          style: FinancialChartStyle.grouped,
          labels: keys.map(PersianNumbers.format).toList(),
          series: [
            FinancialChartSeries(
              PersianCopy.financePageBuildFiltersItems2,
              keys.map((k) => months[k]!.incoming).toList(),
            ),
            FinancialChartSeries(
              PersianCopy.financePageBuildFiltersItems3,
              keys.map((k) => months[k]!.outgoing).toList(),
            ),
          ],
          format: (v) => _money(v, currency),
        ),
      );
      for (final type in [AccountEntryType.expense, AccountEntryType.income]) {
        final shares = categoryShares(report.movements, currency, type);
        result.add(
          FinancialReportChart(
            title: PersianCopy.reportsPageFiltersChildren7(
              (type == AccountEntryType.expense
                      ? PersianCopy.reportsPageCashChartsTitle4
                      : PersianCopy.reportsPageCashChartsTitle3)
                  .toString(),
              (currency).toString(),
            ),
            style: FinancialChartStyle.donut,
            labels: shares.keys.toList(),
            series: [
              FinancialChartSeries(
                PersianCopy.reportsPageCashChartsSeries,
                shares.values.toList(),
              ),
            ],
            format: (v) => _money(v, currency),
          ),
        );
      }
    }
    return result;
  }

  List<Widget> _recurringCharts(List<ReportSettlement> rows, String? currency) {
    final months = recurringSettlementMonths(rows);
    final keys = months.keys.toList()..sort();
    return [
      const Text(PersianCopy.reportsPageRecurringChartsMessage),
      FinancialReportChart(
        title: PersianCopy.reportsPageRecurringChartsTitle,
        style: FinancialChartStyle.line,
        positions: keys.map((key) {
          final parts = key.split('-').map(int.parse).toList();
          return parts[0] * 12 + parts[1];
        }).toList(),
        labels: keys.map(PersianNumbers.format).toList(),
        series: [
          FinancialChartSeries(
            PersianCopy.reportsPageContentMessage19,
            keys
                .map(
                  (k) => months[k]!.fold<int>(
                    0,
                    (a, s) => a + s.expectation.amount,
                  ),
                )
                .toList(),
          ),
          FinancialChartSeries(
            PersianCopy.reportsPageRecurringChartsSeries,
            keys
                .map((k) => months[k]!.fold<int>(0, (a, s) => a + s.allocated))
                .toList(),
          ),
        ],
        format: (v) => _money(v, currency),
      ),
    ];
  }

  Widget _moneyChart(String title, String? currency, Map<String, int> values) =>
      ReportBarChart(
        title: title,
        data: [
          for (final entry in values.entries)
            ReportBarDatum(
              entry.key,
              entry.value,
              _money(entry.value, currency),
            ),
        ],
      );

  Widget _section(
    String title,
    List<Widget> children, {
    bool expanded = false,
  }) => ExpansionTile(
    key: PageStorageKey('report-section:$title'),
    title: Text(title),
    initiallyExpanded: expanded,
    childrenPadding: const EdgeInsets.all(PlanActSpacing.md),
    children: children,
  );
  Widget _occurrenceTile(ReportOccurrence r) => ListTile(
    title: Text(r.commitment.title),
    subtitle: Text(
      PersianCopy.reportsPageOccurrenceTileSubtitle4(
        (_date(r.occurrence.currentScheduledAt)).toString(),
        (occurrenceStatusLabel(r.occurrence.status)).toString(),
        (r.actual == null || r.actual!.outcome == ActualOutcome.reopened
                ? PersianCopy.reportsPageOccurrenceTileSubtitle
                : '\n${_outcome(r.actual!.outcome)}')
            .toString(),
        (_kind == PersonalReportKind.changes
                ? PersianCopy.reportsPageOccurrenceTileSubtitle2(
                    (_date(r.occurrence.originalScheduledAt)).toString(),
                  )
                : '')
            .toString(),
        (r.commitment.status == CommitmentStatus.archived
                ? PersianCopy.reportsPageOccurrenceTileSubtitle3
                : '')
            .toString(),
      ),
    ),
    onTap: widget.onOpenCommitment == null
        ? null
        : () => _open(() => widget.onOpenCommitment!(r.commitment)),
  );
  Widget _movementTile(ReportMovement m, ReportSnapshot data) => ListTile(
    title: Text(m.entry.note ?? m.entry.category ?? _entryLabel(m.entry.type)),
    subtitle: Text(
      PersianCopy.reportsPageMovementTileSubtitle(
        (_date(m.entry.occurredAt)).toString(),
        (_entryLabel(m.entry.type)).toString(),
        (_money(m.minorUnits, m.entry.amount.currency)).toString(),
        (data.accounts
                    .where((a) => a.id == m.entry.accountId)
                    .firstOrNull
                    ?.name ??
                PersianCopy.quickAddSheetBuildLabelText)
            .toString(),
      ),
    ),
    onTap:
        widget.onOpenTransaction == null ||
            ![
              AccountEntryType.income,
              AccountEntryType.expense,
            ].contains(m.entry.type)
        ? null
        : () => _open(() => widget.onOpenTransaction!(m.entry.id)),
  );
}

String _settlementLabel(ReportSettlementState state) => switch (state) {
  ReportSettlementState.unpaid =>
    PersianCopy.reportsPageReportSettlementStateUnpaid,
  ReportSettlementState.partial =>
    PersianCopy.reportsPageReportSettlementStatePartial,
  ReportSettlementState.settled =>
    PersianCopy.reportsPageReportSettlementStateSettled,
  ReportSettlementState.overpaid =>
    PersianCopy.reportsPageReportSettlementStateOverpaid,
};
String _unit(EntitlementUnitType unit) => switch (unit) {
  EntitlementUnitType.session =>
    PersianCopy.reportsPageEntitlementUnitTypeSession,
  EntitlementUnitType.hour => PersianCopy.reportsPageEntitlementUnitTypeHour,
  EntitlementUnitType.visit => PersianCopy.reportsPageEntitlementUnitTypeVisit,
  EntitlementUnitType.credit =>
    PersianCopy.reportsPageEntitlementUnitTypeCredit,
};
String _ledgerLabel(EntitlementEntryType type) => switch (type) {
  EntitlementEntryType.grant =>
    PersianCopy.reportsPageEntitlementEntryTypeGrant,
  EntitlementEntryType.consume =>
    PersianCopy.reportsPageEntitlementEntryTypeConsume,
  EntitlementEntryType.restore => PersianCopy.inboxPageRejectLabel,
  EntitlementEntryType.adjustment =>
    PersianCopy.reportsPageEntitlementEntryTypeAdjustment,
  EntitlementEntryType.expire =>
    PersianCopy.reportsPageEntitlementEntryTypeExpire,
  EntitlementEntryType.refund =>
    PersianCopy.reportsPageEntitlementEntryTypeRefund,
};
String _outcome(ActualOutcome outcome) => switch (outcome) {
  ActualOutcome.completed => PersianCopy.occurrenceCompleted,
  ActualOutcome.attended => PersianCopy.reportsPageActualOutcomeAttended,
  ActualOutcome.cancelled => PersianCopy.reportsPageActualOutcomeCancelled,
  ActualOutcome.missed => PersianCopy.reportsPageActualOutcomeMissed,
  ActualOutcome.noShow => PersianCopy.occurrenceSkipped,
  ActualOutcome.partial => PersianCopy.reportsPageActualOutcomePartial,
  ActualOutcome.reopened => PersianCopy.reportsPageActualOutcomeReopened,
};
String _entryLabel(AccountEntryType type) => switch (type) {
  AccountEntryType.openingBalance =>
    PersianCopy.transactionDirectionAccountEntryTypeOpeningBalance,
  AccountEntryType.income => PersianCopy.financePageResultCategory,
  AccountEntryType.expense => PersianCopy.reportsPageFiltersChildren12,
  AccountEntryType.transferIn =>
    PersianCopy.transactionDirectionAccountEntryTypeTransferIn,
  AccountEntryType.transferOut =>
    PersianCopy.transactionDirectionAccountEntryTypeTransferOut,
  AccountEntryType.adjustment =>
    PersianCopy.reportsPageAccountEntryTypeAdjustment,
  AccountEntryType.refund =>
    PersianCopy.transactionDirectionAccountEntryTypeRefund,
  AccountEntryType.reversal =>
    PersianCopy.transactionDirectionAccountEntryTypeReversal,
};
