import 'dart:async';

import 'package:planact/core/ids/stable_id.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/logging/app_logger.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/inbox_review_projection.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({
    super.key,
    required this.inbox,
    required this.finance,
    this.smsSource,
    this.onDetermineRelationship,
  });

  final InboxUseCases inbox;
  final FinanceRepository finance;
  final AndroidSmsSource? smsSource;
  final Future<void> Function(StableId transactionId)? onDetermineRelationship;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with WidgetsBindingObserver {
  StreamSubscription<AndroidSmsMessage>? _smsSubscription;
  bool _reloading = false;
  bool _reloadRequested = false;
  static const _logger = AppLogger();
  static const _projection = InboxReviewProjection();
  List<InboxReviewItem> _items = const [];
  List<FinancialAccount> _accounts = const [];
  bool _loading = true;
  bool _working = false;
  bool? _smsAccess;
  String? _smsError;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _smsSubscription = widget.smsSource?.messages.listen(
      (_) async {
        // The broadcast may precede insertion by the default SMS application.
        // Import only provider rows; never create a second broadcast identity.
        await Future<void>.delayed(const Duration(seconds: 2));
        if (mounted) await _reload();
      },
      onError: (Object error) {
        if (mounted) {
          setState(
            () => _smsError =
                'دریافت پیامک قطع شد؛ برای همگام‌سازی دوباره تلاش کنید.',
          );
        }
      },
    );
    _reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_working) _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_reloading) {
      _reloadRequested = true;
      return;
    }
    _reloading = true;
    if (mounted) setState(() => _loading = true);
    try {
      await _syncSms();
      final suggestions = await widget.inbox.listPendingSuggestions();
      final imports = await widget.inbox.repository.listImports();
      final accounts = await widget.finance.listAccounts();
      final entries = await widget.finance.listEntries();
      final items = _projection.build(
        suggestions: suggestions,
        imports: imports,
        accounts: accounts,
        entries: entries,
      );
      if (!mounted) return;
      setState(() {
        _items = items;
        _accounts = accounts;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      _logger.error(
        'Inbox reload failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (!mounted) return;
      setState(() {
        _error = 'بارگذاری صف بررسی انجام نشد.';
        _loading = false;
      });
    } finally {
      _reloading = false;
      if (_reloadRequested && mounted) {
        _reloadRequested = false;
        unawaited(_reload());
      }
    }
  }

  Future<void> _syncSms() async {
    final source = widget.smsSource;
    if (source == null) return;
    try {
      final access = await source.hasAccess();
      if (!access) {
        if (mounted) {
          setState(() {
            _smsAccess = false;
            _smsError = null;
          });
        }
        return;
      }
      final messages = await source.readRelevantMessages();
      var unsupported = 0;
      var failed = 0;
      for (final message in messages) {
        try {
          await widget.inbox.stageSms(
            rawText: message.body,
            sourceKey: message.sourceKey,
            currency: 'IRR',
            importedAt: message.receivedAt,
          );
        } on DuplicateSmsImport {
          // Already persisted under another provider identity (e.g. restore).
        } on ValidationError {
          unsupported++;
        } on Exception {
          failed++;
        }
      }
      if (mounted) {
        setState(() {
          _smsAccess = true;
          _smsError = failed > 0
              ? 'ثبت برخی پیامک‌ها انجام نشد؛ دوباره تلاش کنید.'
              : unsupported > 0
              ? 'برخی پیامک‌ها قابل تشخیص نبودند و تراکنشی از آن‌ها ثبت نشد.'
              : null;
        });
      }
    } catch (error) {
      _logger.error(
        'SMS sync failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) {
        setState(() {
          _smsError = 'خواندن پیامک‌ها انجام نشد.';
        });
      }
    }
  }

  Future<void> _enableSms() async {
    final source = widget.smsSource;
    if (source == null || _working) return;
    final consent = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('دسترسی به پیامک‌های بانکی'),
        content: const Text(
          'برای ورود پیامک‌های بانکی، دسترسی خواندن و دریافت پیامک لازم است. '
          'پیامک‌های مرتبط فقط روی دستگاه بررسی و در صف بررسی ثبت می‌شوند؛ '
          'تراکنش مالی بدون تأیید شما ثبت نمی‌شود. می‌توانید دسترسی را در تنظیمات دستگاه لغو کنید.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('فعلاً نه'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ادامه'),
          ),
        ],
      ),
    );
    if (consent != true || !mounted) return;

    // Do not start an Android permission transition while the Flutter dialog
    // is still being removed. On some Android versions this leaves the
    // activity window behind a black scrim and the platform Future pending.
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted) return;
    setState(() => _working = true);
    try {
      final requestStarted = await source.requestAccess().timeout(
        const Duration(seconds: 5),
        onTimeout: () =>
            throw TimeoutException('SMS permission request timed out'),
      );
      if (!requestStarted) {
        if (mounted) {
          setState(() {
            _smsAccess = false;
            _smsError = 'مجوز پیامک فعال نیست؛ تنظیمات برنامه را بررسی کنید.';
          });
        }
        return;
      }

      var granted = await source.hasAccess();
      final deadline = DateTime.now().add(const Duration(seconds: 25));
      while (!granted && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        granted = await source.hasAccess();
      }
      if (!mounted) return;
      if (granted) {
        await _reload();
      } else {
        setState(() {
          _smsAccess = false;
          _smsError = 'دسترسی پیامک داده نشد. برای فعال‌سازی دوباره تلاش کنید یا مجوز را در تنظیمات برنامه فعال کنید.';
        });
      }
    } catch (error) {
      _logger.error(
        'SMS permission request failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) {
        setState(
          () => _smsError = error is TimeoutException
              ? 'درخواست مجوز پاسخ نداد. مجوز پیامک را از تنظیمات برنامه بررسی کنید.'
              : 'درخواست دسترسی انجام نشد؛ دوباره تلاش کنید.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _confirm(InboxReviewItem item) async {
    final compatible = _accounts
        .where(
          (account) =>
              account.status == FinancialAccountStatus.active &&
              account.currency == item.suggestion.draft.amount.currency,
        )
        .toList();
    final account =
        item.account ?? (compatible.length == 1 ? compatible.single : null);
    if (account == null) {
      await _showMessage(
        'انتخاب حساب لازم است',
        compatible.isEmpty
            ? 'حساب فعال سازگار با واحد پول پیدا نشد.'
            : 'چند حساب سازگار وجود دارد؛ ابتدا از ویرایش حساب را انتخاب کنید.',
      );
      return;
    }
    AccountEntry? imported;
    await _runAction(() async {
      imported = await widget.inbox.confirm(
        suggestion: item.suggestion,
        account: account,
        finance: widget.finance,
      );
    });
    if (mounted && imported != null) {
      final id = imported!.id;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تراکنش ثبت شد.'),
          action: widget.onDetermineRelationship == null
              ? null
              : SnackBarAction(
                  label: 'تعیین ارتباط',
                  onPressed: () => widget.onDetermineRelationship!(id),
                ),
        ),
      );
    }
  }

  Future<void> _reject(InboxReviewItem item) async {
    await _runAction(() => widget.inbox.reject(item.suggestion));
  }

  Future<void> _edit(InboxReviewItem item) async {
    final draft = item.suggestion.draft;
    final amountController = TextEditingController(
      text: draft.amount.minorUnits.toString(),
    );
    final merchantController = TextEditingController(
      text: draft.merchant ?? '',
    );
    final referenceController = TextEditingController(
      text: draft.reference ?? '',
    );
    var selectedDirection = draft.direction;
    final type = await showPlanActFormSheet<String>(
      context: context,
      title: 'ویرایش پیشنهاد تراکنش',
      primaryLabel: 'ذخیره و بررسی',
      builder: (_) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('مقادیر تشخیص‌داده‌شده از قبل وارد شده‌اند.'),
          const SizedBox(height: PlanActSpacing.md),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [MoneyInputFormatter()],
            decoration: const InputDecoration(labelText: 'مبلغ'),
          ),
          const SizedBox(height: PlanActSpacing.sm),
          TextField(
            controller: merchantController,
            decoration: const InputDecoration(labelText: 'پذیرنده یا شرح'),
          ),
          const SizedBox(height: PlanActSpacing.sm),
          TextField(
            controller: referenceController,
            decoration: const InputDecoration(labelText: 'شناسه پیگیری'),
          ),
          const SizedBox(height: PlanActSpacing.sm),
          DropdownButtonFormField<TransactionDirection>(
            initialValue: draft.direction,
            decoration: const InputDecoration(labelText: 'نوع تراکنش'),
            items: const [
              DropdownMenuItem(
                value: TransactionDirection.outgoing,
                child: Text('هزینه / برداشت'),
              ),
              DropdownMenuItem(
                value: TransactionDirection.incoming,
                child: Text('درآمد / واریز'),
              ),
            ],
            onChanged: (value) {
              if (value != null) selectedDirection = value;
            },
          ),
        ],
      ),
      onPrimary: () => Navigator.of(context).pop('save'),
    );
    if (type != 'save' || !mounted) {
      amountController.dispose();
      merchantController.dispose();
      referenceController.dispose();
      return;
    }
    final amount = int.tryParse(
      amountController.text.replaceAll(',', '').replaceAll('،', ''),
    );
    final merchant = merchantController.text.trim();
    final reference = referenceController.text.trim();
    amountController.dispose();
    merchantController.dispose();
    referenceController.dispose();
    if (amount == null || amount <= 0) {
      await _showMessage('مبلغ نامعتبر است', 'مبلغ باید بزرگ‌تر از صفر باشد.');
      return;
    }
    final edited = TransactionDraft(
      id: draft.id,
      stagedImportId: draft.stagedImportId,
      amount: Money(minorUnits: amount, currency: draft.amount.currency),
      occurredAt: draft.occurredAt,
      type: selectedDirection == TransactionDirection.incoming
          ? 'income'
          : 'expense',
      merchant: merchant.isEmpty ? null : merchant,
      reference: reference.isEmpty ? null : reference,
      direction: selectedDirection,
      bank: draft.bank,
      accountHint: draft.accountHint,
      balance: draft.balance,
      quality: draft.quality,
      confidence: draft.confidence,
    );
    await _runAction(() async {
      await widget.inbox.edit(item.suggestion, edited);
    });
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await action();
      await _reload();
    } catch (error) {
      _logger.error(
        'Inbox action failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) {
        await _showMessage('عملیات انجام نشد', 'اطلاعات در صف بررسی حفظ شد.');
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _showMessage(String title, String message) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('بستن'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 320,
              child: _InboxStateCard(
                icon: Icons.error_outline,
                title: 'صف بررسی در دسترس نیست',
                message: _error!,
                actionLabel: 'تلاش دوباره',
                onAction: _reload,
              ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.all(PlanActSpacing.md),
        children: [
          _SmsStatusCard(
            access: _smsAccess,
            error: _smsError,
            onRefresh: _reload,
            onEnable:
                widget.smsSource != null && !_working && _smsAccess != true
                ? _enableSms
                : null,
          ),
          const SizedBox(height: PlanActSpacing.md),
          if (_items.isEmpty)
            const SizedBox(
              height: 300,
              child: _InboxStateCard(
                icon: Icons.inbox_outlined,
                title: 'صف بررسی خالی است',
                message: 'اطلاعات واردشده و پیشنهادهای مالی برای بررسی در اینجا نمایش داده می‌شوند.',
              ),
            )
          else ...[
            Text(
              'نیازمند بررسی · ${_items.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: PlanActSpacing.sm),
            for (final item in _items) ...[
              _ReviewCard(
                item: item,
                busy: _working,
                onConfirm: () => _confirm(item),
                onEdit: () => _edit(item),
                onReject: () => _reject(item),
              ),
              const SizedBox(height: PlanActSpacing.sm),
            ],
          ],
        ],
      ),
    );
  }
}

class _SmsStatusCard extends StatelessWidget {
  const _SmsStatusCard({
    required this.access,
    required this.error,
    required this.onRefresh,
    required this.onEnable,
  });
  final bool? access;
  final String? error;
  final VoidCallback onRefresh;
  final VoidCallback? onEnable;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(
        access == true ? Icons.sms_outlined : Icons.sms_failed_outlined,
      ),
      title: const Text('ورود پیامک بانکی'),
      subtitle: Text(
        error ??
            switch (access) {
              true =>
                'مجوز فعال است؛ پیامک‌های مرتبط به‌صورت محلی بررسی می‌شوند.',
              false => 'دسترسی خواندن و دریافت پیامک فعال نیست؛ ورود خودکار انجام نمی‌شود.',
              null => 'وضعیت مجوز پیامک هنوز بررسی نشده است.',
            },
      ),
      trailing: onEnable == null
          ? IconButton(
              tooltip: 'بازخوانی',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            )
          : TextButton(onPressed: onEnable, child: const Text('فعال‌سازی')),
    ),
  );
}

class _ReviewCard extends StatefulWidget {
  const _ReviewCard({
    required this.item,
    required this.busy,
    required this.onConfirm,
    required this.onEdit,
    required this.onReject,
  });

  final InboxReviewItem item;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onReject;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final draft = widget.item.suggestion.draft;
    final amount = PersianMoneyText.money(draft.amount);
    final date = PersianDateFormatter.date(
      JalaliDate.fromDateTime(draft.occurredAt),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(PlanActSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    draft.merchant ?? draft.type,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(amount, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.item.sourceLabel} · ${_direction(draft.direction)} · $date',
            ),
            Text(
              'حساب پیشنهادی: ${widget.item.account?.name ?? 'نیازمند انتخاب'}',
            ),
            for (final warning in widget.item.warnings)
              Text(
                'هشدار: $warning',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            TextButton.icon(
              onPressed: () => setState(() => _showDetails = !_showDetails),
              icon: Icon(_showDetails ? Icons.expand_less : Icons.expand_more),
              label: Text(_showDetails ? 'بستن جزئیات' : 'جزئیات پیشنهاد'),
            ),
            if (_showDetails) ...[
              if (draft.bank != null) Text('بانک: ${draft.bank}'),
              if (draft.accountHint != null)
                Text('راهنمای حساب: ${draft.accountHint}'),
              if (draft.reference != null)
                Text('شناسه پیگیری: ${draft.reference}'),
              Text(
                'چرا این پیشنهاد؟',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              for (final reason in widget.item.reasons) Text('• $reason'),
            ],
            const SizedBox(height: PlanActSpacing.sm),
            Wrap(
              spacing: PlanActSpacing.sm,
              runSpacing: PlanActSpacing.xs,
              children: [
                FilledButton.icon(
                  onPressed: widget.busy ? null : widget.onConfirm,
                  icon: const Icon(Icons.check),
                  label: const Text('تأیید و ثبت'),
                ),
                OutlinedButton.icon(
                  onPressed: widget.busy ? null : widget.onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('ویرایش'),
                ),
                TextButton.icon(
                  onPressed: widget.busy ? null : widget.onReject,
                  icon: const Icon(Icons.close),
                  label: const Text('رد کردن'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _direction(TransactionDirection direction) => switch (direction) {
    TransactionDirection.incoming => 'درآمد',
    TransactionDirection.outgoing => 'هزینه',
    TransactionDirection.unknown => 'نوع نامشخص',
  };
}

class _InboxStateCard extends StatelessWidget {
  const _InboxStateCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    ),
  );
}
