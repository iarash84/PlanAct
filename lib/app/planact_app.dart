import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/commitments/application/commitment_progress_reader.dart';
import 'package:planact/features/commitments/data/drift_commitment_progress_reader.dart';
import 'package:planact/features/commitments/presentation/commitment_progress_section.dart';
import 'package:planact/features/search/application/search_reader.dart';
import 'package:planact/features/search/data/drift_search_reader.dart';
import 'package:planact/features/search/presentation/search_page.dart';
import 'package:planact/features/notes/application/calendar_note_repository.dart';
import 'package:planact/features/notes/data/drift_calendar_note_repository.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/notes/presentation/calendar_note_editor.dart';
import 'package:planact/core/application/undo_token.dart';
import 'package:planact/core/presentation/undo_feedback.dart';
import 'package:planact/features/scheduling/application/schedule_undo.dart';
import 'package:planact/features/scheduling/presentation/schedule_undo_button.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/features/commitments/data/drift_commitment_correction_repository.dart';
import 'package:planact/features/commitments/presentation/commitment_correction_card.dart';
import 'package:planact/features/scheduling/application/extend_recurring_schedules.dart';
import 'package:planact/features/commitments/presentation/commitment_color_picker.dart';
import 'package:planact/features/commitments/presentation/commitment_browse_sheet.dart';
import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/presentation/holiday_package_settings_card.dart';
import 'package:planact/features/backup/presentation/backup_settings_card.dart';
import 'package:planact/features/calendar/domain/holiday_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:planact/core/presentation/holiday_provider_scope.dart';
import 'package:planact/features/classification/application/tag_repository.dart';
import 'package:planact/features/classification/data/drift_tag_repository.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/reports/data/drift_reports_reader.dart';
import 'package:planact/features/reports/application/repository_reports_reader.dart';
import 'package:planact/features/reports/presentation/reports_page.dart';
import 'package:planact/features/reminders/presentation/occurrence_reminders.dart';
import 'package:planact/features/scheduling/application/edit_commitment_schedule.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';
import 'package:planact/features/scheduling/presentation/edit_schedule_dialog.dart';
import 'package:planact/features/actuals/data/drift_actual_repository.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/features/backup/application/backup_actions.dart';
import 'package:planact/app/app_lock.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/presentation/sms_sync_controller.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/application/checklist_repository.dart';
import 'package:planact/features/commitments/data/drift_checklist_repository.dart';
import 'package:planact/features/commitments/presentation/checklist_page.dart';
import 'package:planact/features/search/domain/search.dart';
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
import 'package:planact/features/calendar/presentation/planned_occurrence_widgets.dart';
import 'package:planact/features/scheduling/application/planned_occurrences.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';
import 'package:planact/features/commitments/application/commitment_draft.dart';
import 'package:planact/features/sessions/data/drift_session_repositories.dart';
import 'package:planact/features/quick_add/presentation/quick_add_sheet.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/application/reminder_platform.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/core/money/money.dart';
import 'package:planact/features/reconciliation/application/contextual_reconciliation.dart';
import 'package:planact/features/reconciliation/application/relationship_review_repository.dart';
import 'package:planact/features/reconciliation/domain/relationship_review.dart';
import 'package:planact/features/reconciliation/application/reconciliation_use_cases.dart';
import 'package:planact/features/reconciliation/data/drift_reconciliation_repository.dart';
import 'package:planact/features/reconciliation/presentation/transaction_relationship_page.dart';
import 'package:planact/features/reconciliation/presentation/relationship_queue_page.dart';
import 'package:planact/features/reconciliation/application/bulk_relationship_review.dart';

class PlanActApp extends StatefulWidget {
  const PlanActApp({
    super.key,
    this.repository,
    this.tagRepository,
    this.planRepository,
    this.holidayPackages,
    this.backupActions,
    this.backupMessage,
    this.smsSource,
  });
  final AndroidSmsSource? smsSource;
  final HolidayPackageService? holidayPackages;
  final BackupActions? backupActions;
  final String? backupMessage;

  final CommitmentRepository? repository;
  final TagRepository? tagRepository;
  final CommitmentPlanRepository? planRepository;

  @override
  State<PlanActApp> createState() => _PlanActAppState();
}

class _PlanActAppState extends State<PlanActApp> {
  ThemeMode _themeMode = ThemeMode.system;
  AppSettings? _settings;
  late MoneyUnitController _moneyUnits;
  String? _moneyUnitError;
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
    _moneyUnits = MoneyUnitController(_settings);
    _loadMoneyUnit();
  }

  Future<void> _loadMoneyUnit() async {
    try {
      await _moneyUnits.load();
      if (mounted) setState(() => _moneyUnitError = null);
    } catch (_) {
      if (mounted) {
        setState(
          () => _moneyUnitError = PersianCopy.planactAppLoadMoneyUnitMessage,
        );
      }
    }
  }

  @override
  void dispose() {
    _moneyUnits.dispose();
    super.dispose();
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
              PersianCopy.planactAppLoadAppLockSettingMessage,
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
      onGenerateTitle: (context) => planActL10n(context).appName,
      locale: const Locale('fa'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      theme: PlanActTheme.light(),
      darkTheme: PlanActTheme.dark(),
      themeMode: _themeMode,
      builder: (context, child) => HolidayProviderScope(
        readProvider: () =>
            widget.holidayPackages?.provider ?? const IranianHolidayProvider(),
        child: MoneyUnitScope(
          controller: _moneyUnits,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: AppLockGate(
              enabled: _appLockEnabled,
              controller: _appLockController,
              child: !_moneyUnits.ready
                  ? Scaffold(
                      body: Center(
                        child: _moneyUnitError == null
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_moneyUnitError!),
                                  TextButton(
                                    onPressed: _loadMoneyUnit,
                                    child: Text(
                                      planActL10n(context).commonRetry,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    )
                  : child ?? const SizedBox.shrink(),
            ),
          ),
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
                            child: Text(planActL10n(context).commonRetry),
                          ),
                        ],
                      ),
              ),
            )
          : HomeShell(
              smsSource: widget.smsSource,
              holidayPackages: widget.holidayPackages,
              backupActions: widget.backupActions,
              backupMessage: widget.backupMessage,
              repository: widget.repository,
              tagRepository: widget.tagRepository,
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
    this.tagRepository,
    this.planRepository,
    this.settings,
    this.holidayPackages,
    this.backupActions,
    this.backupMessage,
    this.smsSource,
    this.themeMode = ThemeMode.system,
    this.appLockEnabled = false,
    this.appLockController,
    this.onAppLockChanged = _ignoreAppLockChange,
    this.onThemeModeChanged = _ignoreThemeChange,
  });

  static void _ignoreThemeChange(ThemeMode _) {}
  static Future<void> _ignoreAppLockChange(bool _) async {}

  final CommitmentRepository? repository;
  final AndroidSmsSource? smsSource;
  final TagRepository? tagRepository;
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

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late final CalendarNoteRepository _noteRepository =
      _repository is DriftCommitmentRepository
      ? DriftCalendarNoteRepository(_repository.database)
      : InMemoryCalendarNoteRepository();
  int _notesRevision = 0;
  late final PageController _pageController = PageController();
  late final CommitmentRepository _repository =
      widget.repository ?? InMemoryCommitmentRepository();
  late final TagRepository _tagRepository =
      widget.tagRepository ??
      (_repository is DriftCommitmentRepository
          ? DriftTagRepository(_repository.database)
          : InMemoryTagRepository());
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
      final rules = await DriftReminderRepository(repository.database)
          .listRules();
      if (rules.any((r) => r.enabled && r.delivery == ReminderDelivery.alarm) &&
          !await platform.requestAlarmChannelPermission()) {
        return false;
      }
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
  final _commitmentViewsRevision = ValueNotifier<int>(0);
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
  late final AndroidSmsSource _smsSource =
      widget.smsSource ?? AndroidSmsSource();
  SmsSyncController? _smsSync;

  void _smsSyncChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshWithSms() async {
    await _smsSync?.refresh();
    await _refresh();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_repository is DriftCommitmentRepository) {
      _smsSync = SmsSyncController(
        inbox: _inboxUseCases,
        source: _smsSource,
        onChanged: _refresh,
      )..addListener(_smsSyncChanged);
      _smsSync!.start();
    }
    _maintainSchedules();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maintainSchedules();
  }

  Future<void> _maintainSchedules() async {
    try {
      final plans = _planRepository;
      if (plans is RecurringScheduleMaintenance) {
        await ExtendRecurringSchedules(plans as RecurringScheduleMaintenance)
            .call(DateTime.now());
      }
      await _refresh();
      if (_repository case final DriftCommitmentRepository repository) {
        try {
          await ReminderService(
            repository: DriftReminderRepository(repository.database),
            platform: AndroidReminderPlatformAdapter(),
          ).reconcile(now: DateTime.now().toUtc());
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(PersianCopy.planactAppMaintainSchedulesContent),
              ),
            );
          }
        }
      }
    } catch (_) {
      await _refresh();
      if (mounted) {
        setState(
          () => _todayError = PersianCopy.planactAppMaintainSchedulesMessage,
        );
      }
    }
  }

  Future<void> _tagsChanged() => _refresh(throwOnFailure: true);

  Future<void> _refresh({bool throwOnFailure = false}) async {
    try {
      final persisted = await _repository.list();
      final allTags = await _tagRepository.list();
      final items = <Commitment>[];
      for (final item in persisted) {
        final ids = await _tagRepository.tagsFor(
          item.id.value,
          TaggableType.commitment,
        );
        items.add(
          item.withTags(
            allTags
                .where((tag) => ids.contains(tag.id))
                .map((tag) => tag.label)
                .toSet(),
          ),
        );
      }
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
      final reviewEntries = <RelationshipReviewEntry>[];
      final reviewRepository = _reconciliation.repository;
      if (reviewRepository is RelationshipReviewRepository) {
        for (final entry in entries) {
          reviewEntries.addAll(
            await (reviewRepository as RelationshipReviewRepository)
                .reviewHistory(entry),
          );
        }
      }
      final dashboard = _attentionEngine.build(
        now: DateTime.now(),
        commitments: items,
        plans: plans,
        expectations: expectations,
        matches: matches,
        inboxSuggestions: inboxSuggestions,
        entries: entries,
        accounts: accounts,
        reviewEntries: reviewEntries,
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
        reviewEntries: reviewEntries,
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
        _commitmentViewsRevision.value++;
      }
    } catch (_) {
      if (mounted) {
        setState(() => _todayError = PersianCopy.planactAppRefreshMessage);
        _commitmentViewsRevision.value++;
      }
      if (throwOnFailure) rethrow;
    }
  }

  late final ReconciliationUseCases _reconciliation = ReconciliationUseCases(
    _repository is DriftCommitmentRepository
        ? DriftReconciliationRepository(_repository.database)
        : InMemoryReconciliationRepository(),
  );

  Future<void> _openRelationshipQueue() async {
    final repository = _reconciliation.repository;
    if (repository is! RelationshipReviewRepository) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => RelationshipQueuePage(
          queue: RelationshipQueue(
            _financeRepository,
            repository as RelationshipReviewRepository,
          ),
          onOpen: _openRelationship,
          onDataChanged: () async {
            await _refresh();
            await _financePageKey.currentState?.refreshData();
          },
        ),
      ),
    );
    await _refresh();
    await _financePageKey.currentState?.refreshData();
  }

  Future<void> _openRelationship(StableId transactionId) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TransactionRelationshipPage(
          transactionId: transactionId,
          onOpenQueue: _openRelationshipQueue,
          flow: ContextualReconciliation(
            finance: _financeRepository,
            commitments: _repository,
            plans: _planRepository,
            reconciliation: _reconciliation,
          ),
        ),
      ),
    );
    if (saved == true) {
      await _refresh();
      _showMessage(PersianCopy.planactAppOpenRelationshipMessage);
    }
  }

  Future<void> _openInbox() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text(PersianCopy.planactAppOpenInboxTitle),
          ),
          body: InboxPage(
            tagRepository: _tagRepository,
            inbox: _inboxUseCases,
            onDataChanged: () async {
              await _refresh();
              await _financePageKey.currentState?.refreshData();
            },
            finance: _financeRepository,
            onDetermineRelationship: _openRelationship,
            smsSource: _smsSource,
            smsSync: _smsSync,
          ),
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _showCapture() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => QuickCaptureSheet(
        onSave: _saveCapturedCommitment,
        tagRepository: _tagRepository,
      ),
    );
  }

  Future<void> _saveCapturedCommitment(CommitmentDraft draft) async {
    final startAt = draft.scheduledDates.first;
    final plan = await _createCommitmentPlan(
      title: draft.title,
      startAt: startAt,
      kind: draft.kind,
      priority: draft.priority,
      color: draft.color,
      description: draft.description,
      tags: draft.tags,
      attachmentIds: draft.attachmentIds,
      frequency: draft.frequency,
      recurrenceCalendar: draft.recurrenceCalendar,
      weekdays: draft.weekdays,
      occurrenceCount: draft.termination == RecurrenceTermination.count
          ? draft.occurrenceCount
          : null,
      endDate: draft.termination == RecurrenceTermination.endDate
          ? draft.endDate
          : null,
      reminderOffsets: draft.reminderOffsets,
      reminderDelivery: draft.reminderDelivery,
      entitlementUnits: draft.entitlement == EntitlementDraft.fixedUnits
          ? draft.entitlementUnits
          : null,
      financialDirection: draft.financialMeaning.expectationDirection,
      financialAmount: draft.financialAmount,
    );
    try {
      await _refresh();
    } catch (_) {
      _showMessage(PersianCopy.planactAppSaveCapturedCommitmentMessage);
    }
    if (plan.reminderDeliveryPending) {
      _showMessage(PersianCopy.planactAppSaveCapturedCommitmentMessage2);
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
      case QuickAddAction.note:
        await _showNote();
      case QuickAddAction.commitment:
        await _showCapture();
      case QuickAddAction.expense:
      case QuickAddAction.income:
        await _showQuickFinancialEntry(income: action == QuickAddAction.income);
      case QuickAddAction.transfer:
        await _showQuickTransfer();
    }
  }

  Future<void> _showNote([CalendarNote? note]) async {
    final result = await CalendarNoteEditor.show(
      context,
      _noteRepository,
      note: note,
    );
    if (!mounted) return;
    setState(() => _notesRevision++);
    if (result != null) _showMessage(planActL10n(context).calendarNoteSaved);
  }

  Future<void> _showQuickFinancialEntry({required bool income}) async {
    final accounts = await _financeRepository.listAccounts();
    if (!mounted) return;
    if (accounts.isEmpty) {
      _showMessage(PersianCopy.planactAppShowQuickFinancialEntryMessage);
      _goToFinance();
      return;
    }
    final result = await showModalBottomSheet<QuickFinancialEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => QuickFinancialEntrySheet(
        accounts: accounts,
        income: income,
        tagRepository: _tagRepository,
        onSave: _saveQuickFinancialEntry,
      ),
    );
    if (!mounted || result == null) return;
    if (result.moreOptions) {
      _goToFinance();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _financePageKey.currentState?.openTransactionForm(
            income: income,
            initialTags: result.tags,
          );
        }
      });
      return;
    }
  }

  Future<void> _saveQuickFinancialEntry(QuickFinancialEntry result) async {
    await FinanceUseCases(_financeRepository).record(
      account: result.account!,
      type: result.income ? AccountEntryType.income : AccountEntryType.expense,
      amount: Money(
        minorUnits: result.amount,
        currency: result.account!.currency,
      ),
      occurredAt: DateTime.now(),
      note: result.note,
      tags: result.tags,
      category: result.income ? 'دریافت' : 'عمومی',
    );
    try {
      await _refresh();
      _showMessage(
        result.income
            ? PersianCopy.planactAppSaveQuickFinancialEntryMessage
            : PersianCopy.planactAppSaveQuickFinancialEntryMessage2,
      );
    } catch (_) {
      _showMessage(PersianCopy.planactAppSaveQuickFinancialEntryMessage3);
    }
  }

  Future<void> _showQuickTransfer() async {
    final accounts = await _financeRepository.listAccounts();
    if (!mounted) return;
    if (accounts.length < 2) {
      _showMessage(PersianCopy.planactAppShowQuickTransferMessage);
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
      if (mounted) {
        _showMessage(PersianCopy.planactAppShowQuickTransferMessage2);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(PersianCopy.planactAppShowQuickTransferMessage3);
      }
    }
  }

  void _goToFinance() {
    setState(() => _selectedIndex = 2);
    _pageController.animateToPage(
      2,
      duration: PlanActMotion.duration(context),
      curve: PlanActMotion.curve,
    );
  }

  Future<void> _showCommitmentDetails(Commitment commitment) async {
    final fresh = await _repository.findById(commitment.id);
    if (fresh == null) throw StateError('Commitment no longer exists');
    commitment = fresh;
    final lifecycle = _repository;
    final undo = lifecycle is CommitmentLifecycleRepository
        ? await (lifecycle as CommitmentLifecycleRepository).statusUndo(
            commitment.id,
          )
        : null;
    if (!mounted) return;
    final action = await showModalBottomSheet<Future<void> Function()>(
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
                    title: const Text(
                      PersianCopy.planactAppShowCommitmentDetailsTitle,
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        () => _applyStatus(
                          commitment,
                          CommitmentStatus.completed,
                        ),
                      );
                    },
                  ),
                if (commitment.status == CommitmentStatus.active)
                  ListTile(
                    leading: const Icon(Icons.pause_circle_outline),
                    title: const Text(
                      PersianCopy.planactAppShowCommitmentDetailsTitle2,
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        () => _applyStatus(commitment, CommitmentStatus.paused),
                      );
                    },
                  ),
                if (commitment.status == CommitmentStatus.paused)
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text(
                      PersianCopy.planactAppShowCommitmentDetailsTitle3,
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        () => _applyStatus(commitment, CommitmentStatus.active),
                      );
                    },
                  ),
                if (commitment.status == CommitmentStatus.active ||
                    commitment.status == CommitmentStatus.paused)
                  ListTile(
                    leading: const Icon(Icons.cancel_outlined),
                    title: const Text(
                      PersianCopy.planactAppShowCommitmentDetailsTitle4,
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        () => _applyStatus(
                          commitment,
                          CommitmentStatus.cancelled,
                        ),
                      );
                    },
                  ),
                if (commitment.status != CommitmentStatus.archived)
                  ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: const Text(
                      PersianCopy.planactAppShowCommitmentDetailsTitle5,
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        () =>
                            _applyStatus(commitment, CommitmentStatus.archived),
                      );
                    },
                  ),
                if (commitment.status == CommitmentStatus.archived)
                  ListTile(
                    leading: const Icon(Icons.unarchive_outlined),
                    title: const Text(
                      PersianCopy.planactAppShowCommitmentDetailsTitle6,
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        () => _restoreCommitment(commitment),
                      );
                    },
                  ),
                if (undo != null)
                  ListTile(
                    leading: const Icon(Icons.undo),
                    title: Text(planActL10n(sheetContext).undoStatusAction),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        () => _undoCommitmentStatus(commitment, undo),
                      );
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.checklist),
                  title: Text(planActL10n(sheetContext).checklistTitle),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    () => _openChecklist(commitment),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text(
                    PersianCopy.planactAppShowCommitmentDetailsTitle7,
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      () => _openReportCommitment(commitment),
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
    if (mounted && action != null) await action();
  }

  late final ChecklistRepository _checklists =
      _repository is DriftCommitmentRepository
      ? DriftChecklistRepository(_repository.database)
      : InMemoryChecklistRepository(_repository);

  Future<void> _openChecklist(Commitment commitment) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => ChecklistPage(
            repository: _checklists,
            commitmentId: commitment.id,
            title: commitment.title,
          ),
        ),
      );

  Future<void> _applyStatus(
    Commitment commitment,
    CommitmentStatus status,
  ) async {
    try {
      final id = commitment.id;
      switch (status) {
        case CommitmentStatus.active:
          if (commitment.status == CommitmentStatus.archived) {
            await RestoreCommitment(_repository)(id);
          } else {
            await ResumeCommitment(_repository)(id);
          }
        case CommitmentStatus.paused:
          await PauseCommitment(_repository)(id);
        case CommitmentStatus.completed:
          await CompleteCommitment(_repository)(id);
        case CommitmentStatus.cancelled:
          await CancelCommitment(_repository)(id);
        case CommitmentStatus.archived:
          await ArchiveCommitment(_repository)(id);
      }
    } catch (_) {
      if (mounted) {
        showRecordedActionFeedback(context, planActL10n(context).undoConflict);
      }
      return;
    }
    UndoToken? token;
    final lifecycle = _repository;
    if (lifecycle is CommitmentLifecycleRepository) {
      token = await (lifecycle as CommitmentLifecycleRepository).statusUndo(
        commitment.id,
      );
    }
    final pending = await _reconcileStatusReminders();
    try {
      await _refresh(throwOnFailure: true);
    } catch (_) {
      if (mounted) {
        showRecordedActionFeedback(
          context,
          planActL10n(context).undoRefreshPending,
        );
      }
      return;
    }
    if (mounted) {
      showRecordedActionFeedback(
        context,
        pending
            ? planActL10n(context).planactAppBuildContent
            : planActL10n(context).undoStateSaved,
        onUndo: token == null
            ? null
            : () => _undoCommitmentStatus(commitment, token!),
      );
    }
  }

  Future<bool> _reconcileStatusReminders() async {
    try {
      await _createCommitmentPlan.reminderService?.reconcile(
        now: DateTime.now(),
      );
      return false;
    } catch (_) {
      return true;
    }
  }

  Future<void> _restoreCommitment(Commitment commitment) async {
    if (!await confirmRecordedAction(
          context,
          planActL10n(context).legacyArchiveRestoreMessage,
        ) ||
        !mounted) {
      return;
    }
    await _applyStatus(commitment, CommitmentStatus.active);
  }

  Future<void> _undoCommitmentStatus(
    Commitment commitment,
    UndoToken token,
  ) async {
    final lifecycle = _repository;
    if (lifecycle is! CommitmentLifecycleRepository) return;
    if (!await confirmRecordedAction(
          context,
          planActL10n(context).undoConfirmMessage,
        ) ||
        !mounted) {
      return;
    }
    try {
      await (lifecycle as CommitmentLifecycleRepository).undoStatus(
        commitment.id,
        token,
      );
    } catch (_) {
      if (mounted) {
        showRecordedActionFeedback(context, planActL10n(context).undoConflict);
      }
      return;
    }
    final pending = await _reconcileStatusReminders();
    try {
      await _refresh(throwOnFailure: true);
    } catch (_) {
      if (mounted) {
        showRecordedActionFeedback(
          context,
          planActL10n(context).undoRefreshPending,
        );
      }
      return;
    }
    if (mounted) {
      showRecordedActionFeedback(
        context,
        pending
            ? planActL10n(context).planactAppBuildContent
            : planActL10n(context).undoSuccess,
      );
    }
  }

  List<Commitment> _timelineItems(bool includeHistory) {
    final items =
        _commitments
            .where(
              (item) =>
                  includeHistory ||
                  (item.status != CommitmentStatus.completed &&
                      item.status != CommitmentStatus.cancelled &&
                      item.status != CommitmentStatus.archived),
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
    return items;
  }

  Future<void> _showTimeline({bool includeHistory = false}) async {
    await showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: AnimationStyle(
        duration: PlanActMotion.duration(context),
        reverseDuration: PlanActMotion.duration(context, PlanActMotion.short),
      ),
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: false,
      enableDrag: false,
      builder: (context) => ValueListenableBuilder<int>(
        valueListenable: _commitmentViewsRevision,
        builder: (context, revision, _) => CommitmentBrowseSheet(
          title: includeHistory
              ? planActL10n(context).commitmentHistoryTitle
              : planActL10n(context).planactAppShowTimelineTitle,
          items: _timelineItems(includeHistory),
          subtitle: (item) =>
              planActL10n(context).planactAppShowTimelineSubtitle2(
                _firstScheduledDate(item) == null
                    ? planActL10n(context).planactAppShowTimelineSubtitle
                    : _formatDate(_firstScheduledDate(item)!),
                _statusLabel(item.status),
              ),
          onOpen: _showCommitmentDetails,
          error: _todayError,
          onRetry: _refresh,
        ),
      ),
    );
  }

  DateTime? _firstScheduledDate(Commitment commitment) {
    final dates = [...?_scheduledDates[commitment.id.value]]..sort();
    return dates.firstOrNull;
  }

  Future<void> _openReports() => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ReportsPage(
        reader: _repository is DriftCommitmentRepository
            ? DriftReportsReader(_repository.database)
            : RepositoryReportsReader(
                commitments: _repository,
                plans: _planRepository,
                finance: _financeRepository,
                expectations: _expectationRepository,
                tags: _tagRepository,
              ),
        onOpenCommitment: _openReportCommitment,
        onOpenTransaction: _openRelationship,
      ),
    ),
  );

  CommitmentDetailsPage _detailsPage(Commitment commitment) =>
      CommitmentDetailsPage(
        commitment: commitment,
        repository: _repository,
        tagRepository: _tagRepository,
        planRepository: _planRepository,
        expectationRepository: _expectationRepository,
        occurrenceExecutor: PersistedOccurrenceActionExecutor(
          plans: _planRepository,
          actuals: _repository is DriftCommitmentRepository
              ? DriftActualRepository(_repository.database)
              : null,
          reminders: _createCommitmentPlan.reminderService,
          replacements: _repository is DriftCommitmentRepository
              ? DriftReplacementRepository(_repository.database)
              : null,
          policyRepository: _repository is DriftCommitmentRepository
              ? DriftSessionPolicyRepository(_repository.database)
              : null,
        ),
        onSaved: _tagsChanged,
        checklistRepository: _checklists,
      );

  Future<void> _openSearch() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => SearchPage(
          reader: _repository is DriftCommitmentRepository
              ? DriftSearchReader(_repository.database)
              : RepositorySearchReader(
                  commitments: _repository,
                  finance: _financeRepository,
                  notes: _noteRepository,
                  tags: _tagRepository,
                ),
          onOpenCommitment: _showCommitmentDetails,
          onOpenNote: _showNote,
          onOpenFinancial: _openSearchFinancial,
        ),
      ),
    );
    if (!mounted) return;
    await _refresh();
    await _financePageKey.currentState?.refreshData();
  }

  Future<void> _openReportCommitment(Commitment commitment) async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => _detailsPage(commitment)));
    if (mounted) await _refresh();
  }

  Future<void> _openSearchFinancial(SearchTarget target) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => FinancePage(
            repository: _financeRepository,
            expectationRepository: _expectationRepository,
            tagRepository: _tagRepository,
            onTagsChanged: _tagsChanged,
            onDataChanged: _refresh,
            onDetermineRelationship: _openRelationship,
            focusedRecordId: target.id,
            focusedKind: target is AccountSearchTarget
                ? FinanceRecordKind.account
                : FinanceRecordKind.entry,
          ),
        ),
      );

  String _formatDate(DateTime value) {
    final local = value.toLocal();
    final date = JalaliDate.fromDateTime(local);
    final time =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return PersianCopy.planactAppFormatDateMessage(
      (PersianDateFormatter.date(date)).toString(),
      (PersianNumbers.format(date.year)).toString(),
      (PersianNumbers.format(time)).toString(),
    );
  }

  Future<void> _archiveCommitment(Commitment commitment) async {
    if (commitment.status == CommitmentStatus.archived) return;
    await _applyStatus(commitment, CommitmentStatus.archived);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _smsSync?.removeListener(_smsSyncChanged);
    _smsSync?.dispose();
    _pageController.dispose();
    _commitmentViewsRevision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayPage(
        onOpenRelationshipQueue:
            _reconciliation.repository is RelationshipReviewRepository
            ? _openRelationshipQueue
            : null,
        commitments: _commitments,
        scheduledDates: _scheduledDates,
        dashboard: _todayDashboard,
        actionCenter: _todayActionCenter,
        error: _todayError,
        smsSyncError: _smsSync?.error,
        onRetry: _refreshWithSms,
        onRefresh: _refreshWithSms,
        onAdd: _showCapture,
        onCommitmentTap: _showCommitmentDetails,
        onCommitmentArchive: _archiveCommitment,
        onReview: (item) {
          if (item.attentionAction == AttentionAction.classifyTransaction &&
              item.sourceReference != null) {
            _openRelationship(StableId.parse(item.sourceReference!));
            return;
          }
          if (item.type != TodayActionItemType.financialReview) {
            _openInbox();
            return;
          }
          setState(() => _selectedIndex = 2);
          _pageController.animateToPage(
            2,
            duration: PlanActMotion.duration(context),
            curve: PlanActMotion.curve,
          );
        },
      ),
      CalendarPage(
        noteLoader: _noteRepository.loadRange,
        notesRevision: _notesRevision,
        onNoteTap: _showNote,
        holidayProvider:
            widget.holidayPackages?.provider ?? const IranianHolidayProvider(),
        commitments: _commitments,
        occurrences: _calendarOccurrences,
        plannedLoader: _planRepository is PlannedOccurrencesRepository
            ? (start, end) => (_planRepository as PlannedOccurrencesRepository)
                  .loadPlannedRange(
                    start,
                    end,
                    LocalDate.fromDateTime(DateTime.now()),
                  )
            : null,
        weekLoader: _planRepository is DriftCommitmentPlanRepository
            ? _planRepository.loadWeek
            : null,
        monthLoader: _planRepository is DriftCommitmentPlanRepository
            ? _planRepository.loadMonth
            : null,
        reminderRules: _calendarReminderRules,
        scheduledDates: _scheduledDates,
        onCommitmentTap: _showCommitmentDetails,
        onAdd: _showCapture,
      ),
      FinancePage(
        key: _financePageKey,
        embedded: true,
        repository: _financeRepository,
        onDetermineRelationship: _openRelationship,
        tagRepository: _tagRepository,
        onTagsChanged: _tagsChanged,
        onDataChanged: _refresh,
        expectationRepository: _expectationRepository,
      ),
      _MorePage(
        onInbox: _openInbox,
        onReports: _openReports,
        holidayPackages: widget.holidayPackages,
        onHolidaysChanged: () => setState(() {}),
        backupActions: widget.backupActions,
        backupMessage: widget.backupMessage,
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
    final titles = [
      planActL10n(context).commonToday,
      planActL10n(context).navigationCalendar,
      planActL10n(context).planactAppTitlesMessage,
      planActL10n(context).navigationMore,
    ];
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: PlanActMotion.duration(context, PlanActMotion.short),
          switchInCurve: PlanActMotion.curve,
          switchOutCurve: PlanActMotion.curve,
          child: Text(titles[_selectedIndex], key: ValueKey(_selectedIndex)),
        ),
        actions: [
          IconButton(
            key: const ValueKey('shell-search'),
            tooltip: planActL10n(context).searchTitle,
            onPressed: _openSearch,
            icon: const Icon(Icons.search),
          ),
          PopupMenuButton<_AppMenuAction>(
            tooltip: planActL10n(context).planactAppBuildTooltip,
            icon: const Icon(Icons.more_horiz),
            position: PopupMenuPosition.under,
            requestFocus: true,
            onSelected: (action) {
              if (action == _AppMenuAction.addCommitment) {
                _showCapture();
              } else if (action == _AppMenuAction.timeline) {
                _showTimeline();
              } else if (action == _AppMenuAction.history) {
                _showTimeline(includeHistory: true);
              } else if (action == _AppMenuAction.reports) {
                _openReports();
              } else if (action == _AppMenuAction.inbox) {
                _openInbox();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _AppMenuAction.addCommitment,
                child: ListTile(
                  leading: Icon(Icons.add_task),
                  title: Text(planActL10n(context).planactAppBuildTitle),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _AppMenuAction.timeline,
                child: ListTile(
                  leading: Icon(Icons.timeline),
                  title: Text(planActL10n(context).planactAppBuildTitle2),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _AppMenuAction.history,
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(planActL10n(context).commitmentHistoryTitle),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _AppMenuAction.reports,
                child: ListTile(
                  leading: Icon(Icons.bar_chart_outlined),
                  title: Text(planActL10n(context).planactAppBuildTitle3),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _AppMenuAction.inbox,
                child: ListTile(
                  leading: Icon(Icons.inbox_outlined),
                  title: Text(planActL10n(context).planactAppOpenInboxTitle),
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
          onPageChanged: (index) {
            setState(() => _selectedIndex = index);
            if (index == 0) _refresh();
          },
          children: pages
              .map(
                (page) => Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: PlanActSpacing.contentWidth,
                    ),
                    child: page,
                  ),
                ),
              )
              .toList(),
        ),
      ),
      // One persistent action host across tabs. Its measured height reserves
      // space for every page, including Finance's final operations target.
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(PlanActSpacing.lg),
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                heightFactor: 1,
                child: FloatingActionButton(
                  key: const ValueKey('shell-quick-add'),
                  tooltip: planActL10n(context).commonQuickAdd,
                  onPressed: _showQuickAdd,
                  child: const Icon(Icons.add),
                ),
              ),
            ),
          ),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
              final duration = PlanActMotion.duration(context);
              if (duration == Duration.zero) {
                _pageController.jumpToPage(index);
                return;
              }
              _pageController.animateToPage(
                index,
                duration: duration,
                curve: PlanActMotion.curve,
              );
            },
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.today_outlined),
                selectedIcon: Icon(Icons.today),
                label: planActL10n(context).commonToday,
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month),
                label: planActL10n(context).navigationCalendar,
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet),
                label: planActL10n(context).navigationFinance,
              ),
              NavigationDestination(
                icon: Icon(Icons.more_horiz),
                label: planActL10n(context).navigationMore,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum _AppMenuAction { addCommitment, timeline, history, reports, inbox }

class CommitmentDetailsPage extends StatefulWidget {
  const CommitmentDetailsPage({
    super.key,
    required this.commitment,
    required this.repository,
    required this.planRepository,
    required this.expectationRepository,
    required this.occurrenceExecutor,
    required this.onSaved,
    this.tagRepository,
    this.checklistRepository,
  });
  final ChecklistRepository? checklistRepository;
  final TagRepository? tagRepository;
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
  int _progressRevision = 0;
  late CommitmentProgressReader _progressReader = _createProgressReader();

  CommitmentProgressReader _createProgressReader() =>
      widget.planRepository is DriftCommitmentPlanRepository &&
          widget.expectationRepository is DriftFinancialExpectationRepository &&
          identical(
            (widget.planRepository as DriftCommitmentPlanRepository).database,
            (widget.expectationRepository
                    as DriftFinancialExpectationRepository)
                .database,
          )
      ? DriftCommitmentProgressReader(
          (widget.planRepository as DriftCommitmentPlanRepository).database,
        )
      : RepositoryCommitmentProgressReader(
          widget.planRepository,
          widget.expectationRepository,
        );

  @override
  void didUpdateWidget(CommitmentDetailsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.planRepository != widget.planRepository ||
        oldWidget.expectationRepository != widget.expectationRepository) {
      _progressReader = _createProgressReader();
    }
  }

  Future<void> _refreshDetails() async {
    try {
      await widget.onSaved();
    } finally {
      if (mounted) setState(() => _progressRevision++);
    }
  }

  late final _title = TextEditingController(text: widget.commitment.title);
  late final _description = TextEditingController(
    text: widget.commitment.description ?? '',
  );
  late CommitmentPriority _priority = widget.commitment.priority;
  late CommitmentColor? _color = widget.commitment.color;
  bool _saving = false;
  bool get _dirty =>
      _title.text != widget.commitment.title ||
      _description.text != (widget.commitment.description ?? '') ||
      _priority != widget.commitment.priority ||
      _color != widget.commitment.color;
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
              title: const Text(PersianCopy.planactAppConfirmLeaveTitle),
              content: const Text(PersianCopy.planactAppConfirmLeaveContent),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(PersianCopy.planactAppConfirmLeaveActions),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(PersianCopy.planactAppConfirmLeaveActions2),
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
        color: _color,
        updateColor: true,
      );
      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(PersianCopy.planactAppSaveContent)),
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
      appBar: AppBar(title: Text(planActL10n(context).planactAppBuildTitle4)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CommitmentProgressSection(
            reader: _progressReader,
            commitmentId: widget.commitment.id,
            revision: _progressRevision,
          ),
          Text(
            planActL10n(context).planactAppBuildChildren(
              (_statusLabel(widget.commitment.status)).toString(),
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 16),
          if (widget.checklistRepository
              case final ChecklistRepository repository)
            ListTile(
              leading: const Icon(Icons.checklist),
              title: Text(planActL10n(context).checklistTitle),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute(
                  builder: (_) => ChecklistPage(
                    repository: repository,
                    commitmentId: widget.commitment.id,
                    title: widget.commitment.title,
                  ),
                ),
              ),
            ),
          Text(
            planActL10n(context).planactAppBuildChildren2(
              (_kindLabel(widget.commitment.kind)).toString(),
            ),
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: planActL10n(context).planactAppBuildLabelText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _description,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: planActL10n(context).planactAppBuildLabelText2,
            ),
          ),
          const SizedBox(height: 16),
          CommitmentColorPicker(
            selected: _color,
            enabled: !_saving,
            onChanged: (color) => setState(() => _color = color),
          ),
          DropdownButtonFormField<CommitmentPriority>(
            initialValue: _priority,
            decoration: InputDecoration(
              labelText: planActL10n(context).planactAppBuildLabelText3,
            ),
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
          if (widget.tagRepository case final TagRepository tags)
            RecordTagEditor(
              repository: tags,
              recordId: widget.commitment.id.value,
              type: TaggableType.commitment,
              onChanged: () async {
                // Re-read durable state before any later metadata/status command.
                await widget.repository.findById(widget.commitment.id);
                await _refreshDetails();
              },
            )
          else
            TagLabels(labels: widget.commitment.tags),
          const SizedBox(height: PlanActSpacing.lg),
          if (widget.planRepository case final ScheduleUndoRepository undo)
            ScheduleUndoButton(
              repository: undo,
              commitmentId: widget.commitment.id,
              reminders:
                  widget.occurrenceExecutor is PersistedOccurrenceActionExecutor
                  ? (widget.occurrenceExecutor
                            as PersistedOccurrenceActionExecutor)
                        .reminders
                  : null,
              onChanged: _refreshDetails,
            ),
          if (widget.planRepository
              case final DriftCommitmentPlanRepository plans)
            CommitmentCorrectionCard(
              repository: DriftCommitmentCorrectionRepository(plans.database),
              commitmentId: widget.commitment.id,
              reminders:
                  widget.occurrenceExecutor is PersistedOccurrenceActionExecutor
                  ? (widget.occurrenceExecutor
                            as PersistedOccurrenceActionExecutor)
                        .reminders
                  : null,
              onSaved: _refreshDetails,
            ),
          PlannedDetailsRange(
            commitment: widget.commitment,
            repository: widget.planRepository,
            onSaved: _refreshDetails,
            synchronizeReminders:
                widget.occurrenceExecutor is PersistedOccurrenceActionExecutor
                ? () async =>
                      (widget.occurrenceExecutor
                              as PersistedOccurrenceActionExecutor)
                          .reminders
                          ?.reconcile(now: DateTime.now())
                : null,
            builder: (plan, occurrences) {
              if (occurrences.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(planActL10n(context).planactAppBuildChildren3),
                  const SizedBox(height: 8),
                  for (final occurrence in occurrences)
                    OccurrenceActionRow(
                      occurrence: occurrence,
                      executor: widget.occurrenceExecutor,
                      key: ValueKey(
                        '${occurrence.id}:${occurrence.currentScheduledAt}:${occurrence.status}:${occurrence.resultRevision}',
                      ),
                      onChanged: _refreshDetails,
                      onEdit: widget.planRepository is CommitmentPlanTransaction
                          ? (selected) async {
                              final selection =
                                  await showDialog<ScheduleEditSelection>(
                                    context: context,
                                    builder: (_) => EditScheduleDialog(
                                      occurrence: selected,
                                      recurring:
                                          plan.schedule.mode !=
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
                                await _refreshDetails();
                                if (!context.mounted) return;
                                setState(() {});
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      pending
                                          ? planActL10n(context)
                                                .planactAppBuildContent
                                          : planActL10n(context)
                                                .planactAppBuildContent2,
                                    ),
                                  ),
                                );
                              } catch (_) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      planActL10n(context)
                                          .planactAppBuildContent3,
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
                    title: Text(planActL10n(context).planactAppBuildTitle5),
                    children: [
                      Text(planActL10n(context).planactAppBuildChildren4),
                      for (final occurrence in occurrences)
                        _FinancialExpectationOccurrenceRow(
                          occurrence: occurrence,
                          onSaved: () => setState(() => _progressRevision++),
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
                : Text(planActL10n(context).commonSave),
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
    required this.onSaved,
  });

  final Occurrence occurrence;
  final FinancialExpectationUseCases useCases;
  final VoidCallback onSaved;

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
        : planActL10n(context).planactAppDateLabelMessage;
    return Card(
      child: ExpansionTile(
        initiallyExpanded: false,
        onExpansionChanged: _expand,
        title: Text(dateLabel),
        subtitle: Text(planActL10n(context).planactAppBuildSubtitle),
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
                      onSaved: widget.onSaved,
                    ),
            ),
        ],
      ),
    );
  }
}

String _statusLabel(CommitmentStatus status) => switch (status) {
  CommitmentStatus.active => PersianCopy.planactAppCommitmentStatusActive,
  CommitmentStatus.paused => PersianCopy.planactAppCommitmentStatusPaused,
  CommitmentStatus.completed => PersianCopy.planactAppCommitmentStatusCompleted,
  CommitmentStatus.cancelled => PersianCopy.occurrenceCancelled,
  CommitmentStatus.archived => PersianCopy.planactAppCommitmentStatusArchived,
};

String _kindLabel(CommitmentKind kind) => switch (kind) {
  CommitmentKind.oneOff => PersianCopy.planactAppCommitmentKindOneOff,
  CommitmentKind.recurring => PersianCopy.planactAppCommitmentKindRecurring,
};

String _priorityLabel(CommitmentPriority priority) => switch (priority) {
  CommitmentPriority.low => PersianCopy.planactAppCommitmentPriorityLow,
  CommitmentPriority.normal => PersianCopy.planactAppCommitmentPriorityNormal,
  CommitmentPriority.high => PersianCopy.planactAppCommitmentPriorityHigh,
  CommitmentPriority.urgent => PersianCopy.planactAppCommitmentPriorityUrgent,
};

class _MorePage extends StatelessWidget {
  const _MorePage({
    required this.onInbox,
    required this.onReports,
    required this.settings,
    this.holidayPackages,
    this.onHolidaysChanged,
    this.backupActions,
    this.backupMessage,
  });

  final VoidCallback onInbox;
  final VoidCallback onReports;
  final Widget settings;
  final HolidayPackageService? holidayPackages;
  final VoidCallback? onHolidaysChanged;
  final BackupActions? backupActions;
  final String? backupMessage;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Card(
        child: ListTile(
          leading: const Icon(Icons.analytics_outlined),
          title: Text(planActL10n(context).planactAppBuildTitle3),
          subtitle: Text(planActL10n(context).planactAppBuildSubtitle2),
          trailing: const Icon(Icons.chevron_left),
          onTap: onReports,
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.inbox_outlined),
          title: Text(planActL10n(context).planactAppOpenInboxTitle),
          subtitle: Text(planActL10n(context).planactAppBuildSubtitle3),
          trailing: const Icon(Icons.chevron_left),
          onTap: onInbox,
        ),
      ),
      Card(
        child: ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(planActL10n(context).planactAppBuildTitle6),
          subtitle: Text(planActL10n(context).planactAppBuildSubtitle4),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: Text(planActL10n(context).planactAppBuildTitle6),
                ),
                body: settings,
              ),
            ),
          ),
        ),
      ),
      if (holidayPackages != null)
        HolidayPackageSettingsCard(
          service: holidayPackages!,
          onInstalled: onHolidaysChanged ?? () {},
        ),
      if (backupActions != null)
        BackupSettingsCard(actions: backupActions!, message: backupMessage),
    ],
  );
}
