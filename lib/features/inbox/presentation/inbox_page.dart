import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/core/money/money_input_formatter.dart';
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
import 'package:planact/features/inbox/presentation/sms_review_editor.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/presentation/financial_account_picker.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/presentation/sms_scan_card.dart';
import 'package:planact/features/inbox/presentation/sms_automatic_sync_card.dart';
import 'package:planact/features/inbox/presentation/sms_sync_controller.dart';
import 'package:planact/features/inbox/application/inbox_review_projection.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/bulk_inbox_reject.dart';
import 'package:planact/features/inbox/domain/inbox.dart';
import 'package:planact/features/inbox/domain/sms_currency_evidence.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({
    super.key,
    required this.inbox,
    required this.finance,
    this.smsSource,
    this.smsSync,
    this.tagRepository,
    this.onDetermineRelationship,
    this.onDataChanged,
  });

  final Future<void> Function()? onDataChanged;
  final TagRepository? tagRepository;
  final InboxUseCases inbox;
  final FinanceRepository finance;
  final AndroidSmsSource? smsSource;
  final SmsSyncController? smsSync;
  final Future<void> Function(StableId transactionId)? onDetermineRelationship;

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> with WidgetsBindingObserver {
  SmsSyncController? _smsSync;
  bool _ownsSmsSync = false;
  int _smsRevision = 0;
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
  bool _showSmsPermissionHelp = false;
  bool _openingSmsSettings = false;
  String? _error;
  int _page = 0;
  final Map<StableId, InboxSuggestion> _selected = {};
  BulkInboxReject? _bulk;
  InboxRejectProgress? _bulkProgress;
  int _bulkTotal = 0;
  bool _bulkConfirming = false;

  List<InboxReviewItem> get _pageItems => _items
      .skip(_page * BulkInboxReject.pageSize)
      .take(BulkInboxReject.pageSize)
      .toList(growable: false);

  void _clearSelection() {
    _selected.clear();
    _page = 0;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _smsSync = widget.smsSync;
    if (_smsSync == null &&
        widget.smsSource != null &&
        widget.inbox.repository is AutomaticSmsScanStore) {
      _ownsSmsSync = true;
      _smsSync = SmsSyncController(
        inbox: widget.inbox,
        source: widget.smsSource!,
      );
    }
    _smsRevision = _smsSync?.revision ?? 0;
    _smsSync?.addListener(_smsSyncChanged);
    if (_ownsSmsSync) _smsSync!.start();
    _reload();
    unawaited(_refreshSms());
  }

  void _smsSyncChanged() {
    if (!mounted) return;
    setState(() => _smsAccess = _smsSync?.access ?? _smsAccess);
    if (_smsRevision != _smsSync!.revision) {
      _smsRevision = _smsSync!.revision;
      unawaited(_reload());
    }
  }

  Future<void> _refreshSms() async {
    await _syncSms();
    await _reload();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_working) _refreshSms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsSync?.removeListener(_smsSyncChanged);
    if (_ownsSmsSync) _smsSync?.dispose();
    _bulk?.cancel();
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
        if (_page * BulkInboxReject.pageSize >= items.length) _page = 0;
        final fresh = {
          for (final item in _pageItems) item.suggestion.id: item.suggestion,
        };
        _selected.removeWhere(
          (id, snapshot) =>
              fresh[id]?.revision != snapshot.revision ||
              fresh[id]?.status != snapshot.status ||
              !BulkInboxReject.eligible(fresh[id]!),
        );
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
        _error = PersianCopy.inboxPageReloadMessage;
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
      if (_smsSync != null) {
        await _smsSync!.refresh(checkAccess: true);
      }
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
      if (mounted) {
        setState(() {
          _smsAccess = true;
          _smsError = null;
          _showSmsPermissionHelp = false;
        });
      }
    } catch (error) {
      _logger.error(
        'SMS sync failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) {
        setState(() {
          _smsError = PersianCopy.inboxPageSyncSmsMessage;
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
        scrollable: true,
        title: const Text(PersianCopy.inboxPageConsentTitle),
        content: const Text(PersianCopy.inboxPageConsentContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(PersianCopy.inboxPageConsentActions),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              PersianCopy.planactAppShowCommitmentDetailsTitle3,
            ),
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
      final granted = await source.requestAccess().timeout(
        const Duration(seconds: 50),
        onTimeout: () =>
            throw TimeoutException('SMS permission request timed out'),
      );
      if (!mounted) return;
      if (granted) {
        await _refreshSms();
      } else {
        setState(() {
          _smsAccess = false;
          _smsError = planActL10n(context).smsPermissionNotGranted;
          _showSmsPermissionHelp = true;
        });
      }
    } catch (error) {
      _logger.error(
        'SMS permission request failed',
        fields: {'errorType': error.runtimeType.toString()},
      );
      if (mounted) {
        setState(() {
          _smsError = planActL10n(context).smsPermissionRequestFailed;
          _showSmsPermissionHelp = true;
        });
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _openSmsSettings() async {
    if (_openingSmsSettings || widget.smsSource == null) return;
    setState(() => _openingSmsSettings = true);
    try {
      await widget.smsSource!.openSettings();
    } catch (_) {
      if (mounted) {
        setState(
          () => _smsError = planActL10n(context).smsPermissionSettingsFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _openingSmsSettings = false);
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
      if (widget.tagRepository != null) {
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (_) => SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                PlanActSpacing.page,
                PlanActSpacing.page,
                PlanActSpacing.page,
                PlanActSpacing.page + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: RecordTagEditor(
                repository: widget.tagRepository!,
                recordId: id.value,
                type: TaggableType.accountEntry,
                onChanged: () async {
                  await widget.onDataChanged?.call();
                },
              ),
            ),
          ),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).clearSnackBars();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            refreshFailed
                ? PersianCopy.inboxPageConfirmContent
                : PersianCopy.financePageRecordTransactionMessage,
          ),
          action: widget.onDetermineRelationship == null
              ? null
              : SnackBarAction(
                  label: PersianCopy.financePageEntryOperationsItemBuilder,
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
                ? PersianCopy.inboxPageRejectContent
                : PersianCopy.inboxPageRejectContent2,
          ),
          action: recover
              ? null
              : SnackBarAction(
                  label: PersianCopy.inboxPageRejectLabel,
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
            content: const Text(PersianCopy.inboxPageRejectContent3),
            action: SnackBarAction(
              label: PersianCopy.commonRetry,
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
      final saved = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        builder: (_) =>
            SmsReviewEditor(suggestion: item.suggestion, inbox: widget.inbox),
      );
      if (saved == true && mounted) {
        _epoch++;
        await _reload();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(PersianCopy.inboxPageEditContent)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _pending.remove(item.suggestion.id));
    }
  }

  Future<void> _bulkReject({bool retry = false}) async {
    if (_bulk != null || _bulkConfirming) return;
    final snapshots =
        (retry
                ? _bulkProgress?.failures.values ?? <InboxSuggestion>[]
                : _selected.values)
            .where((s) => !_pending.contains(s.id))
            .toList(growable: false);
    if (snapshots.isEmpty) return;
    setState(() => _bulkConfirming = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(PersianCopy.inboxPageConfirmedTitle),
        content: Text(
          PersianCopy.inboxPageConfirmedContent(
            (PersianNumbers.format(snapshots.length)).toString(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(PersianCopy.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(PersianCopy.inboxPageConfirmedActions),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _bulkConfirming = false);
    if (confirmed != true) return;
    final runner = BulkInboxReject(widget.inbox);
    final progress = InboxRejectProgress();
    setState(() {
      _bulk = runner;
      _bulkProgress = progress;
      _bulkTotal = snapshots.length;
      _selected.clear();
    });
    await runner.run(
      snapshots,
      onStarted: (suggestion) {
        if (!mounted) return;
        setState(() {
          _pending.add(suggestion.id);
          _epoch++;
        });
      },
      onFinished: (suggestion, success) {
        progress.attempted++;
        if (success) {
          progress.succeeded++;
        } else {
          progress.failures[suggestion.id] = suggestion;
        }
        if (!mounted) return;
        setState(() {
          _pending.remove(suggestion.id);
          _epoch++;
          if (success) {
            _items = _items
                .where((i) => i.suggestion.id != suggestion.id)
                .toList();
          }
        });
      },
    );
    if (!mounted) return;
    setState(() => _bulk = null);
    await _reload();
  }

  Widget _bulkControls() {
    final page = _pageItems;
    final eligible = page.where(
      (i) =>
          BulkInboxReject.eligible(i.suggestion) &&
          !_pending.contains(i.suggestion.id),
    );
    final progress = _bulkProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          PersianCopy.inboxPageBulkControlsChildren(
            (PersianNumbers.format(BulkInboxReject.pageSize)).toString(),
          ),
        ),
        Text(
          PersianCopy.inboxPageBulkControlsChildren2(
            (PersianNumbers.format(_selected.length)).toString(),
          ),
        ),
        Wrap(
          spacing: PlanActSpacing.sm,
          children: [
            TextButton(
              onPressed: _bulk != null || _bulkConfirming || eligible.isEmpty
                  ? null
                  : () => setState(() {
                      for (final item in eligible) {
                        _selected[item.suggestion.id] = item.suggestion;
                      }
                    }),
              child: const Text(PersianCopy.inboxPageBulkControlsChildren3),
            ),
            TextButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => setState(_selected.clear),
              child: const Text(PersianCopy.inboxPageBulkControlsChildren4),
            ),
            OutlinedButton(
              onPressed: _bulk != null || _bulkConfirming || _selected.isEmpty
                  ? null
                  : _bulkReject,
              child: const Text(PersianCopy.inboxPageBulkControlsChildren5),
            ),
          ],
        ),
        if (_items.length > BulkInboxReject.pageSize || _page > 0)
          Wrap(
            spacing: PlanActSpacing.sm,
            children: [
              Text(
                PersianCopy.inboxPageBulkControlsChildren6(
                  (PersianNumbers.format(_page + 1)).toString(),
                ),
              ),
              TextButton(
                onPressed: _page == 0
                    ? null
                    : () => setState(() {
                        _page--;
                        _selected.clear();
                      }),
                child: const Text(PersianCopy.inboxPageBulkControlsChildren7),
              ),
              TextButton(
                onPressed:
                    (_page + 1) * BulkInboxReject.pageSize >= _items.length
                    ? null
                    : () => setState(() {
                        _page++;
                        _selected.clear();
                      }),
                child: const Text(PersianCopy.inboxPageBulkControlsChildren8),
              ),
            ],
          ),
        if (progress != null) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              PersianCopy.inboxPageBulkControlsChildren9(
                (PersianNumbers.format(progress.attempted)).toString(),
                (PersianNumbers.format(_bulkTotal)).toString(),
                (PersianNumbers.format(progress.succeeded)).toString(),
                (PersianNumbers.format(progress.failures.length)).toString(),
              ),
            ),
          ),
          if (_bulk != null)
            TextButton(
              onPressed: () => setState(() => _bulk!.cancel()),
              child: Text(
                _bulk!.cancelled
                    ? PersianCopy.inboxPageBulkControlsChildren10
                    : PersianCopy.inboxPageBulkControlsChildren11,
              ),
            )
          else ...[
            const Text(PersianCopy.inboxPageBulkControlsChildren12),
            if (progress.failures.isNotEmpty) ...[
              const Text(PersianCopy.inboxPageBulkControlsChildren13),
              TextButton(
                onPressed: _bulkConfirming
                    ? null
                    : () => _bulkReject(retry: true),
                child: const Text(PersianCopy.inboxPageBulkControlsChildren14),
              ),
            ],
          ],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _items.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshSms,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: 320,
              child: _InboxStateCard(
                icon: Icons.error_outline,
                title: planActL10n(context).inboxPageBuildTitle,
                message: _error!,
                actionLabel: planActL10n(context).commonRetry,
                onAction: _refreshSms,
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
          onRefresh: _refreshSms,
          onEnable: widget.smsSource != null && !_working && _smsAccess != true
              ? _enableSms
              : null,
        ),
        if (widget.smsSource != null && _smsAccess != true)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(PlanActSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextButton(
                    onPressed: () => setState(
                      () => _showSmsPermissionHelp = !_showSmsPermissionHelp,
                    ),
                    child: Text(planActL10n(context).smsPermissionHelpTitle),
                  ),
                  if (_showSmsPermissionHelp) ...[
                    Text(planActL10n(context).smsPermissionHelpBody),
                    const SizedBox(height: PlanActSpacing.sm),
                    OutlinedButton(
                      onPressed: _working || _openingSmsSettings
                          ? null
                          : _openSmsSettings,
                      child: Text(
                        planActL10n(context).smsPermissionOpenSettings,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (_smsSync != null) SmsAutomaticSyncCard(controller: _smsSync!),
        if (widget.smsSource != null && widget.inbox.repository is SmsScanStore)
          SmsScanCard(
            inbox: widget.inbox,
            source: widget.smsSource!,
            access: _smsAccess == true,
            onChanged: _reload,
          ),
        const SizedBox(height: PlanActSpacing.md),
        DropdownButtonFormField<SuggestionStatus>(
          isExpanded: true,
          itemHeight: null,
          initialValue: _status,
          decoration: InputDecoration(
            labelText: planActL10n(context).inboxPageHeaderLabelText,
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(planActL10n(context).inboxPageHeaderItems),
            ),
            DropdownMenuItem(
              value: SuggestionStatus.rejected,
              child: Text(planActL10n(context).inboxPageHeaderItems2),
            ),
            DropdownMenuItem(
              value: SuggestionStatus.confirmed,
              child: Text(planActL10n(context).inboxPageHeaderItems3),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _status = value;
              _clearSelection();
              _epoch++;
            });
            _reload();
          },
        ),
        DropdownButtonFormField<String>(
          isExpanded: true,
          itemHeight: null,
          initialValue: _bank,
          decoration: InputDecoration(
            labelText: planActL10n(context).inboxPageHeaderLabelText2,
          ),
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(planActL10n(context).inboxPageHeaderItems4),
            ),
            for (final bank in _banks)
              DropdownMenuItem(
                value: bank,
                child: Text(
                  bank.isEmpty
                      ? planActL10n(context).inboxPageHeaderItems5
                      : bank,
                ),
              ),
          ],
          onChanged: (value) {
            setState(() {
              _bank = value;
              _clearSelection();
              _epoch++;
            });
            _reload();
          },
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _oldestFirst = !_oldestFirst;
              _clearSelection();
              _epoch++;
            });
            _reload();
          },
          icon: const Icon(Icons.sort),
          label: Text(
            _oldestFirst
                ? planActL10n(context).inboxPageHeaderLabel
                : planActL10n(context).inboxPageHeaderLabel2,
          ),
        ),
        if (_error != null) Text(_error!),
        _bulkControls(),
        if (_items.isEmpty)
          SizedBox(
            height: 300,
            child: _InboxStateCard(
              icon: Icons.inbox_outlined,
              title: planActL10n(context).inboxPageHeaderTitle,
              message: planActL10n(context).inboxPageHeaderMessage,
            ),
          )
        else
          Text(
            planActL10n(context).planactAppShowTimelineSubtitle2(
              (switch (_status) {
                SuggestionStatus.rejected => planActL10n(
                  context,
                ).inboxPageHeaderItems2,
                SuggestionStatus.confirmed => planActL10n(
                  context,
                ).inboxPageHeaderItems3,
                _ => planActL10n(context).inboxPageHeaderItems,
              }).toString(),
              (PersianNumbers.format(_items.length)).toString(),
            ),
            style: Theme.of(context).textTheme.titleMedium,
          ),
      ],
    );
    return RefreshIndicator(
      onRefresh: _refreshSms,
      child: ListView.builder(
        controller: _scroll,
        key: const PageStorageKey('inbox-review'),
        padding: const EdgeInsets.all(PlanActSpacing.md),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _pageItems.length + 1,
        findChildIndexCallback: (key) {
          if (key is! ValueKey<StableId>) return null;
          final index = _pageItems.indexWhere(
            (i) => i.suggestion.id == key.value,
          );
          return index < 0 ? null : index + 1;
        },
        itemBuilder: (context, index) {
          if (index == 0) return header;
          final item = _pageItems[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: PlanActSpacing.md),
            child: _ReviewCard(
              key: ValueKey(item.suggestion.id),
              item: item,
              selected: _selected.containsKey(item.suggestion.id),
              onSelection:
                  !BulkInboxReject.eligible(item.suggestion) ||
                      _pending.contains(item.suggestion.id) ||
                      _bulk != null ||
                      _bulkConfirming
                  ? null
                  : (value) => setState(() {
                      if (value == true) {
                        _selected[item.suggestion.id] = item.suggestion;
                      } else {
                        _selected.remove(item.suggestion.id);
                      }
                    }),
              busy: _pending.contains(item.suggestion.id),
              onConfirm: () => _confirm(item),
              onEdit: () => _edit(item),
              onReject: () => _reject(
                item,
                recover: item.suggestion.status == SuggestionStatus.rejected,
              ),
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
  bool _dateAcknowledged = false;
  bool _classificationAcknowledged = false;
  SmsMoneyUnit? _proposedUnit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.item.suggestion.draft.currencyEvidence?.requiresSelection ==
        true) {
      _proposedUnit ??= MoneyUnitScope.of(context) == IranianMoneyUnit.toman
          ? SmsMoneyUnit.toman
          : SmsMoneyUnit.rial;
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    final suggestion = widget.item.suggestion;
    final draft = suggestion.draft;
    if (suggestion.extractedEvidence?.isTransfer == true ||
        draft.type == 'transfer') {
      setState(() => _error = PersianCopy.inboxPageSaveMessage);
      return;
    }
    if (draft.type != 'income' && draft.type != 'expense') {
      setState(() => _error = PersianCopy.inboxPageSaveMessage2);
      return;
    }
    if (!_classificationAcknowledged) {
      setState(() => _error = PersianCopy.inboxPageSaveMessage3);
      return;
    }
    if (draft.dateSource != TransactionDateSource.extracted &&
        draft.dateSource != TransactionDateSource.reviewer &&
        !_dateAcknowledged) {
      setState(() => _error = PersianCopy.inboxPageSaveMessage4);
      return;
    }
    final account = _account;
    if (account == null) {
      setState(() => _error = PersianCopy.financePageResultOnPrimary);
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
        selectedUnit: _proposedUnit,
      );
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop(entry);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = PersianCopy.inboxPageSaveMessage6;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: PlanActFormSheet(
      title: planActL10n(context).inboxPageBuildTitle2,
      primaryLabel: planActL10n(context).inboxPageBuildPrimaryLabel,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  planActL10n(context).inboxDefaultUnitAmount(
                    PersianNumbers.format(
                      MoneyInputFormatter.groupText(
                        widget
                            .item
                            .suggestion
                            .draft
                            .currencyEvidence!
                            .sourceAmount
                            .toString(),
                      ),
                    ),
                    _proposedUnit!.label,
                  ),
                ),
                Text(planActL10n(context).inboxDefaultUnitConfirmationNotice),
                DropdownButtonFormField<SmsMoneyUnit>(
                  initialValue: _proposedUnit,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: planActL10n(context)
                        .smsReviewEditorBuildLabelText,
                  ),
                  items: [
                    for (final unit in SmsMoneyUnit.values)
                      DropdownMenuItem(value: unit, child: Text(unit.label)),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _proposedUnit = value!),
                ),
              ],
            )
          else
            Text(
              PersianMoneyText.money(
                widget.item.suggestion.draft.amount,
                unit: MoneyUnitScope.of(context),
              ),
            ),
          SmsOriginalEvidence(suggestion: widget.item.suggestion),
          const SizedBox(height: PlanActSpacing.md),
          Text(
            planActL10n(context).inboxPageBuildChildren2(
              (smsReviewTimestamp(widget.item.suggestion.draft.occurredAt))
                  .toString(),
            ),
          ),
          if (widget.item.suggestion.extractedEvidence?.isTransfer == true ||
              widget.item.suggestion.draft.type == 'transfer')
            Text(planActL10n(context).inboxPageSaveMessage)
          else if (widget.item.suggestion.draft.type != 'income' &&
              widget.item.suggestion.draft.type != 'expense')
            Text(planActL10n(context).inboxPageBuildChildren3)
          else
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _classificationAcknowledged,
              onChanged: _saving
                  ? null
                  : (value) => setState(
                      () => _classificationAcknowledged = value == true,
                    ),
              title: Text(
                planActL10n(context).inboxPageBuildTitle5(
                  (widget.item.suggestion.draft.type == 'income'
                          ? planActL10n(context).inboxPageBuildTitle4
                          : planActL10n(context).inboxPageBuildTitle3)
                      .toString(),
                ),
              ),
              subtitle: Text(planActL10n(context).inboxPageBuildSubtitle),
            ),
          if (widget.item.suggestion.draft.dateSource !=
                  TransactionDateSource.extracted &&
              widget.item.suggestion.draft.dateSource !=
                  TransactionDateSource.reviewer)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _dateAcknowledged,
              onChanged: _saving
                  ? null
                  : (value) =>
                        setState(() => _dateAcknowledged = value == true),
              title: Text(planActL10n(context).inboxPageBuildTitle6),
              subtitle: Text(
                widget.item.suggestion.draft.dateSource ==
                        TransactionDateSource.receipt
                    ? planActL10n(context).inboxPageBuildSubtitle2
                    : planActL10n(context).inboxPageBuildSubtitle3,
              ),
            ),
          Text(
            planActL10n(context).inboxPageBuildChildren5(
              (widget.item.account?.name ??
                      planActL10n(context).inboxPageBuildChildren4)
                  .toString(),
            ),
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
      title: Text(planActL10n(context).inboxPageBuildTitle7),
      subtitle: Text(
        error ??
            switch (access) {
              true => planActL10n(context).inboxPageBuildSubtitle4,
              false => planActL10n(context).inboxPageBuildSubtitle5,
              null => planActL10n(context).inboxPageBuildSubtitle6,
            },
      ),
      trailing: onEnable == null
          ? IconButton(
              tooltip: planActL10n(context).inboxPageBuildTooltip,
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
            )
          : TextButton(
              onPressed: onEnable,
              child: Text(planActL10n(context).inboxPageBuildTrailing),
            ),
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
    required this.selected,
    this.onSelection,
  });

  final bool selected;
  final ValueChanged<bool?>? onSelection;
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
        ? planActL10n(context).inboxDefaultUnitProposalAmount(
            (PersianNumbers.format(
              MoneyInputFormatter.groupText(
                draft.currencyEvidence!.sourceAmount.toString(),
              ),
            )).toString(),
            MoneyUnitScope.of(context).label,
          )
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
            Text(
              draft.merchant ?? _direction(draft.direction),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (BulkInboxReject.eligible(widget.item.suggestion))
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(planActL10n(context).inboxPageBuildTitle8),
                value: widget.selected,
                onChanged: widget.onSelection,
              ),
            Text(amount, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('${widget.item.sourceLabel} · ${_direction(draft.direction)}'),
            Text(
              draft.receivedAt == null
                  ? planActL10n(context).inboxPageBuildChildren6
                  : planActL10n(context).inboxPageBuildChildren7(
                      (PersianDateFormatter.date(
                        JalaliDate.fromDateTime(draft.receivedAt!),
                      )).toString(),
                    ),
            ),
            Text(
              draft.dateSource == TransactionDateSource.extracted
                  ? planActL10n(context)
                        .inboxPageBuildChildren8((date).toString())
                  : draft.dateSource == TransactionDateSource.receipt
                  ? planActL10n(context).inboxPageBuildChildren9
                  : draft.dateSource == TransactionDateSource.reviewer
                  ? planActL10n(context).inboxPageBuildChildren10(
                      (smsReviewTimestamp(draft.occurredAt)).toString(),
                    )
                  : planActL10n(context).inboxPageBuildChildren11,
            ),
            Text(
              planActL10n(context).inboxPageBuildChildren12(
                (draft.bank ?? planActL10n(context).commonUnknown).toString(),
              ),
            ),
            Text(
              draft.currencyEvidence == null
                  ? planActL10n(context).inboxPageBuildChildren13
                  : draft.currencyEvidence!.requiresSelection
                  ? planActL10n(context).inboxDefaultUnitReviewNotice
                  : planActL10n(context).inboxPageBuildChildren17(
                      (draft.currencyEvidence!.effectiveUnit!.label).toString(),
                      (draft.currencyEvidence!.selectedUnit == null
                              ? planActL10n(context).inboxPageBuildChildren16
                              : planActL10n(context).inboxPageBuildChildren15)
                          .toString(),
                    ),
            ),
            if (widget.busy)
              Text(
                planActL10n(context).financialExpectationEditorBuildChildren,
              ),
            Text(
              planActL10n(context).inboxPageBuildChildren18(
                (widget.item.account?.name ??
                        planActL10n(context).inboxPageBuildChildren4)
                    .toString(),
              ),
            ),
            for (final warning in widget.item.warnings)
              Text(
                planActL10n(context)
                    .inboxPageBuildChildren19((warning).toString()),
                style: TextStyle(
                  color: PlanActStatusColors.of(context).attention,
                ),
              ),
            TextButton.icon(
              onPressed: () => setState(() => _showDetails = !_showDetails),
              icon: Icon(_showDetails ? Icons.expand_less : Icons.expand_more),
              label: Text(
                _showDetails
                    ? planActL10n(context).inboxPageBuildLabel
                    : planActL10n(context).inboxPageBuildLabel2,
              ),
            ),
            if (_showDetails) ...[
              SmsOriginalEvidence(suggestion: widget.item.suggestion),
              const SizedBox(height: PlanActSpacing.md),
              Text(
                planActL10n(context).inboxPageBuildChildren20,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                planActL10n(context).inboxPageBuildChildren12(
                  (draft.bank ?? planActL10n(context).commonUnknown).toString(),
                ),
              ),
              Text(
                planActL10n(context)
                    .inboxPageBuildChildren21((amount).toString()),
              ),
              Text(
                planActL10n(context).inboxPageBuildChildren22(
                  (_direction(draft.direction)).toString(),
                ),
              ),
              Text(
                planActL10n(context).inboxPageBuildChildren23(
                  (draft.merchant ?? planActL10n(context).commonUnknown)
                      .toString(),
                ),
              ),
              Text(
                planActL10n(context).inboxPageBuildChildren24(
                  (maskedSmsEvidence(draft.accountHint)).toString(),
                ),
              ),
              Text(
                planActL10n(context).inboxPageBuildChildren25(
                  (maskedSmsEvidence(draft.reference)).toString(),
                ),
              ),
              Text(
                planActL10n(context).inboxPageBuildChildren26(
                  (smsReviewTimestamp(draft.occurredAt)).toString(),
                ),
              ),
              Text(
                planActL10n(context).inboxPageBuildChildren27,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              for (final reason in widget.item.reasons) Text('• $reason'),
            ],
            const SizedBox(height: PlanActSpacing.sm),
            if (widget.item.suggestion.status == SuggestionStatus.confirmed)
              Text(planActL10n(context).inboxPageBuildChildren28)
            else if (widget.item.suggestion.status == SuggestionStatus.rejected)
              TextButton.icon(
                onPressed: widget.busy ? null : widget.onReject,
                icon: const Icon(Icons.undo),
                label: Text(planActL10n(context).inboxPageBuildLabel3),
              )
            else
              Wrap(
                spacing: PlanActSpacing.sm,
                runSpacing: PlanActSpacing.xs,
                children: [
                  FilledButton.icon(
                    onPressed: widget.busy ? null : widget.onConfirm,
                    icon: const Icon(Icons.check),
                    label: Text(planActL10n(context).inboxPageBuildLabel4),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.busy ? null : widget.onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(planActL10n(context).inboxPageBuildLabel5),
                  ),
                  TextButton.icon(
                    onPressed: widget.busy ? null : widget.onReject,
                    icon: const Icon(Icons.close),
                    label: Text(planActL10n(context).inboxPageBuildLabel6),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _direction(TransactionDirection direction) => switch (direction) {
    TransactionDirection.incoming =>
      PersianCopy.transactionDirectionAccountEntryTypeIncome,
    TransactionDirection.outgoing =>
      PersianCopy.transactionDirectionAccountEntryTypeExpense,
    TransactionDirection.unknown =>
      PersianCopy.inboxPageTransactionDirectionUnknown,
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
