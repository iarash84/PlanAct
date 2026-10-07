import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/money/money_input_formatter.dart';
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
  });
  final StableId transactionId;
  final ContextualReconciliation flow;
  @override
  State<TransactionRelationshipPage> createState() =>
      _TransactionRelationshipPageState();
}

class _TransactionRelationshipPageState
    extends State<TransactionRelationshipPage> {
  TransactionRelationshipContext? _context;
  StableId? _selected;
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
          _error = 'بارگذاری تراکنش انجام نشد؛ دوباره تلاش کنید.';
        });
      }
    }
  }

  Future<void> _save() async {
    final amount = int.tryParse(MoneyInputFormatter.normalize(_amount.text));
    if (_selected == null ||
        amount == null ||
        amount <= 0 ||
        amount > _context!.available.minorUnits) {
      setState(
        () => _error =
            'رخداد و مبلغ معتبر در محدودهٔ مبلغ باقی‌مانده را انتخاب کنید.',
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
          _error = 'ثبت ارتباط انجام نشد؛ انتخاب و مبلغ شما حفظ شده است. مبلغ باقی‌مانده را بازخوانی کنید و دوباره تلاش کنید.';
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
                  ? 'باقی‌ماندهٔ تراکنش مستقل ثبت شد؛ ارتباط‌های قبلی حفظ شدند.'
                  : 'بررسی ارتباط دوباره باز شد؛ اکنون می‌توانید ارتباط ثبت کنید.',
            ),
            action: SnackBarAction(
              label: 'بازگردانی',
              onPressed: () =>
                  _decide(independent: !independent, expected: review),
            ),
          ),
        );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'ثبت تصمیم انجام نشد؛ انتخاب و مبلغ شما حفظ شده است. اطلاعات را بازخوانی کنید و دوباره تلاش کنید.';
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
    if (date == null) return 'بدون تاریخ';
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
          title: const Text('تعیین ارتباط تراکنش'),
          leading: Navigator.of(context).canPop()
              ? BackButton(onPressed: _saving ? null : _back)
              : null,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(PlanActSpacing.lg),
                children: [
                  if (data != null) ...[
                    Text(
                      data.transaction.note ?? 'تراکنش بدون شرح',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'مبلغ تراکنش: ${PersianMoneyText.money(data.transaction.amount)}',
                    ),
                    Text('حساب: ${data.account?.name ?? 'حساب در دسترس نیست'}'),
                    Text(
                      'باقی‌مانده برای ارتباط: ${PersianMoneyText.money(data.available)}',
                    ),
                    const SizedBox(height: PlanActSpacing.lg),
                    if (data.review?.isIndependent == true) ...[
                      const Text(
                        'بررسی‌شده: باقی‌ماندهٔ تراکنش به تعهدی مربوط نیست.',
                      ),
                      const Text(
                        'برای ثبت ارتباط جدید، ابتدا بررسی را دوباره باز کنید. ارتباط‌های قبلی حفظ شده‌اند.',
                      ),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => _decide(independent: false),
                        child: const Text('بازگشایی بررسی ارتباط'),
                      ),
                    ] else if (data.review != null &&
                        data.available.minorUnits > 0) ...[
                      const Text(
                        'اگر مبلغ باقی‌مانده مستقل است، آن را صریحاً تأیید کنید. این تصمیم ارتباط‌های قبلی، موجودی و تاریخچه را تغییر نمی‌دهد.',
                      ),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => _decide(independent: true),
                        child: const Text('به تعهدی مربوط نیست'),
                      ),
                    ],
                    if (_saving) ...[
                      const LinearProgressIndicator(),
                      const Text('در حال ثبت…'),
                    ],
                    if (data.review?.isIndependent != true) ...[
                      const Text(
                        'تعهد و نوبت مربوط را انتخاب کنید؛ هیچ نتیجه یا مبلغ مورد انتظاری تغییر نمی‌کند.',
                      ),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'جستجوی تعهد',
                        ),
                        enabled: !_saving,
                        onChanged: (v) => setState(() => _query = v.trim()),
                      ),
                      if (data.targets.isEmpty)
                        const Text('هنوز رخدادی برای انتخاب ثبت نشده است.'),
                      if (data.targets.isNotEmpty && targets.isEmpty)
                        const Text('تعهدی با این عبارت پیدا نشد.'),
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
                            '${_date(target)}${target.commitment.status == CommitmentStatus.archived ? ' · بایگانی‌شده' : ''}',
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
                        keyboardType: TextInputType.number,
                        inputFormatters: const [MoneyInputFormatter()],
                        decoration: const InputDecoration(
                          labelText: 'مبلغ ارتباط',
                        ),
                      ),
                      const SizedBox(height: PlanActSpacing.md),
                      FilledButton(
                        onPressed: _saving || data.available.minorUnits == 0
                            ? null
                            : _save,
                        child: Text(_saving ? 'در حال ثبت…' : 'تأیید ارتباط'),
                      ),
                    ],
                    if (data.available.minorUnits == 0)
                      const Text('مبلغ این تراکنش به‌طور کامل مرتبط شده است.'),
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
                    child: const Text('بازخوانی'),
                  ),
                ],
              ),
      ),
    );
  }
}
