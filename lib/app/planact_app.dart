import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
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
  late final CreateCommitment _createCommitment = CreateCommitment(_repository);
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
    final commitment = await _createCommitment(title: draft.title);
    if (draft.scheduledDates.isNotEmpty) {
      _scheduledDates[commitment.id.value] = draft.scheduledDates;
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayPage(
        commitments: _commitments,
        scheduledDates: _scheduledDates,
        onAdd: _showCapture,
      ),
      CalendarPage(commitments: _commitments, scheduledDates: _scheduledDates),
      const _MorePage(),
    ];
    final titles = ['امروز', 'تقویم', 'بیشتر'];
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
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
