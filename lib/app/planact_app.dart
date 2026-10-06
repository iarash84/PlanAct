import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/reminders/presentation/occurrence_reminders.dart';
import 'package:planact/features/scheduling/application/edit_commitment_schedule.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/scheduling/presentation/edit_schedule_dialog.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/features/backup/application/backup_actions.dart';
import 'package:planact/app/app_lock.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/application/commitment_use_cases.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/finance/application/finance_use_cases.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/data/drift_inbox_repository.dart';
import 'package:planact/features/inbox/presentation/inbox_page.dart';
import 'package:planact/features/finance/application/financial_expectation_use_cases.dart';
import 'package:planact/features/finance/domain/finance.dart';
import 'package:planact/features/finance/data/drift_finance_repository.dart';
import 'package:planact/features/finance/data/drift_financial_expectation_repository.dart';
import 'package:planact/features/finance/presentation/finance_page.dart';
import 'package:planact/features/finance/presentation/financial_expectation_editor.dart';
import 'package:planact/features/settings/presentation/about_page.dart';
import 'package:planact/features/settings/presentation/settings_page.dart';
import 'package:planact/features/scheduling/application/occurrence_actions.dart';
import 'package:planact/features/scheduling/presentation/occurrence_action_row.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/today/application/attention_engine.dart';
import 'package:planact/features/today/presentation/today_page.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/application/reminder_platform.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/core/money/money.dart';

class PlanActApp extends StatefulWidget {
  const PlanActApp({
    super.key,
    this.repository,
    this.planRepository,
    this.holidayPackages,
    this.backupActions,
    this.backupMessage,
  });
  final HolidayPackageService? holidayPackages;
  final BackupActions? backupActions;
  final String? backupMessage;

  final CommitmentRepository? repository;
  final CommitmentPlanRepository? planRepository;

  @override
  State<PlanActApp> createState() => _PlanActAppState();
}

class _PlanActAppState extends State<PlanActApp> {
  ThemeMode _themeMode = ThemeMode.system;
  AppSettings? _settings;
  bool _appLockEnabled = false;
  bool _appLockSettingLoaded = false;
  String? _appLockSettingError;
  late final AppLockController _appLockController = AppLockController(
    authenticator: LocalAppAuthenticator(),
  );

  @override
  void initState() {
    super.initState();
    final repository = widget.repository;
    if (repository is DriftCommitmentRepository) {
      _settings = AppSettings(repository.database);
      _settings!.readThemeMode().then((mode) {
        if (mounted) setState(() => _themeMode = mode);
      });
      _loadAppLockSetting();
    }
  }

  Future<void> _loadAppLockSetting() async {
    try {
      final enabled = await _settings!.readAppLockEnabled();
      if (enabled) _appLockController.lock();
      if (mounted) {
        setState(() {
          _appLockEnabled = enabled;
          _appLockSettingLoaded = true;
          _appLockSettingError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _appLockSettingError =
              'خواندن تنظیمات قفل برنامه ممکن نشد. دوباره تلاش کنید.',
        );
      }
    }
  }

  bool _changingAppLock = false;

  Future<void> _setAppLock(bool enabled) async {
    if (_changingAppLock) throw StateError('App lock change already running');
    if (enabled == _appLockEnabled) return;
    _changingAppLock = true;
    try {
      final settings = _settings;
      if (settings == null) throw StateError('Persistent settings unavailable');
      await _appLockController.changeSetting(
        enabled: enabled,
        persist: settings.writeAppLockEnabled,
      );
      if (!mounted) return;
      setState(() => _appLockEnabled = enabled);
    } finally {
      _changingAppLock = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پلن‌اکت',
      debugShowCheckedModeBanner: false,
      theme: PlanActTheme.light(),
      darkTheme: PlanActTheme.dark(),
      themeMode: _themeMode,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: AppLockGate(
          enabled: _appLockEnabled,
          controller: _appLockController,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: !_appLockSettingLoaded && _settings != null
          ? Scaffold(
              body: Center(
                child: _appLockSettingError == null
                    ? const CircularProgressIndicator()
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_appLockSettingError!),
                          TextButton(
                            onPressed: _loadAppLockSetting,
                            child: const Text('تلاش دوباره'),
                          ),
                        ],
                      ),
              ),
            )
          : HomeShell(
              holidayPackages: widget.holidayPackages,
              backupActions: widget.backupActions,
              backupMessage: widget.backupMessage,
              repository: widget.repository,
              planRepository: widget.planRepository,
              settings: _settings,
              themeMode: _themeMode,
              appLockEnabled: _appLockEnabled,
              appLockController: _appLockController,
              onAppLockChanged: _setAppLock,
              onThemeModeChanged: (mode) async {
                setState(() => _themeMode = mode);
                await _settings?.writeThemeMode(mode);
              },
            ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    this.repository,
    this.planRepository,
    this.settings,
    this.holidayPackages,
    this.backupActions,
    this.backupMessage,
    this.themeMode = ThemeMode.system,
    this.appLockEnabled = false,
    this.appLockController,
    this.onAppLockChanged = _ignoreAppLockChange,
    this.onThemeModeChanged = _ignoreThemeChange,
  });

  static void _ignoreThemeChange(ThemeMode _) {}
  static Future<void> _ignoreAppLockChange(bool _) async {}

  final CommitmentRepository? repository;
  final CommitmentPlanRepository? planRepository;
  final AppSettings? settings;
  final HolidayPackageService? holidayPackages;
  final BackupActions? backupActions;
  final String? backupMessage;
  final ThemeMode themeMode;
  final bool appLockEnabled;
  final AppLockController? appLockController;
  final Future<void> Function(bool enabled) onAppLockChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final PageController _pageController = PageController();
  late final CommitmentRepository _repository =
      widget.repository ?? InMemoryCommitmentRepository();
  late final CommitmentPlanRepository _planRepository =
      widget.planRepository ??
      (_repository is DriftCommitmentRepository
          ? DriftCommitmentPlanRepository(_repository.database)
          : InMemoryCommitmentPlanRepository());
  late final EntitlementPlanRepository? _entitlementRepository =
      _repository is DriftCommitmentRepository
      ? DriftEntitlementPlanRepository(_repository.database)
      : null;
  Future<bool> _enableReminders() async {
    final repository = _repository;
    if (repository is! DriftCommitmentRepository) return false;
    final platform = AndroidReminderPlatformAdapter();
    return CommandGate.runFor(repository, () async {
      if (!await platform.requestPermission()) return false;
      if (!await platform.requestExactAlarmPermission()) return false;
      await ReminderService(
        repository: DriftReminderRepository(repository.database),
        platform: platform,
      ).reconcile(now: DateTime.now().toUtc());
      return true;
    });
  }

  late final CreateCommitmentPlan _createCommitmentPlan = CreateCommitmentPlan(
    commitments: _repository,
    plans: _planRepository,
    entitlements: _entitlementRepository,
    financialExpectations: _expectationUseCases,
    reminderService: _repository is DriftCommitmentRepository
        ? ReminderService(
            repository: DriftReminderRepository(_repository.database),
            platform: AndroidReminderPlatformAdapter(),
          )
        : null,
  );
  int _selectedIndex = 0;
  final GlobalKey<FinancePageState> _financePageKey =
      GlobalKey<FinancePageState>();
  late final FinanceRepository _financeRepository =
      _repository is DriftCommitmentRepository
      ? DriftFinanceRepository(_repository.database)
      : InMemoryFinanceRepository();
  List<Commitment> _commitments = const [];
  final Map<String, List<DateTime>> _scheduledDates = {};
  Map<String, List<Occurrence>> _calendarOccurrences = {};
  List<ReminderRule> _calendarReminderRules = [];
  TodayDashboard? _todayDashboard;
  TodayActionCenter? _todayActionCenter;
  String? _todayError;
  final AttentionEngine _attentionEngine = const AttentionEngine();
  late final FinancialExpectationRepository _expectationRepository =
      _repository is DriftCommitmentRepository
      ? DriftFinancialExpectationRepository(_repository.database)
      : InMemoryFinancialExpectationRepository();
  late final FinancialExpectationUseCases _expectationUseCases =
      FinancialExpectationUseCases(_expectationRepository);

  late final InboxUseCases _inboxUseCases = InboxUseCases(
    _repository is DriftCommitmentRepository
        ? DriftInboxRepository(_repository.database)
        : InMemoryInboxRepository(),
  );

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final items = await _repository.list();
      final schedules = <String, List<DateTime>>{};
      final plans = <StableId, List<Occurrence>>{};
      for (final item in items) {
        final plan = await _planRepository.findByCommitmentId(item.id);
        if (plan == null) continue;
        plans[item.id] = plan.occurrences;
        schedules[item.id.value] = [
          for (final occurrence in plan.occurrences)
            if (occurrence.currentScheduledAt case final DateTime date)
              date.isUtc ? date.toLocal() : date
            else if (occurrence.currentScheduledAt case final LocalDate date)
              DateTime(date.year, date.month, date.day),
        ];
      }
      final reminderRules =
          await _createCommitmentPlan.reminderService?.repository.listRules() ??
          <ReminderRule>[];
      final expectations = await _expectationRepository.listExpectations();
      final matches = await _expectationRepository.listMatches();
      final accounts = await _financeRepository.listAccounts();
      final entries = await _financeRepository.listEntries();
      final inboxSuggestions = await _inboxUseCases.listPendingSuggestions();
      final dashboard = _attentionEngine.build(
        now: DateTime.now(),
        commitments: items,
        plans: plans,
        expectations: expectations,
        matches: matches,
        inboxSuggestions: inboxSuggestions,
        entries: entries,
        accounts: accounts,
      );
      final actionCenter = _attentionEngine.buildActionCenter(
        now: DateTime.now(),
        commitments: items,
        plans: plans,
        expectations: expectations,
        matches: matches,
        inboxSuggestions: inboxSuggestions,
        entries: entries,
        accounts: accounts,
      );
      if (mounted) {
        setState(() {
          _commitments = items;
          _calendarOccurrences = {
            for (final entry in plans.entries) entry.key.value: entry.value,
          };
          _calendarReminderRules = reminderRules;
          _scheduledDates
            ..clear()
            ..addAll(schedules);
          _todayDashboard = dashboard;
          _todayActionCenter = actionCenter;
          _todayError = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _todayError = 'بارگذاری اقدامات انجام نشد؛ دوباره تلاش کنید.',
        );
      }
    }
  }

  void _openInbox() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('صندوق ورودی')),
          body: InboxPage(
            inbox: _inboxUseCases,
            finance: _financeRepository,
            smsSource: AndroidSmsSource(),
          ),
        ),
      ),
    );
  }

  Future<void> _showCapture() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => QuickCaptureSheet(onSave: _saveCapturedCommitment),
    );
  }

  Future<void> _saveCapturedCommitment(CommitmentDraft draft) async {
    final startAt = draft.scheduledDates.first;
    final plan = await _createCommitmentPlan(
      title: draft.title,
      startAt: startAt,
      kind: draft.kind,
      priority: draft.priority,
      description: draft.description,
      tags: draft.tags,
      attachmentIds: draft.attachmentIds,
      frequency: draft.frequency,
      weekdays: draft.weekdays,
      occurrenceCount: draft.occurrenceCount,
      endDate: draft.endDate,
      reminderOffsets: draft.reminderOffsets,
      entitlementUnits: draft.entitlement == EntitlementDraft.fixedUnits
          ? draft.entitlementUnits
          : null,
      financialDirection: draft.financialMeaning.expectationDirection,
      financialAmount: draft.financialAmount,
    );
    await _refresh();
    if (plan.reminderDeliveryPending) {
      _showMessage(
        'تعهد ذخیره شد؛ هماهنگ‌سازی یادآوری هنوز انجام نشده است. مجوزهای یادآوری را در تنظیمات بررسی کنید؛ با بازکردن دوباره برنامه، هماهنگ‌سازی تکرار می‌شود.',
      );
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showQuickAdd() async {
    final action = await QuickAddSheet.show(context);
    if (!mounted || action == null) return;
    switch (action) {
      case QuickAddAction.commitment:
        await _showCapture();
      case QuickAddAction.expense:
      case QuickAddAction.income:
        await _showQuickFinancialEntry(income: action == QuickAddAction.income);
      case QuickAddAction.transfer:
        await _showQuickTransfer();
    }
  }

  Future<void> _showQuickFinancialEntry({required bool income}) async {
    final accounts = await _financeRepository.listAccounts();
    if (!mounted) return;
    if (accounts.isEmpty) {
      _showMessage('ابتدا یک حساب اضافه کنید.');
      _goToFinance();
      return;
    }
    final result = await showModalBottomSheet<QuickFinancialEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) =>
          QuickFinancialEntrySheet(accounts: accounts, income: income),
    );
    if (!mounted || result == null) return;
    if (result.moreOptions) {
      _goToFinance();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _financePageKey.currentState?.openTransactionForm(income: income);
        }
      });
      return;
    }
    try {
      await FinanceUseCases(_financeRepository).record(
        account: result.account!,
        type: result.income
            ? AccountEntryType.income
            : AccountEntryType.expense,
        amount: Money(
          minorUnits: result.amount,
          currency: result.account!.currency,
        ),
        occurredAt: DateTime.now(),
        note: result.note,
        category: result.income ? 'دریافت' : 'عمومی',
      );
      await _refresh();
      if (mounted) {
        _showMessage(result.income ? 'درآمد ثبت شد.' : 'هزینه ثبت شد.');
      }
    } catch (_) {
      if (mounted) _showMessage('ثبت انجام نشد؛ دوباره تلاش کنید.');
    }
  }

  Future<void> _showQuickTransfer() async {
    final accounts = await _financeRepository.listAccounts();
    if (!mounted) return;
    if (accounts.length < 2) {
      _showMessage('برای انتقال، دست‌کم دو حساب فعال لازم است.');
      _goToFinance();
      return;
    }
    final result = await showModalBottomSheet<QuickTransfer>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => QuickTransferSheet(accounts: accounts),
    );
    if (!mounted || result == null) return;
    try {
      await FinanceUseCases(_financeRepository).transfer(
        from: result.from,
        to: result.to,
        amount: Money(
          minorUnits: result.amount,
          currency: result.from.currency,
        ),
        occurredAt: DateTime.now(),
      );
      await _refresh();
      if (mounted) _showMessage('انتقال ثبت شد.');
    } catch (_) {
      if (mounted) _showMessage('ثبت انتقال انجام نشد؛ دوباره تلاش کنید.');
    }
  }

  void _goToFinance() {
    setState(() => _selectedIndex = 2);
    _pageController.animateToPage(
      2,
      duration: PlanActMotion.standard,
      curve: PlanActMotion.curve,
    );
  }

  Future<void> _showCommitmentDetails(Commitment commitment) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: Text(commitment.title),
                  subtitle: Text(_statusLabel(commitment.status)),
                ),
                if (commitment.status == CommitmentStatus.active)
                  ListTile(
                    leading: const Icon(Icons.check_circle_outline),
                    title: const Text('انجام شد'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _applyStatus(commitment, CommitmentStatus.completed);
                    },
                  ),
                if (commitment.status == CommitmentStatus.active)
                  ListTile(
                    leading: const Icon(Icons.pause_circle_outline),
                    title: const Text('توقف موقت'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _applyStatus(commitment, CommitmentStatus.paused);
                    },
                  ),
                if (commitment.status == CommitmentStatus.paused)
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('ادامه'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _applyStatus(commitment, CommitmentStatus.active);
                    },
                  ),
                if (commitment.status == CommitmentStatus.active ||
                    commitment.status == CommitmentStatus.paused)
                  ListTile(
                    leading: const Icon(Icons.cancel_outlined),
                    title: const Text('لغو تعهد'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _applyStatus(commitment, CommitmentStatus.cancelled);
                    },
                  ),
                if (commitment.status != CommitmentStatus.archived)
                  ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: const Text('بایگانی'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _applyStatus(commitment, CommitmentStatus.archived);
                    },
                  ),
                if (commitment.status == CommitmentStatus.archived)
                  ListTile(
                    leading: const Icon(Icons.unarchive_outlined),
                    title: const Text('بازگردانی از بایگانی'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _restoreCommitment(commitment);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('جزئیات و ویرایش'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CommitmentDetailsPage(
                          commitment: commitment,
                          repository: _repository,
                          planRepository: _planRepository,
                          expectationRepository: _expectationRepository,
                          occurrenceExecutor: PersistedOccurrenceActionExecutor(
                            plans: _planRepository,
                            actuals: _repository is DriftCommitmentRepository
                                ? DriftActualRepository(_repository.database)
                                : null,
                            reminders: _createCommitmentPlan.reminderService,
                            replacements:
                                _repository is DriftCommitmentRepository
                                ? DriftReplacementRepository(
                                    _repository.database,
                                  )
                                : null,
                            policyRepository:
                                _repository is DriftCommitmentRepository
                                ? DriftSessionPolicyRepository(
                                    _repository.database,
                                  )
                                : null,
                          ),
                          onSaved: _refresh,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyStatus(
    Commitment commitment,
    CommitmentStatus status,
  ) async {
    try {
      final id = commitment.id;
      switch (status) {
        case CommitmentStatus.active:
          await ResumeCommitment(_repository)(id);
        case CommitmentStatus.paused:
          await PauseCommitment(_repository)(id);
        case CommitmentStatus.completed:
          await CompleteCommitment(_repository)(id);
        case CommitmentStatus.cancelled:
          await CancelCommitment(_repository)(id);
        case CommitmentStatus.archived:
          await ArchiveCommitment(_repository)(id);
      }
      await _refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ذخیرهٔ وضعیت انجام نشد؛ دوباره تلاش کنید.'),
        ),
      );
    }
  }

  Future<void> _restoreCommitment(Commitment commitment) async {
    try {
      await RestoreCommitment(_repository)(commitment.id);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعهد از بایگانی بازگردانی شد.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('بازگردانی تعهد انجام نشد؛ دوباره تلاش کنید.'),
        ),
      );
    }
  }

  Future<void> _showTimeline() async {
    final items =
        _commitments
            .where(
              (item) =>
                  item.status != CommitmentStatus.completed &&
                  item.status != CommitmentStatus.cancelled &&
                  item.status != CommitmentStatus.archived,
            )
            .toList()
          ..sort((a, b) {
            final first = _firstScheduledDate(a);
            final second = _firstScheduledDate(b);
            if (first == null) {
              return second == null ? a.title.compareTo(b.title) : 1;
            }
            if (second == null) {
              return -1;
            }
            return first.compareTo(second);
          });
    await showDialog<void>(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Text('خط زمانی تعهدات باقی‌مانده'),
          content: SizedBox(
            width: double.maxFinite,
            child: items.isEmpty
                ? const Text('تعهد باقی‌مانده‌ای وجود ندارد.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(PersianNumbers.format(index + 1)),
                        ),
                        title: Text(item.title),
                        subtitle: Text(
                          '${_firstScheduledDate(item) == null ? 'زمان‌بندی در دسترس نیست' : _formatDate(_firstScheduledDate(item)!)} · '
                          '${_statusLabel(item.status)}',
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _showCommitmentDetails(item);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('بستن'),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? _firstScheduledDate(Commitment commitment) {
    final dates = [...?_scheduledDates[commitment.id.value]]..sort();
    return dates.firstOrNull;
  }

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final date = JalaliDate.fromDateTime(local);
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '${PersianDateFormatter.date(date)} ${PersianNumbers.format(date.year)}، ${PersianNumbers.format(time)}';
  }

  Future<void> _archiveCommitment(Commitment commitment) async {
    if (commitment.status == CommitmentStatus.archived) return;
    try {
      await ArchiveCommitment(_repository)(commitment.id);
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('تعهد بایگانی شد.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('بایگانی انجام نشد؛ دوباره تلاش کنید.')),
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayPage(
        commitments: _commitments,
        scheduledDates: _scheduledDates,
        dashboard: _todayDashboard,
        actionCenter: _todayActionCenter,
        error: _todayError,
        onRetry: _refresh,
        onAdd: _showCapture,
        onCommitmentTap: _showCommitmentDetails,
        onCommitmentArchive: _archiveCommitment,
        onReview: (item) {
          if (item.type != TodayActionItemType.financialReview) {
            _openInbox();
            return;
          }
          setState(() => _selectedIndex = 2);
          _pageController.animateToPage(
            2,
            duration: PlanActMotion.standard,
            curve: PlanActMotion.curve,
          );
        },
      ),
      CalendarPage(
        holidayProvider:
            widget.holidayPackages?.provider ?? const IranianHolidayProvider(),
        commitments: _commitments,
        occurrences: _calendarOccurrences,
        reminderRules: _calendarReminderRules,
        scheduledDates: _scheduledDates,
        onCommitmentTap: _showCommitmentDetails,
      ),
      FinancePage(
        key: _financePageKey,
        repository: _financeRepository,
        expectationRepository: _expectationRepository,
      ),
      _MorePage(
        onInbox: _openInbox,
        settings: SettingsPage(
          holidayPackages: widget.holidayPackages,
          onHolidaysChanged: () => setState(() {}),
          enableReminders: _repository is DriftCommitmentRepository
              ? _enableReminders
              : null,
          backupActions: widget.backupActions,
          backupMessage: widget.backupMessage,
          settings: widget.settings,
          themeMode: widget.themeMode,
          appLockEnabled: widget.appLockEnabled,
          appLockController: widget.appLockController,
          onAppLockChanged: widget.onAppLockChanged,
          onThemeModeChanged: widget.onThemeModeChanged,
          onAbout: () => Navigator.of(context)
              .push(MaterialPageRoute<void>(builder: (_) => const AboutPage())),
        ),
      ),
    ];
    final titles = ['امروز', 'تقویم', 'مدیریت مالی', 'بیشتر'];
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Transform.scale(
                  scale: 1.14,
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(titles[_selectedIndex]),
          ],
        ),
        actions: [
          PopupMenuButton<_AppMenuAction>(
            tooltip: 'گزینه‌های بیشتر',
            icon: const Icon(Icons.more_horiz),
            onSelected: (action) {
              if (action == _AppMenuAction.addCommitment) {
                _showCapture();
              } else if (action == _AppMenuAction.timeline) {
                _showTimeline();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _AppMenuAction.addCommitment,
                child: ListTile(
                  leading: Icon(Icons.add_task),
                  title: Text('افزودن تعهد'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _AppMenuAction.timeline,
                child: ListTile(
                  leading: Icon(Icons.timeline),
                  title: Text('خط زمانی تعهدات'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          children: pages,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'افزودن سریع',
        onPressed: _showQuickAdd,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(
            index,
            duration: PlanActMotion.standard,
            curve: PlanActMotion.curve,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'امروز',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'تقویم',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'مالی',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'بیشتر'),
        ],
      ),
    );
  }
}

enum _AppMenuAction { addCommitment, timeline }

class CommitmentDetailsPage extends StatefulWidget {
  const CommitmentDetailsPage({
    super.key,
    required this.commitment,
    required this.repository,
    required this.planRepository,
    required this.expectationRepository,
    required this.occurrenceExecutor,
    required this.onSaved,
  });
  final Commitment commitment;
  final CommitmentRepository repository;
  final CommitmentPlanRepository planRepository;
  final FinancialExpectationRepository expectationRepository;
  final OccurrenceActionExecutor occurrenceExecutor;
  final Future<void> Function() onSaved;
  @override
  State<CommitmentDetailsPage> createState() => _CommitmentDetailsPageState();
}

class _CommitmentDetailsPageState extends State<CommitmentDetailsPage> {
  late final _title = TextEditingController(text: widget.commitment.title);
  late final _description = TextEditingController(
    text: widget.commitment.description ?? '',
  );
  late CommitmentPriority _priority = widget.commitment.priority;
  bool _saving = false;
  bool get _dirty =>
      _title.text != widget.commitment.title ||
      _description.text != (widget.commitment.description ?? '') ||
      _priority != widget.commitment.priority;
  @override
  void initState() {
    super.initState();
    _title.addListener(_onDraftChanged);
    _description.addListener(_onDraftChanged);
  }

  void _onDraftChanged() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<bool> _confirmLeave() async =>
      !_dirty ||
      (await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('تغییرات ذخیره نشده'),
              content: const Text('تغییرات ذخیره نشده‌اند. خارج می‌شوید؟'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('ادامهٔ ویرایش'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('خروج بدون ذخیره'),
                ),
              ],
            ),
          ) ??
          false);
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await UpdateCommitmentMetadata(widget.repository)(
        commitmentId: widget.commitment.id,
        title: _title.text,
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        priority: _priority,
      );
      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ذخیرهٔ تغییرات انجام نشد؛ دوباره تلاش کنید.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) async {
      if (!didPop && await _confirmLeave() && context.mounted) {
        Navigator.of(context).pop();
      }
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('جزئیات تعهد')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'وضعیت: ${_statusLabel(widget.commitment.status)}',
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 16),
          Text(
            'نوع: ${_kindLabel(widget.commitment.kind)}',
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'عنوان'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'توضیحات'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<CommitmentPriority>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'اولویت'),
            items: CommitmentPriority.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_priorityLabel(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _priority = value);
            },
          ),
          const SizedBox(height: 24),
          FutureBuilder<CommitmentPlan?>(
            future: widget.planRepository.findByCommitmentId(
              widget.commitment.id,
            ),
            builder: (context, snapshot) {
              final occurrences = snapshot.data?.occurrences ?? const [];
              if (occurrences.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('نوبت‌ها'),
                  const SizedBox(height: 8),
                  for (final occurrence in occurrences)
                    OccurrenceActionRow(
                      occurrence: occurrence,
                      executor: widget.occurrenceExecutor,
                      key: ValueKey(
                        '${occurrence.id}:${occurrence.currentScheduledAt}:${occurrence.status}',
                      ),
                      onChanged: () async {
                        await widget.onSaved();
                        if (mounted) setState(() {});
                      },
                      onEdit: widget.planRepository is CommitmentPlanTransaction
                          ? (selected) async {
                              final selection =
                                  await showDialog<ScheduleEditSelection>(
                                    context: context,
                                    builder: (_) => EditScheduleDialog(
                                      occurrence: selected,
                                      recurring:
                                          snapshot.data!.schedule.mode !=
                                          ScheduleMode.oneOff,
                                    ),
                                  );
                              if (selection == null || !mounted) return;
                              try {
                                final executor = widget.occurrenceExecutor;
                                final pending =
                                    await EditCommitmentSchedule(
                                      widget.planRepository,
                                      reminders:
                                          executor
                                              is PersistedOccurrenceActionExecutor
                                          ? executor.reminders
                                          : null,
                                    )(
                                      commitmentId: widget.commitment.id,
                                      expected: selected,
                                      scheduledAt: selection.scheduledAt,
                                      scope: selection.scope,
                                      now: DateTime.now(),
                                    );
                                await widget.onSaved();
                                if (!context.mounted) return;
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      pending
                                          ? 'زمان ذخیره شد؛ هماهنگ‌سازی یادآوری در انتظار است.'
                                          : 'زمان ذخیره شد؛ سوابق قبلی محفوظ است.',
                                    ),
                                  ),
                                );
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'تغییر زمان انجام نشد. نوبت‌های گذشته، دستی یا تغییر تاریخ سری ماهانه و سالانه قابل ویرایش نیستند؛ نوبت را دوباره بررسی کنید.',
                                    ),
                                  ),
                                );
                              }
                            }
                          : null,
                    ),
                  if (widget.occurrenceExecutor
                      case final PersistedOccurrenceActionExecutor executor)
                    if (executor.reminders != null)
                      for (final occurrence in occurrences)
                        OccurrenceReminders(
                          key: ValueKey(
                            'reminders:${occurrence.id}:${occurrence.status}:${occurrence.currentScheduledAt}',
                          ),
                          occurrence: occurrence,
                          service: executor.reminders!,
                          onSaved: widget.onSaved,
                        ),
                  const SizedBox(height: 16),
                  ExpansionTile(
                    title: const Text('انتظار مالی نوبت‌ها'),
                    children: [
                      const Text(
                        'برای هر نوبتِ این تعهد، مبلغ جداگانه و اختیاری ثبت کنید.',
                      ),
                      for (final occurrence in occurrences)
                        _FinancialExpectationOccurrenceRow(
                          occurrence: occurrence,
                          useCases: FinancialExpectationUseCases(
                            widget.expectationRepository,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator()
                : const Text('ذخیره'),
          ),
        ],
      ),
    ),
  );
}

class _FinancialExpectationOccurrenceRow extends StatefulWidget {
  const _FinancialExpectationOccurrenceRow({
    required this.occurrence,
    required this.useCases,
  });

  final Occurrence occurrence;
  final FinancialExpectationUseCases useCases;

  @override
  State<_FinancialExpectationOccurrenceRow> createState() =>
      _FinancialExpectationOccurrenceRowState();
}

class _FinancialExpectationOccurrenceRowState
    extends State<_FinancialExpectationOccurrenceRow> {
  bool _expanded = false;
  List<FinancialAccount> _accounts = const [];
  bool _loadingAccounts = false;

  Future<void> _expand(bool expanded) async {
    setState(() => _expanded = expanded);
    if (!expanded || _loadingAccounts || _accounts.isNotEmpty) return;
    setState(() => _loadingAccounts = true);
    try {
      final accounts = await widget.useCases.repository.listAccounts();
      if (mounted) setState(() => _accounts = accounts);
    } finally {
      if (mounted) setState(() => _loadingAccounts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduled = widget.occurrence.currentScheduledAt;
    final dateLabel = scheduled is DateTime
        ? PersianDateFormatter.date(JalaliDate.fromDateTime(scheduled))
        : 'تاریخ نوبت مشخص نشده است';
    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: _expand,
        title: Text(dateLabel),
        subtitle: const Text('برای ثبت یا ویرایش انتظار مالی باز کنید'),
        children: [
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: _loadingAccounts
                  ? const LinearProgressIndicator()
                  : FinancialExpectationEditor(
                      occurrenceId: widget.occurrence.id,
                      useCases: widget.useCases,
                      accounts: _accounts,
                    ),
            ),
        ],
      ),
    );
  }
}

String _statusLabel(CommitmentStatus status) => switch (status) {
  CommitmentStatus.active => 'فعال',
  CommitmentStatus.paused => 'متوقف‌شده',
  CommitmentStatus.completed => 'تکمیل‌شده',
  CommitmentStatus.cancelled => 'لغوشده',
  CommitmentStatus.archived => 'بایگانی‌شده',
};

String _kindLabel(CommitmentKind kind) => switch (kind) {
  CommitmentKind.oneOff => 'یک‌باره',
  CommitmentKind.recurring => 'تکرارشونده',
};

String _priorityLabel(CommitmentPriority priority) => switch (priority) {
  CommitmentPriority.low => 'کم',
  CommitmentPriority.normal => 'عادی',
  CommitmentPriority.high => 'زیاد',
  CommitmentPriority.urgent => 'فوری',
};

class _MorePage extends StatelessWidget {
  const _MorePage({required this.onInbox, required this.settings});

  final VoidCallback onInbox;
  final Widget settings;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        child: ListTile(
          leading: const Icon(Icons.inbox_outlined),
          title: const Text('صندوق ورودی'),
          subtitle: const Text('بررسی پیام‌های واردشده پیش از ثبت مالی'),
          trailing: const Icon(Icons.chevron_left),
          onTap: onInbox,
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('تنظیمات'),
          subtitle: const Text('تنظیمات عمومی برنامه'),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('تنظیمات')),
                body: settings,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
