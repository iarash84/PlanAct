import 'package:flutter/material.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/features/commitments/application/commitment_correction.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';

class CommitmentCorrectionCard extends StatefulWidget {
  const CommitmentCorrectionCard({
    super.key,
    required this.repository,
    required this.commitmentId,
    required this.onSaved,
    this.reminders,
  });
  final CommitmentCorrectionRepository repository;
  final StableId commitmentId;
  final Future<void> Function() onSaved;
  final ReminderService? reminders;
  @override
  State<CommitmentCorrectionCard> createState() =>
      _CommitmentCorrectionCardState();
}

class _CommitmentCorrectionCardState extends State<CommitmentCorrectionCard> {
  final _value = TextEditingController();
  final _reason = TextEditingController();
  bool _credit = false;
  bool _busy = false;
  String? _error;
  String? _success;
  late Future<List<CommitmentCorrectionRecord>> _history;
  @override
  void initState() {
    super.initState();
    _history = widget.repository.history(widget.commitmentId);
  }

  @override
  void dispose() {
    _value.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final value = int.tryParse(
        PersianNumbers.normalizeDigits(_value.text.trim()),
      );
      if (value == null) throw const ValidationError('عدد معتبر وارد کنید.');
      final preview = await widget.repository.preview(
        CommitmentCorrectionRequest(
          commitmentId: widget.commitmentId,
          reason: _reason.text,
          scheduleCount: _credit ? null : value,
          creditDelta: _credit ? value : null,
        ),
        DateTime.now(),
      );
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('پیش‌نمایش اصلاح'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.hasHistory
                      ? 'تعهد دارای سابقه است؛ سوابق محفوظ می‌مانند.'
                      : 'تعهد ثبت‌شده بدون سابقهٔ نتیجه؛ این اصلاح ثبت می‌شود.',
                ),
                Text(
                  'تعداد برنامه: ${_number(preview.beforeCount)} ← ${_number(preview.afterCount)}',
                ),
                Text(
                  'نوبت آیندهٔ افزوده در بازهٔ تولید: ${_number(preview.futureAdded)}',
                ),
                Text('نوبت آیندهٔ لغوشده: ${_number(preview.futureCancelled)}'),
                Text(
                  'اعتبار باقی‌مانده: ${_number(preview.remainingBefore)} ← ${_number(preview.remainingAfter)}',
                ),
                Text(
                  _credit
                      ? 'فقط اعتبار بسته اصلاح می‌شود؛ برنامه و مصرف قبلی تغییر نمی‌کنند.'
                      : 'از فردا؛ الگوی تکرار و نوبت‌های محافظت‌شده تغییر نمی‌کنند. اعتبار بسته تغییر نمی‌کند.',
                ),
                const Text(
                  'هیچ سابقه‌ای حذف نمی‌شود. اصلاح بعدی نیاز به تأیید جداگانه دارد.',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ادامهٔ ویرایش'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأیید اصلاح'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await widget.repository.confirm(preview, DateTime.now());
      _history = widget.repository.history(widget.commitmentId);
      var pending = false;
      try {
        await widget.reminders?.reconcile(now: DateTime.now());
      } catch (_) {
        pending = true;
      }
      try {
        await widget.onSaved();
      } catch (_) {
        pending = true;
      }
      if (mounted) {
        setState(
          () => _success = pending
              ? 'اصلاح ثبت شد؛ هماهنگ‌سازی یا بازخوانی در انتظار است. صفحه را دوباره باز کنید.'
              : 'اصلاح ثبت شد؛ سوابق قبلی محفوظ است.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ValidationError
              ? error.message
              : 'اصلاح انجام نشد؛ ورودی‌ها محفوظ است. دوباره تلاش کنید.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _number(int? value) =>
      value == null ? '—' : PersianNumbers.format(value);
  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: const Text('اصلاح تعداد برنامه یا اعتبار بسته'),
      subtitle: const Text(
        'آزمایشی: اصلاح تعداد فقط برای برنامهٔ شمارشی و از فردا؛ اعتبار بسته مستقل است.',
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<bool>(
                initialValue: _credit,
                decoration: const InputDecoration(labelText: 'نوع اصلاح'),
                items: const [
                  DropdownMenuItem(
                    value: false,
                    child: Text('تعداد نوبت‌های برنامه'),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text('افزایش یا کاهش اعتبار بسته'),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _credit = value!;
                        _error = null;
                        _success = null;
                      }),
              ),
              TextField(
                controller: _value,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: _credit
                      ? 'تغییر اعتبار (مثلاً ۲ یا ۲-)'
                      : 'تعداد کل جدید برنامه',
                ),
              ),
              TextField(
                controller: _reason,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'دلیل اصلاح'),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_success != null) Text(_success!),
              FutureBuilder<List<CommitmentCorrectionRecord>>(
                future: _history,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return TextButton(
                      onPressed: () => setState(() {
                        _history = widget.repository.history(
                          widget.commitmentId,
                        );
                      }),
                      child: const Text('بازخوانی سوابق اصلاح'),
                    );
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  if (snapshot.data!.isEmpty) {
                    return const Text('اصلاح ثبت‌شده‌ای وجود ندارد.');
                  }
                  return ExpansionTile(
                    title: const Text('سوابق اصلاح'),
                    children: [
                      for (final record in snapshot.data!)
                        ListTile(
                          title: Text(record.reason),
                          subtitle: Text(
                            '${PersianDateFormatter.date(JalaliDate.fromDateTime(record.at.toLocal()))}\n'
                            'تعداد: ${_number(record.beforeCount)} ← ${_number(record.afterCount)}\n'
                            'اعتبار: ${_number(record.beforeRemaining)} ← ${_number(record.afterRemaining)}',
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (_busy) const LinearProgressIndicator(),
              FilledButton(
                onPressed: _busy ? null : _preview,
                child: const Text('بررسی اثر اصلاح'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
