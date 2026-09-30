import 'package:flutter/material.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/app/theme/planact_theme.dart';
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

class PlanActApp extends StatefulWidget {
  const PlanActApp({super.key, this.repository, this.planRepository});

  final CommitmentRepository? repository;
  final CommitmentPlanRepository? planRepository;

  @override
  State<PlanActApp> createState() => _PlanActAppState();
}

class _PlanActAppState extends State<PlanActApp> {
  ThemeMode _themeMode = ThemeMode.system;
  AppSettings? _settings;

  @override
  void initState() {
    super.initState();
    final repository = widget.repository;
    if (repository is DriftCommitmentRepository) {
      _settings = AppSettings(repository.database);
      _settings!.readThemeMode().then((mode) {
        if (mounted) setState(() => _themeMode = mode);
      });
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
        child: child ?? const SizedBox.shrink(),
      ),
      home: HomeShell(
        repository: widget.repository,
        planRepository: widget.planRepository,
        settings: _settings,
        themeMode: _themeMode,
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
    this.themeMode = ThemeMode.system,
    this.onThemeModeChanged = _ignoreThemeChange,
  });

  static void _ignoreThemeChange(ThemeMode _) {}

  final CommitmentRepository? repository;
  final CommitmentPlanRepository? planRepository;
  final AppSettings? settings;
  final ThemeMode themeMode;
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
  late final CreateCommitmentPlan _createCommitmentPlan = CreateCommitmentPlan(
    commitments: _repository,
    plans: _planRepository,
    entitlements: _entitlementRepository,
    financialExpectations: _expectationUseCases,
  );
  int _selectedIndex = 0;
  late final FinanceRepository _financeRepository =
      _repository is DriftCommitmentRepository
      ? DriftFinanceRepository(_repository.database)
      : InMemoryFinanceRepository();
  List<Commitment> _commitments = const [];
  final Map<String, List<DateTime>> _scheduledDates = {};
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
            if (occurrence.currentScheduledAt is DateTime)
              occurrence.currentScheduledAt as DateTime,
        ];
      }
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

  Future<void> _showCapture() async {
    final draft = await showModalBottomSheet<CommitmentDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const QuickCaptureSheet(),
    );
    if (draft == null || draft.title.trim().isEmpty) return;
    if (draft.scheduledDates.isEmpty) return;
    try {
      final startAt = draft.scheduledDates.first;
      await _createCommitmentPlan(
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
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('ثبت تعهد انجام نشد؛ دوباره تلاش کنید.'),
          action: SnackBarAction(label: 'بستن', onPressed: _hideSnackBar),
        ),
      );
    }
  }

  void _hideSnackBar() {
    if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
          final page = item.type == TodayActionItemType.financialReview ? 2 : 3;
          setState(() => _selectedIndex = page);
          _pageController.animateToPage(
            page,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        },
      ),
      CalendarPage(
        commitments: _commitments,
        scheduledDates: _scheduledDates,
        onCommitmentTap: _showCommitmentDetails,
      ),
      FinancePage(
        repository: _financeRepository,
        expectationRepository: _expectationRepository,
      ),
      _MorePage(
        inbox: InboxPage(
          inbox: _inboxUseCases,
          finance: _financeRepository,
          smsSource: AndroidSmsSource(),
        ),
        settings: SettingsPage(
          settings: widget.settings,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
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
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              tooltip: 'افزودن تعهد',
              onPressed: _showCapture,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
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
                      onChanged: widget.onSaved,
                    ),
                  const SizedBox(height: 16),
                  const Text('انتظار مالی نوبت‌ها'),
                  const SizedBox(height: 8),
                  const Text(
                    'برای هر نوبتِ این تعهد، مبلغ جداگانه و اختیاری ثبت کنید.',
                  ),
                  const SizedBox(height: 8),
                  for (final occurrence in occurrences)
                    _FinancialExpectationOccurrenceRow(
                      occurrence: occurrence,
                      useCases: FinancialExpectationUseCases(
                        widget.expectationRepository,
                      ),
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

class _MorePage extends StatefulWidget {
  const _MorePage({required this.inbox, required this.settings});

  final Widget inbox;
  final Widget settings;

  @override
  State<_MorePage> createState() => _MorePageState();
}

enum _MoreChild { inbox, settings }

class _MorePageState extends State<_MorePage> {
  _MoreChild? _child;

  void _open(_MoreChild child) {
    setState(() => _child = child);
  }

  @override
  Widget build(BuildContext context) {
    final child = _child;
    if (child != null) {
      final (title, page) = switch (child) {
        _MoreChild.inbox => ('صندوق ورودی', widget.inbox),
        _MoreChild.settings => ('تنظیمات', widget.settings),
      };
      return Column(
        children: [
          ListTile(
            leading: const Icon(Icons.arrow_back),
            title: Text(title),
            onTap: () => setState(() => _child = null),
          ),
          const Divider(height: 1),
          Expanded(child: page),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.inbox_outlined),
            title: const Text('صندوق ورودی'),
            subtitle: const Text('بررسی پیام‌های واردشده پیش از ثبت مالی'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _open(_MoreChild.inbox),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('تنظیمات'),
            subtitle: const Text('تنظیمات عمومی برنامه'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => _open(_MoreChild.settings),
          ),
        ),
      ],
    );
  }
}
