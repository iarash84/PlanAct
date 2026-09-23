import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
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

  Future<void> _changeStatus(Commitment commitment) async {
    final nextStatus = await showModalBottomSheet<CommitmentStatus>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('تغییر وضعیت تعهد')),
            if (commitment.status == CommitmentStatus.active)
              ListTile(
                leading: const Icon(Icons.pause_circle_outline),
                title: const Text('توقف موقت'),
                onTap: () => Navigator.pop(context, CommitmentStatus.paused),
              ),
            if (commitment.status == CommitmentStatus.paused)
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('ادامه'),
                onTap: () => Navigator.pop(context, CommitmentStatus.active),
              ),
            if (commitment.status == CommitmentStatus.active)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('تکمیل‌شده'),
                onTap: () => Navigator.pop(context, CommitmentStatus.completed),
              ),
            if (commitment.status == CommitmentStatus.active ||
                commitment.status == CommitmentStatus.paused)
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('لغو تعهد'),
                onTap: () => Navigator.pop(context, CommitmentStatus.cancelled),
              ),
            if (commitment.status != CommitmentStatus.archived)
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('بایگانی'),
                onTap: () => Navigator.pop(context, CommitmentStatus.archived),
              ),
          ],
        ),
      ),
    );
    if (nextStatus == null) return;
    final updated = switch (nextStatus) {
      CommitmentStatus.active => commitment.resume(),
      CommitmentStatus.paused => commitment.pause(),
      CommitmentStatus.completed => commitment.complete(),
      CommitmentStatus.cancelled => commitment.cancel(),
      CommitmentStatus.archived => commitment.archive(),
    };
    await _repository.save(updated);
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('وضعیت «${commitment.title}» تغییر کرد.'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'بازگردانی',
            onPressed: () async {
              await _repository.save(commitment);
              await _refresh();
            },
          ),
        ),
      );
  }

  Future<void> _deleteCommitment(Commitment commitment) async {
    if (commitment.status == CommitmentStatus.archived) return;
    final previous = commitment;
    await _repository.save(commitment.archive());
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('تعهد بایگانی شد.'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'بازگردانی',
            onPressed: () async {
              await _repository.save(previous);
              await _refresh();
            },
          ),
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
        onCommitmentTap: _changeStatus,
        onCommitmentDelete: _deleteCommitment,
      ),
      CalendarPage(commitments: _commitments, scheduledDates: _scheduledDates),
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
          IconButton(
            tooltip: 'افزودن تعهد',
            onPressed: _showCapture,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: SafeArea(child: pages[_selectedIndex]),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showCapture,
              icon: const Icon(Icons.add),
              label: const Text('تعهد جدید'),
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

class _MorePage extends StatelessWidget {
  const _MorePage();

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('ابزارهای بیشتر در نسخهٔ بعدی اضافه می‌شوند.'));
}
