import 'package:flutter/material.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/application/commitment_use_cases.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

void main() {
  runApp(const PlanActApp());
}

class PlanActApp extends StatelessWidget {
  const PlanActApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'پلن‌اکت',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff176b87),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff7fafb),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      builder: (context, child) =>
          Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final CommitmentRepository _repository = InMemoryCommitmentRepository();
  late final CreateCommitment _createCommitment = CreateCommitment(_repository);
  int _selectedIndex = 0;
  List<Commitment> _commitments = const [];

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
    final title = await showDialog<String>(
      context: context,
      builder: (context) => const _CaptureDialog(),
    );
    if (title == null || title.trim().isEmpty) return;
    await _createCommitment(title: title);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayPage(commitments: _commitments, onAdd: _showCapture),
      CalendarPage(commitments: _commitments),
      const Center(child: Text('تنظیمات در نسخهٔ بعدی اضافه می‌شود')),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? 'امروز'
              : _selectedIndex == 1
              ? 'تقویم'
              : 'بیشتر',
        ),
        centerTitle: false,
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

class TodayPage extends StatelessWidget {
  const TodayPage({required this.commitments, required this.onAdd, super.key});

  final List<Commitment> commitments;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text('شنبه، ۳۰ شهریور', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'چه چیزی نیاز به توجه دارد؟',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'نیازمند توجه',
          icon: Icons.priority_high_rounded,
          color: Colors.orange,
        ),
        const SizedBox(height: 8),
        _AttentionCard(),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'امروز',
          icon: Icons.today,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        if (commitments.isEmpty)
          _EmptyCard(onAdd: onAdd)
        else
          ...commitments.map((item) => _CommitmentCard(commitment: item)),
        const SizedBox(height: 24),
        const _SectionHeader(
          title: 'پیش‌رو',
          icon: Icons.upcoming,
          color: Colors.teal,
        ),
        const SizedBox(height: 8),
        const _InfoCard(
          text: 'زمان‌بندی‌های آینده پس از ایجاد اولین برنامه اینجا نمایش داده می‌شوند.',
        ),
      ],
    );
  }
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({required this.commitments, super.key});
  final List<Commitment> commitments;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'شهریور ۱۴۰۵',
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('ش'),
                  Text('ی'),
                  Text('د'),
                  Text('س'),
                  Text('چ'),
                  Text('پ'),
                  Text('ج'),
                ],
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 7,
                children: List.generate(
                  31,
                  (index) => Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: index == 29 ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),
      Text(
        '${_persianNumber(commitments.length)} تعهد ثبت‌شده',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ],
  );
}

String _persianNumber(int value) {
  const latin = '0123456789';
  const persian = '۰۱۲۳۴۵۶۷۸۹';
  return value
      .toString()
      .split('')
      .map((digit) => persian[latin.indexOf(digit)])
      .join();
}

class _CaptureDialog extends StatefulWidget {
  const _CaptureDialog();

  @override
  State<_CaptureDialog> createState() => _CaptureDialogState();
}

class _CaptureDialogState extends State<_CaptureDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('تعهد جدید'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'چه کاری باید انجام شود؟',
            hintText: 'مثلاً کلاس زبان',
          ),
          onSubmitted: (_) => Navigator.of(context).pop(_controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('ثبت'),
          ),
        ],
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });
  final String title;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 22),
      const SizedBox(width: 8),
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _AttentionCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.orange.withValues(alpha: .1),
    child: const ListTile(
      leading: Icon(Icons.notifications_active_outlined, color: Colors.orange),
      title: Text('هنوز تعهدی برای امروز ندارید'),
      subtitle: Text('با ثبت یک تعهد، برنامهٔ روزانه‌تان را شروع کنید.'),
    ),
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 42),
          const SizedBox(height: 8),
          const Text('امروز برنامه‌ای ندارید'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('ثبت اولین تعهد'),
          ),
        ],
      ),
    ),
  );
}

class _CommitmentCard extends StatelessWidget {
  const _CommitmentCard({required this.commitment});
  final Commitment commitment;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: const CircleAvatar(child: Icon(Icons.check)),
      title: Text(commitment.title),
      subtitle: const Text('فعال • بدون زمان‌بندی'),
      trailing: const Icon(Icons.chevron_left),
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(padding: const EdgeInsets.all(16), child: Text(text)),
  );
}
