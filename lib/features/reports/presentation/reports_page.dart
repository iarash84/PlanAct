import 'package:flutter/material.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/presentation/planact_jalali_date_picker.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/domain/financial_expectation.dart';
import 'package:planact/features/reports/application/reports_reader.dart';
import 'package:planact/features/reports/domain/personal_reports.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/presentation/occurrence_status_label.dart';
import 'package:planact/features/sessions/domain/entitlement.dart';

String personalReportLabel(PersonalReportKind kind) => switch (kind) {
  PersonalReportKind.overview => 'مرور هفته و ماه',
  PersonalReportKind.performance => 'برنامه در برابر عملکرد',
  PersonalReportKind.attention => 'موارد نیازمند پیگیری',
  PersonalReportKind.cashFlow => 'دخل‌وخرج',
  PersonalReportKind.settlement => 'پرداخت‌های برنامه‌ریزی‌شده و واقعی',
  PersonalReportKind.packages => 'وضعیت کلاس‌ها و بسته‌ها',
  PersonalReportKind.topic => 'گزارش موضوعی و هشتگ',
  PersonalReportKind.upcoming => 'برنامه و پرداخت‌های پیش‌رو',
  PersonalReportKind.changes => 'جابه‌جایی و لغو برنامه‌ها',
  PersonalReportKind.accounts => 'گردش و موجودی حساب‌ها',
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
        _error = 'گزارش بارگیری نشد؛ دوباره تلاش کنید.';
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
        const SnackBar(
          content: Text('بازه باید به‌ترتیب تاریخ و حداکثر ۳۶۶ روز باشد.'),
        ),
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
      case 'امروز':
        start = today;
        end = today;
      case 'این هفته':
        start = today.addDays(1 - today.weekDay);
        end = start.addDays(6);
      case 'ماه گذشته':
        start = month.addMonths(-1);
        end = month.addDays(-1);
      case '۳۰ روز آینده':
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
      ? '${PersianNumbers.format(amount)} (واحد نامشخص)'
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
        DropdownMenuItem<T>(value: null, child: const Text('همه')),
        ...choices.entries.map(
          (e) => DropdownMenuItem<T>(value: e.key, child: Text(e.value)),
        ),
      ],
      onChanged: _loading ? null : (v) => setState(() => changed(v)),
    ),
  );

  Widget _filters(ReportSnapshot data) => ExpansionTile(
    key: const PageStorageKey('report-filters'),
    title: const Text('فیلترهای گزارش'),
    subtitle: Text(
      'هشتگ‌ها: ${PersianNumbers.format(_tags.length)}؛ ${_query.isEmpty ? 'بدون جست‌وجو' : _query}',
    ),
    childrenPadding: const EdgeInsets.all(PlanActSpacing.lg),
    children: [
      TextField(
        key: const PageStorageKey('report-search'),
        controller: _searchController,
        decoration: const InputDecoration(
          labelText: 'جست‌وجو در عنوان و توضیحات',
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
      const SizedBox(height: PlanActSpacing.md),
      _select<ReportTagMode>('روش انتخاب هشتگ', _tagMode, const {
        ReportTagMode.any: 'حداقل یکی از هشتگ‌ها',
        ReportTagMode.all: 'همهٔ هشتگ‌ها',
        ReportTagMode.untagged: 'بدون هشتگ',
      }, (v) => _tagMode = v ?? ReportTagMode.any),
      if (data.tags.isEmpty) const Text('هنوز هشتگی ثبت نشده است.'),
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
        title: const Text('حذف هشتگ از نتایج'),
        children: [
          Wrap(
            spacing: PlanActSpacing.sm,
            children: [
              for (final tag in data.tags)
                FilterChip(
                  label: Text('حذف ${tag.displayLabel}'),
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
          'تعهد',
          _commitment,
          {for (final c in data.commitments) c.id: c.title},
          (v) {
            _commitment = v;
            _cycle = null;
          },
        ),
        _select<StableId>('دوره یا بسته', _cycle, {
          for (final c in data.cycles.where(
            (c) => _commitment == null || c.commitmentId == _commitment,
          ))
            c.id:
                '${data.commitments.where((o) => o.id == c.commitmentId).firstOrNull?.title ?? 'تعهد'} — ${_date(c.startDate)}',
        }, (v) => _cycle = v),
        _select<CommitmentKind>('نوع تعهد', _commitmentKind, const {
          CommitmentKind.oneOff: 'یک‌باره',
          CommitmentKind.recurring: 'تکرارشونده',
        }, (v) => _commitmentKind = v),
        if (_kind != PersonalReportKind.packages)
          _select<OccurrenceStatus>('وضعیت نوبت', _status, {
            for (final s in OccurrenceStatus.values)
              s: occurrenceStatusLabel(s),
          }, (v) => _status = v),
      ],
      if (_financial || _kind == PersonalReportKind.settlement) ...[
        _select<StableId>('حساب', _account, {
          for (final a in data.accounts) a.id: a.name,
        }, (v) => _account = v),
        _select<String>('واحد پول', _currency, {
          for (final c in {
            ...data.accounts.map((a) => a.currency),
            ...data.entries.map((e) => e.amount.currency),
          })
            c: c,
        }, (v) => _currency = v),
        if (_kind != PersonalReportKind.accounts)
          _select<AccountEntryType>('جهت مالی', _entryType, const {
            AccountEntryType.income: 'دریافت',
            AccountEntryType.expense: 'پرداخت',
            AccountEntryType.refund: 'بازپرداخت',
          }, (v) => _entryType = v),
      ],
      if (_kind == PersonalReportKind.cashFlow) ...[
        _select<String>('دسته‌بندی', _category, {
          for (final c
              in data.entries
                  .map((e) => e.category)
                  .whereType<String>()
                  .toSet())
            c: c,
        }, (v) => _category = v),
        _select<AccountEntrySource>('منبع تراکنش', _source, const {
          AccountEntrySource.manual: 'دستی',
          AccountEntrySource.sms: 'پیامک',
          AccountEntrySource.import: 'واردشده',
        }, (v) => _source = v),
      ],
      if (_kind == PersonalReportKind.cashFlow ||
          _kind == PersonalReportKind.topic)
        _select<ReportTagSource>('مبنای هشتگ تراکنش', _tagSource, const {
          ReportTagSource.direct: 'هشتگ خود تراکنش',
          ReportTagSource.relatedAllocation: 'سهم تطبیق‌یافته با تعهد هشتگ‌دار',
        }, (v) => _tagSource = v ?? ReportTagSource.direct),
      if (_kind == PersonalReportKind.settlement)
        _select<ReportSettlementState>('وضعیت تسویه', _settlement, {
          for (final s in ReportSettlementState.values) s: _settlementLabel(s),
        }, (v) => _settlement = v),
      if (_kind == PersonalReportKind.changes)
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('فیلتر بر اساس تاریخ اولیه'),
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
        child: const Text('پاک‌کردن فیلترها (تاریخ حفظ می‌شود)'),
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
        title: const Text('گزارش‌ها'),
        actions: [
          IconButton(
            tooltip: 'تازه‌کردن گزارش',
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
                  decoration: const InputDecoration(labelText: 'نوع گزارش'),
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
                  children: [
                    for (final p in [
                      'امروز',
                      'این هفته',
                      'این ماه',
                      'ماه گذشته',
                      '۳۰ روز آینده',
                    ])
                      ActionChip(
                        label: Text(p),
                        onPressed: _loading ? null : () => _preset(p),
                      ),
                  ],
                ),
                Wrap(
                  spacing: PlanActSpacing.sm,
                  children: [
                    OutlinedButton(
                      onPressed: _loading ? null : () => _pickDate(true),
                      child: Text('از ${_date(_from)}'),
                    ),
                    OutlinedButton(
                      onPressed: _loading ? null : () => _pickDate(false),
                      child: Text('تا ${_date(_to)}'),
                    ),
                  ],
                ),
                const Text(
                  'فقط داده‌های ثبت‌شده روی این دستگاه؛ پایان بازه شامل تمام روز است.',
                ),
                if (_loading) const LinearProgressIndicator(),
                if (_error != null) ...[
                  Text(_error!),
                  TextButton(
                    onPressed: _load,
                    child: const Text('تلاش دوباره'),
                  ),
                ],
                if (data != null && _error == null) ...[
                  _filters(data),
                  if (_tags.isNotEmpty || _excludedTags.isNotEmpty)
                    Text(
                      'انتخاب: ${data.tags.where((t) => _tags.contains(t.id)).map((t) => t.displayLabel).join('، ')}؛ حذف: ${data.tags.where((t) => _excludedTags.contains(t.id)).map((t) => t.displayLabel).join('، ')}',
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
      widgets.add(
        const Text(
          'نتیجهٔ فعلی برای تاریخ نوبت‌های انتخاب‌شده؛ ثبت نتیجه، زمان واقعی انجام را مشخص نمی‌کند.',
        ),
      );
      final resolved = report.occurrences.where((r) => r.resolved).length;
      widgets.add(
        Text(
          'نوبت‌های ثبت‌شده: ${PersianNumbers.format(report.occurrences.length)}؛ تعیین‌وضعیت‌شده: ${PersianNumbers.format(resolved)}',
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
        widgets.add(const Text('نوبت ثبت‌شده‌ای با این فیلترها وجود ندارد.'));
      }
    }
    if (_combined || _kind == PersonalReportKind.cashFlow) {
      widgets.add(
        const Text(
          'انتقال، موجودی اولیه و تعدیل در دخل‌وخرج حساب نمی‌شوند؛ بازپرداخت در ورودی لحاظ می‌شود.',
        ),
      );
      if (_tagSource == ReportTagSource.relatedAllocation ||
          _commitment != null ||
          _cycle != null) {
        widgets.add(
          const Text(
            'فقط سهم تطبیق‌یافتهٔ تراکنش‌های معتبر؛ این نما گزارش کل گردش نقدی نیست.',
          ),
        );
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
          _section('جریان نقدی — ${total.key}', [
            Text('ورودی: ${_money(total.value.incoming, total.key)}'),
            Text('خروجی: ${_money(total.value.outgoing, total.key)}'),
            Text('خالص: ${_money(total.value.net, total.key)}'),
            ...rows.map((m) => _movementTile(m, data)),
          ], expanded: true),
        );
      }
      if (report.cashTotals.isEmpty) {
        widgets.add(const Text('دریافت یا پرداختی با این فیلترها وجود ندارد.'));
      }
      widgets.add(
        _select<ReportGrouping>('گروه‌بندی گردش', _grouping, const {
          ReportGrouping.day: 'روز',
          ReportGrouping.month: 'ماه شمسی',
          ReportGrouping.category: 'دسته‌بندی',
          ReportGrouping.account: 'حساب',
        }, (v) => _grouping = v ?? ReportGrouping.month),
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
          ReportGrouping.category => m.category ?? 'بدون دسته‌بندی',
          ReportGrouping.account =>
            data.accounts
                    .where((a) => a.id == m.entry.accountId)
                    .firstOrNull
                    ?.name ??
                'حساب',
        };
        (groups['$label — ${m.entry.amount.currency}'] ??= []).add(m);
      }
      for (final group in groups.entries) {
        final total = ReportCashTotal();
        for (final m in group.value) {
          total.add(m);
        }
        widgets.add(
          _section(
            '${group.key}؛ خالص: ${_money(total.net, group.value.first.entry.amount.currency)}',
            group.value.map((m) => _movementTile(m, data)).toList(),
          ),
        );
      }
    }
    if (_combined ||
        [
          PersonalReportKind.settlement,
          PersonalReportKind.upcoming,
        ].contains(_kind)) {
      widgets.add(
        const Text(
          'تسویه بر اساس سررسید نوبت و تطبیق‌های معتبر فعلی است؛ تاریخ پرداخت ممکن است خارج از بازه باشد.',
        ),
      );
      final groups = <String, List<ReportSettlement>>{};
      for (final s in report.settlements) {
        final key =
            '${s.expectation.direction == FinancialExpectationDirection.incoming ? 'دریافت' : 'پرداخت'} — ${s.expectation.currency ?? 'واحد نامشخص'}';
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
            Text(
              'برنامه: ${_money(expected, currency)}؛ تطبیق: ${_money(allocated, currency)}؛ باقی‌مانده: ${_money(remaining, currency)}',
            ),
            for (final s in group.value)
              ListTile(
                title: Text(s.row.commitment.title),
                subtitle: Text(
                  '${_date(s.row.occurrence.currentScheduledAt)}؛ ${_settlementLabel(s.state)}\nبرنامه: ${_money(s.expectation.amount, currency)}؛ باقی‌مانده: ${_money(s.remaining, currency)}${s.excess > 0 ? '\nمازاد: ${_money(s.excess, currency)}' : ''}',
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
      if (report.settlements.isEmpty) {
        widgets.add(
          const Text('انتظار مالی ثبت‌شده‌ای با این فیلترها وجود ندارد.'),
        );
      }
    }
    if (_kind == PersonalReportKind.packages ||
        _kind == PersonalReportKind.topic) {
      widgets.add(
        Text(
          'اعتبار دفتر تا پایان ${_date(_to)}؛ تعداد برنامه‌ریزی‌شده و حضور، معادل مصرف اعتبار نیست.',
        ),
      );
      for (final p in report.packages) {
        widgets.add(
          _section('${p.commitment.title} — بسته از ${_date(p.plan.validFrom)}', [
            Text(
              'اعتبار تنظیم‌شدهٔ بسته: ${PersianNumbers.format(p.plan.totalUnits)} ${_unit(p.plan.unitType)}',
            ),
            if (p.hasRecordedGrant)
              Text(
                'اعتبار: ${PersianNumbers.format(p.balance.granted)}؛ کسر دفتر: ${PersianNumbers.format(p.balance.consumed)}؛ باقی‌مانده: ${PersianNumbers.format(p.balance.remaining)} ${_unit(p.plan.unitType)}',
              ),
            if (!p.hasRecordedGrant)
              const Text(
                'اعطای اعتبار در دفتر ثبت نشده است؛ باقی‌ماندهٔ قابل اتکا در دسترس نیست.',
              ),
            Text(
              'اعتبار تا: ${p.plan.plannedExpiry == null ? 'تاریخ تعیین نشده' : _date(p.plan.plannedExpiry!)}',
            ),
            if (p.plan.plannedExpiry != null &&
                reportDate(p.plan.plannedExpiry!).isBefore(_to))
              const Text(
                'تاریخ اعتبار گذشته است؛ باقی‌ماندهٔ دفتر به معنی امکان استفاده نیست.',
              ),
            Text(
              'پایان برنامه: ${p.cycle.plannedEndDate == null ? 'تعیین نشده' : _date(p.cycle.plannedEndDate!)}؛ پایان واقعی: ${p.cycle.actualEndDate == null ? 'ثبت نشده' : _date(p.cycle.actualEndDate!)}',
            ),
            if (p.movements.isEmpty)
              const Text('در این بازه تغییری در دفتر اعتبار ثبت نشده است.'),
            for (final e in p.movements)
              ListTile(
                title: Text(
                  '${_ledgerLabel(e.type)}: ${PersianNumbers.format(e.units)} ${_unit(p.plan.unitType)}',
                ),
                subtitle: Text(
                  '${_date(e.occurredAt)}${e.note == null ? '' : '؛ ${e.note}'}',
                ),
              ),
          ], expanded: true),
        );
      }
      if (report.packages.isEmpty) {
        widgets.add(const Text('بسته‌ای با این فیلترها وجود ندارد.'));
      }
    }
    if (_kind == PersonalReportKind.upcoming) {
      widgets.add(
        _section(
          'پیش‌نمایش ذخیره‌نشده: ${PersianNumbers.format(report.previews.length)}',
          [
            const Text(
              'این نوبت‌ها هنوز ثبت نشده‌اند و در شمارش عملکرد، تسویه و مصرف اعتبار وارد نمی‌شوند.',
            ),
            for (final p in report.previews)
              ListTile(
                title: Text(
                  data.commitments
                      .where((c) => c.id == p.commitmentId)
                      .first
                      .title,
                ),
                subtitle: Text('${_date(p.slot.date)}؛ پیش‌نمایش'),
              ),
          ],
          expanded: true,
        ),
      );
      if (report.previews.isNotEmpty) {
        widgets.add(
          const Text(
            'جمع مالی بالا فقط انتظارات ثبت‌شده را شامل می‌شود؛ مبلغ نوبت‌های پیش‌نمایش در آن نیست.',
          ),
        );
      }
    }
    if (_kind == PersonalReportKind.attention) {
      widgets.add(
        _section(
          'تراکنش‌های نیازمند تعیین ارتباط: ${PersianNumbers.format(report.unreviewed.length)}',
          [
            for (final m in report.movements.where(
              (m) => report.unreviewed.containsKey(m.entry.id),
            ))
              ListTile(
                title: Text(m.entry.note ?? 'تراکنش'),
                subtitle: Text(
                  'باقی‌مانده: ${_money(report.unreviewed[m.entry.id]!.remainderMinorUnits, m.entry.amount.currency)}؛ ${_date(m.entry.occurredAt)}',
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
      widgets.add(
        const Text(
          'موجودی از تمام دفتر حساب محاسبه می‌شود؛ هشتگ و جست‌وجو فقط ریز گردش را محدود می‌کنند. این موجودی الزاماً موجودی واقعی بانک نیست.',
        ),
      );
      for (final a in report.accounts) {
        widgets.add(
          _section(a.account.name, [
            Text('ابتدای دوره: ${_money(a.opening, a.account.currency)}'),
            Text(
              'خالص گردش کل دوره: ${_money(a.movement, a.account.currency)}',
            ),
            Text('پایان دوره: ${_money(a.closing, a.account.currency)}'),
            const Text('ریز گردش مطابق فیلترهای انتخاب‌شده:'),
            ...report.movements
                .where((m) => m.entry.accountId == a.account.id)
                .map((m) => _movementTile(m, data)),
          ], expanded: true),
        );
      }
      if (report.accounts.isEmpty) {
        widgets.add(const Text('حسابی با این فیلترها وجود ندارد.'));
      }
    }
    return widgets;
  }

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
      '${_date(r.occurrence.currentScheduledAt)}؛ ${occurrenceStatusLabel(r.occurrence.status)}'
      '${r.actual == null || r.actual!.outcome == ActualOutcome.reopened ? '\nنتیجهٔ واقعی ثبت نشده است.' : '\n${_outcome(r.actual!.outcome)}'}'
      '${_kind == PersonalReportKind.changes ? '\nتاریخ اولیه: ${_date(r.occurrence.originalScheduledAt)}' : ''}'
      '${r.commitment.status == CommitmentStatus.archived ? '؛ تعهد بایگانی‌شده' : ''}',
    ),
    onTap: widget.onOpenCommitment == null
        ? null
        : () => _open(() => widget.onOpenCommitment!(r.commitment)),
  );
  Widget _movementTile(ReportMovement m, ReportSnapshot data) => ListTile(
    title: Text(m.entry.note ?? m.entry.category ?? _entryLabel(m.entry.type)),
    subtitle: Text(
      '${_date(m.entry.occurredAt)}؛ ${_entryLabel(m.entry.type)}؛ ${_money(m.minorUnits, m.entry.amount.currency)}\n${data.accounts.where((a) => a.id == m.entry.accountId).firstOrNull?.name ?? 'حساب'}',
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
  ReportSettlementState.unpaid => 'تسویه نشده',
  ReportSettlementState.partial => 'تسویهٔ جزئی',
  ReportSettlementState.settled => 'تسویه شده',
  ReportSettlementState.overpaid => 'تطبیق دارای مازاد',
};
String _unit(EntitlementUnitType unit) => switch (unit) {
  EntitlementUnitType.session => 'جلسه',
  EntitlementUnitType.hour => 'ساعت',
  EntitlementUnitType.visit => 'مراجعه',
  EntitlementUnitType.credit => 'واحد اعتبار',
};
String _ledgerLabel(EntitlementEntryType type) => switch (type) {
  EntitlementEntryType.grant => 'اعطای اعتبار',
  EntitlementEntryType.consume => 'مصرف',
  EntitlementEntryType.restore => 'بازگردانی',
  EntitlementEntryType.adjustment => 'اصلاح اعتبار',
  EntitlementEntryType.expire => 'انقضا',
  EntitlementEntryType.refund => 'بازپرداخت اعتبار',
};
String _outcome(ActualOutcome outcome) => switch (outcome) {
  ActualOutcome.completed => 'انجام‌شده',
  ActualOutcome.attended => 'حضور',
  ActualOutcome.cancelled => 'لغو',
  ActualOutcome.missed => 'ازدست‌رفته',
  ActualOutcome.noShow => 'عدم حضور',
  ActualOutcome.partial => 'نتیجهٔ جزئی',
  ActualOutcome.reopened => 'بازگشایی‌شده',
};
String _entryLabel(AccountEntryType type) => switch (type) {
  AccountEntryType.openingBalance => 'موجودی اولیه',
  AccountEntryType.income => 'دریافت',
  AccountEntryType.expense => 'پرداخت',
  AccountEntryType.transferIn => 'انتقال ورودی',
  AccountEntryType.transferOut => 'انتقال خروجی',
  AccountEntryType.adjustment => 'تعدیل',
  AccountEntryType.refund => 'بازپرداخت',
  AccountEntryType.reversal => 'ثبت جبرانی',
};
