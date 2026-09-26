import 'package:flutter/material.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/application/commitment_use_cases.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/today/presentation/today_page.dart';
import 'package:planact/features/calendar/presentation/calendar_page.dart';
import 'package:planact/features/capture/presentation/quick_capture_sheet.dart';

class PlanActApp extends StatelessWidget {
  const PlanActApp({super.key, this.repository});

  final CommitmentRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پلن‌اکت',
      debugShowCheckedModeBanner: false,
      theme: PlanActTheme.light(),
      darkTheme: PlanActTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child ?? const SizedBox.shrink(),
      ),
      home: HomeShell(repository: repository),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.repository});

  final CommitmentRepository? repository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final CommitmentRepository _repository =
      widget.repository ?? InMemoryCommitmentRepository();
  late final InMemoryCommitmentPlanRepository _planRepository =
      InMemoryCommitmentPlanRepository();
  late final CreateCommitmentPlan _createCommitmentPlan = CreateCommitmentPlan(
    commitments: _repository,
    plans: _planRepository,
  );
  int _selectedIndex = 0;
  List<Commitment> _commitments = const [];
  final Map<String, List<DateTime>> _scheduledDates = {};

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final items = await _repository.list();
    if (mounted) setState(() => _commitments = items);
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
    final startAt = draft.scheduledDates.isEmpty
        ? DateTime.now()
        : draft.scheduledDates.first;
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
      reminderOffsets: draft.reminderOffsets,
    );
    final commitment = plan.commitment;
    if (plan.occurrences.isNotEmpty) {
      _scheduledDates[commitment.id.value] = [
        for (final occurrence in plan.occurrences)
          if (occurrence.currentScheduledAt is DateTime)
            occurrence.currentScheduledAt as DateTime,
      ];
    }
    await _refresh();
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

  Future<void> _deleteCommitment(Commitment commitment) async {
    if (commitment.status == CommitmentStatus.archived) return;
    await ArchiveCommitment(_repository)(commitment.id);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('تعهد بایگانی شد.'),
          duration: const Duration(seconds: 4),
          action: null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayPage(
        commitments: _commitments,
        scheduledDates: _scheduledDates,
        onAdd: _showCapture,
        onCommitmentTap: _showCommitmentDetails,
        onCommitmentDelete: _deleteCommitment,
      ),
      CalendarPage(
        commitments: _commitments,
        scheduledDates: _scheduledDates,
        onCommitmentTap: _showCommitmentDetails,
      ),
      const _MorePage(),
    ];
    final titles = ['امروز', 'تقویم', 'بیشتر'];
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
      body: SafeArea(child: pages[_selectedIndex]),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              tooltip: 'افزودن تعهد',
              onPressed: _showCapture,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
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
    required this.onSaved,
  });
  final Commitment commitment;
  final CommitmentRepository repository;
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
  const _MorePage();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('ابزارهای بیشتر در نسخهٔ بعدی اضافه می‌شوند.'));
}
