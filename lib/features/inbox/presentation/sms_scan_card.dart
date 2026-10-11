import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';

class SmsScanCard extends StatefulWidget {
  const SmsScanCard({
    super.key,
    required this.inbox,
    required this.source,
    required this.access,
    required this.onChanged,
  });
  final InboxUseCases inbox;
  final AndroidSmsSource source;
  final bool access;
  final Future<void> Function() onChanged;
  @override
  State<SmsScanCard> createState() => _SmsScanCardState();
}

class _SmsScanCardState extends State<SmsScanCard> with WidgetsBindingObserver {
  late final SmsIngestion _command;
  SmsScan? _scan;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _command = SmsIngestion(widget.inbox, widget.source);
    _load();
  }

  Future<void> _load() async {
    try {
      final scan = await _command.load();
      if (mounted) setState(() => _scan = scan);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'بارگذاری وضعیت ورود پیامک انجام نشد.');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _command.cancel();
  }

  @override
  void dispose() {
    _command.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _choose() async {
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('انتخاب بازهٔ ورود پیامک'),
        content: const Text(
          'مجوز پیامک اجازهٔ خواندن تاریخچه نیست. بازه را انتخاب کنید؛ بررسی فقط روی دستگاه است و ثبت مالی نیاز به تأیید شما دارد.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('فقط پیامک‌های جدید از این لحظه'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 7),
            child: const Text('۷ روز گذشته'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 30),
            child: const Text('۳۰ روز گذشته'),
          ),
        ],
      ),
    );
    if (days == null || !mounted) return;
    try {
      final now = DateTime.now();
      await _command.consent(
        from: now.subtract(Duration(days: days)),
        until: now,
        newOnly: days == 0,
      );
      if (mounted) await _run();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'ذخیرهٔ انتخاب انجام نشد؛ دوباره تلاش کنید.');
      }
    }
  }

  Future<void> _run() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _command.run(
        onProgress: (scan) {
          if (mounted) setState(() => _scan = scan);
        },
      );
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'ورود متوقف شد؛ مجوز را بررسی و دوباره ادامه دهید. پیامک‌های ثبت‌شده حفظ شده‌اند.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _load();
        await widget.onChanged();
      }
    }
  }

  String _date(int milliseconds) => PersianDateFormatter.date(
    JalaliDate.fromDateTime(DateTime.fromMillisecondsSinceEpoch(milliseconds)),
  );
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(PlanActSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('ورود پیامک با انتخاب شما'),
          if (_scan != null)
            Text(
              _scan!.newOnly
                  ? 'فقط پیامک‌های جدید از ${_date(_scan!.from)}'
                  : 'از ${_date(_scan!.from)} تا ${_date(_scan!.until)}',
            ),
          if (_scan != null)
            Text(
              'تعداد پیامک‌های بررسی‌شده: ${PersianNumbers.format(_scan!.inspected.toString())}',
            ),
          if (_scan != null && _scan!.unsupported > 0)
            const Text(
              'برخی پیامک‌ها قابل تشخیص نبودند؛ تراکنشی از آن‌ها ثبت نشد.',
            ),
          if (_error != null) Text(_error!),
          if (_busy) const LinearProgressIndicator(),
          if (!_busy && _scan?.complete == true)
            const Text('بررسی بازه کامل شد.'),
          if (_busy)
            TextButton(
              onPressed: _command.cancel,
              child: const Text('توقف ورود پیامک'),
            ),
          if (!_busy && _scan != null && (!_scan!.complete || _scan!.newOnly))
            TextButton(
              onPressed: widget.access ? _run : null,
              child: Text(
                _scan!.complete
                    ? 'بررسی پیامک‌های جدید'
                    : 'ادامه / تلاش دوباره',
              ),
            ),
          TextButton(
            onPressed: !_busy && widget.access ? _choose : null,
            child: const Text('انتخاب بازهٔ پیامک'),
          ),
        ],
      ),
    ),
  );
}
