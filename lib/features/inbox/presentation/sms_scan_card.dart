import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
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
        setState(() => _error = PersianCopy.smsScanCardLoadMessage);
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
        title: const Text(PersianCopy.smsScanCardDaysTitle),
        content: const Text(PersianCopy.smsScanCardDaysContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(PersianCopy.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text(PersianCopy.smsScanCardDaysActions),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 7),
            child: const Text(PersianCopy.smsScanCardDaysActions2),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 30),
            child: const Text(PersianCopy.smsScanCardDaysActions3),
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
        setState(() => _error = PersianCopy.smsScanCardChooseMessage);
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
        setState(() => _error = PersianCopy.smsScanCardRunMessage);
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
          Text(planActL10n(context).smsScanCardBuildChildren),
          if (_scan != null)
            Text(
              _scan!.newOnly
                  ? planActL10n(
                      context,
                    ).smsScanCardBuildChildren2((_date(_scan!.from)).toString())
                  : planActL10n(context).smsScanCardBuildChildren3(
                      (_date(_scan!.from)).toString(),
                      (_date(_scan!.until)).toString(),
                    ),
            ),
          if (_scan != null)
            Text(
              planActL10n(context).smsScanCardBuildChildren4(
                (PersianNumbers.format(_scan!.inspected.toString())).toString(),
              ),
            ),
          if (_scan != null && _scan!.unsupported > 0)
            Text(planActL10n(context).smsScanCardBuildChildren5),
          if (_error != null) Text(_error!),
          if (_busy) const LinearProgressIndicator(),
          if (!_busy && _scan?.complete == true)
            Text(planActL10n(context).smsScanCardBuildChildren6),
          if (_busy)
            TextButton(
              onPressed: _command.cancel,
              child: Text(planActL10n(context).smsScanCardBuildChildren7),
            ),
          if (!_busy && _scan != null && (!_scan!.complete || _scan!.newOnly))
            TextButton(
              onPressed: widget.access ? _run : null,
              child: Text(
                _scan!.complete
                    ? planActL10n(context).smsScanCardBuildChildren8
                    : planActL10n(context).smsScanCardBuildChildren9,
              ),
            ),
          TextButton(
            onPressed: !_busy && widget.access ? _choose : null,
            child: Text(planActL10n(context).smsScanCardBuildChildren10),
          ),
        ],
      ),
    ),
  );
}
