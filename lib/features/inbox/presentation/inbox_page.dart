import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/app/theme/planact_status_colors.dart';

import 'dart:async';

import 'package:planact/core/ids/stable_id.dart';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/logging/app_logger.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/financial_account_picker.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/presentation/sms_scan_card.dart';
import 'package:planact/features/inbox/application/inbox_review_projection.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({
    super.key,
    required this.inbox,
    required this.finance,
    this.smsSource,
    this.onDetermineRelationship,
    this.onDataChanged,
  });

  final Future<void> Function()? onDataChanged;
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
  bool _loading = true;
  bool _working = false;
  final Set<StableId> _pending = {};
  final ScrollController _scroll = ScrollController();
  SuggestionStatus? _status;
  String? _bank;
  bool _oldestFirst = false;
  List<String> _banks = [];
  int _epoch = 0;
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
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    if (_reloading) {
      _reloadRequested = true;
      return;
    }
    _reloading = true;
    final epoch = _epoch;
    try {
      await _syncSms();
      await widget.inbox.expireRawText();
      final suggestions = await widget.inbox.repository.listSuggestions();
      final imports = await widget.inbox.repository.listImports();
      final accounts = await widget.finance.listAccounts();
      final entries = await widget.finance.listEntries();
      final items = _projection.build(
        suggestions: suggestions,
        imports: imports,
        accounts: accounts,
        entries: entries,
        status: _status,
        bank: _bank,
        oldestFirst: _oldestFirst,
      );
      if (!mounted || epoch != _epoch) {
        _reloadRequested = true;
        return;
      }
      setState(() {
        _items = items;
        _banks = suggestions.map((s) => s.draft.bank ?? '').toSet().toList()
          ..sort();
        _error = null;
        _loading = false;
      });
    } catch (error) {
      _logger.error(
        'Inbox reload failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (!mounted) return;
      if (epoch != _epoch) {
        _reloadRequested = true;
        return;
      }
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
      // Permission is not consent to inspect historical provider rows.
      if (mounted) setState(() => _smsAccess = true);
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
    if (!_pending.add(item.suggestion.id)) return;
    setState(() => _epoch++);
    AccountEntry? imported;
    var refreshFailed = false;
    try {
      imported = await showModalBottomSheet<AccountEntry>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        builder: (_) => _ConfirmationSheet(
          item: item,
          inbox: widget.inbox,
          finance: widget.finance,
        ),
      );
      if (imported != null) {
        if (mounted) {
          setState(() {
            _epoch++;
            _items = _items
                .where((i) => i.suggestion.id != item.suggestion.id)
                .toList();
          });
        }
        try {
          await _reload();
          await widget.onDataChanged?.call();
        } catch (_) {
          // The durable confirmation succeeded; refresh failure is not a save failure.
          refreshFailed = true;
        }
      }
    } finally {
      if (mounted) setState(() => _pending.remove(item.suggestion.id));
    }
    if (mounted && imported != null) {
      final id = imported.id;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refreshFailed
                ? 'تراکنش ثبت شد؛ تازه‌سازی نمایش انجام نشد. دوباره تازه‌سازی کنید.'
                : 'تراکنش ثبت شد.',
          ),
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

  Future<void> _reject(InboxReviewItem item, {bool recover = false}) async {
    final id = item.suggestion.id;
    if (!_pending.add(id)) return;
    setState(() {
      _epoch++;
    });
    try {
      if (recover) {
        await widget.inbox.rollback(item.suggestion);
      } else {
        await widget.inbox.reject(item.suggestion);
      }
      if (!mounted) return;
      setState(() {
        _epoch++;
        _items = _items.where((i) => i.suggestion.id != id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            recover
                ? 'پیشنهاد به صف بررسی برگشت.'
                : 'پیشنهاد رد شد؛ تراکنشی حذف یا ثبت نشد.',
          ),
          action: recover
              ? null
              : SnackBarAction(
                  label: 'بازگردانی',
                  onPressed: () async {
                    final current =
                        (await widget.inbox.repository.listSuggestions())
                            .firstWhere((s) => s.id == id);
                    final restored = InboxReviewItem(
                      suggestion: current,
                      import: item.import,
                      proposedAction: item.proposedAction,
                      reasons: item.reasons,
                      warnings: item.warnings,
                      supportedActions: item.supportedActions,
                      account: item.account,
                    );
                    await _reject(restored, recover: true);
                  },
                ),
        ),
      );
      await _reload();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'ذخیره انجام نشد؛ پیشنهاد حفظ شد. دوباره تلاش کنید.',
            ),
            action: SnackBarAction(
              label: 'تلاش دوباره',
              onPressed: () => _reject(item, recover: recover),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _pending.remove(id));
    }
  }

  Future<void> _edit(InboxReviewItem item) async {
    if (!_pending.add(item.suggestion.id)) return;
    setState(() => _epoch++);
    try {
      final draft = item.suggestion.draft;
      final manualInput = PinnedMoneyInput(MoneyUnitScope.of(context));
      SmsMoneyUnit? selectedUnit = draft.currencyEvidence?.effectiveUnit;
      IranianMoneyUnit editUnit() => draft.currencyEvidence == null
          ? (draft.amount.currency == 'IRR'
                ? manualInput.unit
                : IranianMoneyUnit.rial)
          : selectedUnit == SmsMoneyUnit.toman
          ? IranianMoneyUnit.toman
          : IranianMoneyUnit.rial;
      final amountController = TextEditingController(
        text: editUnit().inputText(draft.amount.minorUnits),
      );
      final merchantController = TextEditingController(
        text: draft.merchant ?? '',
      );
      final referenceController = TextEditingController(
        text: draft.reference ?? '',
      );
      var selectedDirection = draft.direction;
      TransitionRoute<dynamic>? editRoute;
      final type = await showPlanActFormSheet<String>(
        context: context,
        title: 'ویرایش پیشنهاد تراکنش',
        primaryLabel: 'ذخیره و بررسی',
        builder: (sheetContext) {
          editRoute = ModalRoute.of(sheetContext) as TransitionRoute<dynamic>?;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('مقادیر تشخیص‌داده‌شده از قبل وارد شده‌اند.'),
              const SizedBox(height: PlanActSpacing.md),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: draft.currencyEvidence == null
                      ? 'مبلغ به ${manualInput.label(draft.amount.currency)}'
                      : 'مبلغ (واحد انتخابی)',
                ),
              ),
              const SizedBox(height: PlanActSpacing.sm),
              if (draft.currencyEvidence != null)
                DropdownButtonFormField<SmsMoneyUnit>(
                  initialValue: selectedUnit,
                  decoration: const InputDecoration(labelText: 'واحد مبلغ'),
                  items: [
                    for (final unit in SmsMoneyUnit.values)
                      DropdownMenuItem(value: unit, child: Text(unit.label)),
                  ],
                  onChanged: (value) => selectedUnit = value,
                )
              else
                const Text(
                  'واحد پیامک قدیمی نامشخص است؛ مقدار ذخیره‌شده بازتفسیر نمی‌شود.',
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
                initialValue: draft.direction == TransactionDirection.unknown
                    ? null
                    : draft.direction,
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
          );
        },
        onPrimary: () => Navigator.of(context).pop('save'),
      );
      // The popped sheet remains mounted during its reverse transition.
      await editRoute?.completed;
      if (type != 'save' || !mounted) {
        amountController.dispose();
        merchantController.dispose();
        referenceController.dispose();
        return;
      }
      final amount = editUnit().parse(amountController.text);
      final merchant = merchantController.text.trim();
      final reference = referenceController.text.trim();
      amountController.dispose();
      merchantController.dispose();
      referenceController.dispose();
      if (amount == null || amount <= 0) {
        await _showMessage(
          'مبلغ نامعتبر است',
          'مبلغ باید بزرگ‌تر از صفر باشد.',
        );
        return;
      }
      if (selectedDirection == TransactionDirection.unknown) {
        await _showMessage(
          'نوع تراکنش نامشخص است',
          'درآمد یا هزینه را صریحاً انتخاب کنید.',
        );
        return;
      }
      if (draft.currencyEvidence != null && selectedUnit == null) {
        await _showMessage(
          'واحد مبلغ نامشخص است',
          'ریال یا تومان را صریحاً انتخاب کنید.',
        );
        return;
      }
      final int canonicalAmount;
      try {
        canonicalAmount = amount;
      } catch (_) {
        await _showMessage(
          'مبلغ نامعتبر است',
          'مبلغ خارج از محدودهٔ مجاز است.',
        );
        return;
      }
      final edited = TransactionDraft(
        id: draft.id,
        stagedImportId: draft.stagedImportId,
        amount: Money(
          minorUnits: canonicalAmount,
          currency: draft.amount.currency,
        ),
        currencyEvidence: draft.currencyEvidence == null
            ? null
            : SmsCurrencyEvidence(
                sourceAmount: draft.currencyEvidence!.sourceAmount,
                detectedUnit: draft.currencyEvidence!.detectedUnit,
                selectedUnit: selectedUnit,
              ),
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
        dateSource: draft.dateSource,
        receivedAt: draft.receivedAt,
      );
      await _runAction(() async {
        await widget.inbox.edit(item.suggestion, edited);
      });
    } finally {
      if (mounted) setState(() => _pending.remove(item.suggestion.id));
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      _epoch++;
      await _reload();
    } catch (error) {
      _logger.error(
        'Inbox action failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) {
        await _showMessage('عملیات انجام نشد', 'اطلاعات در صف بررسی حفظ شد.');
      }
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
    if (_error != null && _items.isEmpty) {
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
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SmsStatusCard(
          access: _smsAccess,
          error: _smsError,
          onRefresh: _reload,
          onEnable: widget.smsSource != null && !_working && _smsAccess != true
              ? _enableSms
              : null,
        ),
        if (widget.smsSource != null && widget.inbox.repository is SmsScanStore)
          SmsScanCard(
            inbox: widget.inbox,
            source: widget.smsSource!,
            access: _smsAccess == true,
            onChanged: _reload,
          ),
        const SizedBox(height: PlanActSpacing.md),
        DropdownButtonFormField<SuggestionStatus>(
          initialValue: _status,
          decoration: const InputDecoration(labelText: 'وضعیت بررسی'),
          items: const [
            DropdownMenuItem(value: null, child: Text('نیازمند بررسی')),
            DropdownMenuItem(
              value: SuggestionStatus.rejected,
              child: Text('ردشده'),
            ),
            DropdownMenuItem(
              value: SuggestionStatus.confirmed,
              child: Text('تأییدشده'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _status = value;
              _epoch++;
            });
            _reload();
          },
        ),
        DropdownButtonFormField<String>(
          initialValue: _bank,
          decoration: const InputDecoration(labelText: 'بانک'),
          items: [
            const DropdownMenuItem(value: null, child: Text('همهٔ بانک‌ها')),
            for (final bank in _banks)
              DropdownMenuItem(
                value: bank,
                child: Text(bank.isEmpty ? 'بانک نامشخص' : bank),
              ),
          ],
          onChanged: (value) {
            setState(() {
              _bank = value;
              _epoch++;
            });
            _reload();
          },
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _oldestFirst = !_oldestFirst;
              _epoch++;
            });
            _reload();
          },
          icon: const Icon(Icons.sort),
          label: Text(
            _oldestFirst
                ? 'قدیمی‌ترین دریافت / ورود ابتدا'
                : 'جدیدترین دریافت / ورود ابتدا',
          ),
        ),
        if (_error != null) Text(_error!),
        if (_items.isEmpty)
          const SizedBox(
            height: 300,
            child: _InboxStateCard(
              icon: Icons.inbox_outlined,
              title: 'صف بررسی خالی است',
              message: 'اطلاعات واردشده و پیشنهادهای مالی برای بررسی در اینجا نمایش داده می‌شوند.',
            ),
          )
        else
          Text(
            '${switch (_status) {
              SuggestionStatus.rejected => 'ردشده',
              SuggestionStatus.confirmed => 'تأییدشده',
              _ => 'نیازمند بررسی',
            }} · ${PersianNumbers.format(_items.length)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
      ],
    );
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView.builder(
        controller: _scroll,
        key: const PageStorageKey('inbox-review'),
        padding: const EdgeInsets.all(PlanActSpacing.md),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _items.length + 1,
        findChildIndexCallback: (key) {
          if (key is! ValueKey<StableId>) return null;
          final index = _items.indexWhere((i) => i.suggestion.id == key.value);
          return index < 0 ? null : index + 1;
        },
        itemBuilder: (context, index) {
          if (index == 0) return header;
          final item = _items[index - 1];
          return _ReviewCard(
            key: ValueKey(item.suggestion.id),
            item: item,
            busy: _pending.contains(item.suggestion.id),
            onConfirm: () => _confirm(item),
            onEdit: () => _edit(item),
            onReject: () => _reject(
              item,
              recover: item.suggestion.status == SuggestionStatus.rejected,
            ),
          );
        },
      ),
    );
  }
}

class _ConfirmationSheet extends StatefulWidget {
  const _ConfirmationSheet({
    required this.item,
    required this.inbox,
    required this.finance,
  });
  final InboxReviewItem item;
  final InboxUseCases inbox;
  final FinanceRepository finance;
  @override
  State<_ConfirmationSheet> createState() => _ConfirmationSheetState();
}

class _ConfirmationSheetState extends State<_ConfirmationSheet> {
  FinancialAccount? _account;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    if (_saving) return;
    if (widget.item.suggestion.draft.currencyEvidence?.requiresSelection ==
        true) {
      setState(
        () => _error = 'واحد مبلغ نامشخص است؛ به ویرایش پیشنهاد بروید و ریال یا تومان را انتخاب کنید.',
      );
      return;
    }
    final account = _account;
    if (account == null) {
      setState(() => _error = 'حساب مالی را انتخاب کنید.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final entry = await widget.inbox.confirm(
        suggestion: widget.item.suggestion,
        account: account,
        finance: widget.finance,
      );
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop(entry);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = 'ثبت انجام نشد؛ پیشنهاد و انتخاب شما حفظ شده‌اند. اعتبار حساب را بررسی کنید و دوباره تلاش کنید.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: PlanActFormSheet(
      title: 'تأیید پیشنهاد تراکنش',
      primaryLabel: 'تأیید نهایی',
      isLoading: _saving,
      error: _error,
      onPrimary: _save,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget
                  .item
                  .suggestion
                  .draft
                  .currencyEvidence
                  ?.requiresSelection ==
              true)
            const Text(
              'واحد مبلغ پیامک نامشخص است؛ ابتدا در ویرایش پیشنهاد واحد را انتخاب کنید.',
            )
          else
            Text(
              PersianMoneyText.money(
                widget.item.suggestion.draft.amount,
                unit: MoneyUnitScope.of(context),
              ),
            ),
          Text(
            'تاریخ پیشنهادی برای ثبت: ${PersianDateFormatter.date(JalaliDate.fromDateTime(widget.item.suggestion.draft.occurredAt))}',
          ),
          if (widget.item.suggestion.draft.dateSource !=
              TransactionDateSource.extracted)
            const Text(
              'تاریخ تراکنش از پیامک استخراج نشده است؛ تأیید نهایی این تاریخ پیشنهادی را ثبت می‌کند.',
            ),
          Text(
            'حساب پیشنهادی: ${widget.item.account?.name ?? 'نیازمند انتخاب'}؛ انتخاب نهایی با شماست.',
          ),
          FinancialAccountPicker(
            repository: widget.finance,
            currency: widget.item.suggestion.draft.amount.currency,
            enabled: !_saving,
            onChanged: (account) => _account = account,
            onCreateAccount: () =>
                openFinancialAccountCreation(context, widget.finance),
          ),
        ],
      ),
    ),
  );
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
                'مجوز فعال است؛ بازهٔ خواندن پیامک را جداگانه انتخاب کنید.',
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
    super.key,
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
    final amount = draft.currencyEvidence?.requiresSelection == true
        ? '${PersianNumbers.format(draft.currencyEvidence!.sourceAmount)} (واحد نامشخص)'
        : PersianMoneyText.money(
            draft.amount,
            unit: MoneyUnitScope.of(context),
          );
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
                    draft.merchant ?? _direction(draft.direction),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(amount, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 6),
            Text('${widget.item.sourceLabel} · ${_direction(draft.direction)}'),
            Text(
              draft.receivedAt == null
                  ? 'تاریخ دریافت پیامک: نامشخص'
                  : 'دریافت پیامک: ${PersianDateFormatter.date(JalaliDate.fromDateTime(draft.receivedAt!))}',
            ),
            Text(
              draft.dateSource == TransactionDateSource.extracted
                  ? 'تاریخ استخراج‌شدهٔ تراکنش: $date'
                  : draft.dateSource == TransactionDateSource.receipt
                  ? 'تاریخ تراکنش نامشخص؛ تاریخ دریافت برای ثبت پیشنهاد شده است.'
                  : 'تاریخ تراکنش و منشأ تاریخ ذخیره‌شده نامشخص است.',
            ),
            Text('بانک: ${draft.bank ?? 'نامشخص'}'),
            Text(
              draft.currencyEvidence == null
                  ? 'واحد پیامک قدیمی نامشخص؛ مبلغ ذخیره‌شده بدون تغییر حفظ شده است.'
                  : draft.currencyEvidence!.requiresSelection
                  ? 'واحد مبلغ نامشخص است؛ در ویرایش، ریال یا تومان را انتخاب کنید.'
                  : 'واحد مبلغ: ${draft.currencyEvidence!.effectiveUnit!.label}؛ ${draft.currencyEvidence!.selectedUnit == null ? 'شواهد پیامک' : 'انتخاب شما'}',
            ),
            if (widget.busy) const Text('در حال ذخیره…'),
            Text(
              'حساب پیشنهادی: ${widget.item.account?.name ?? 'نیازمند انتخاب'}',
            ),
            for (final warning in widget.item.warnings)
              Text(
                'هشدار: $warning',
                style: TextStyle(
                  color: PlanActStatusColors.of(context).attention,
                ),
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
            if (widget.item.suggestion.status == SuggestionStatus.confirmed)
              const Text(
                'تأییدشده؛ برای اصلاح یا برگشت تراکنش به بخش مالی بروید. حذف از صندوق ممکن نیست.',
              )
            else if (widget.item.suggestion.status == SuggestionStatus.rejected)
              TextButton.icon(
                onPressed: widget.busy ? null : widget.onReject,
                icon: const Icon(Icons.undo),
                label: const Text('بازگردانی به صف بررسی'),
              )
            else
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
    ),
  );
}
