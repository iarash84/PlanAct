import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';

class CommitmentDraft {
  const CommitmentDraft({required this.title, this.scheduledDates = const []});
  final String title;
  final List<DateTime> scheduledDates;
}

class QuickCaptureSheet extends StatefulWidget {
  const QuickCaptureSheet({super.key});

  @override
  State<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends State<QuickCaptureSheet> {
  final _controller = TextEditingController();
  bool _showOptions = false;
  TimeOfDay? _time;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    final now = DateTime.now();
    Navigator.of(context).pop(
      CommitmentDraft(
        title: title,
        scheduledDates: [
          DateTime(
            now.year,
            now.month,
            now.day,
            _time?.hour ?? 9,
            _time?.minute ?? 0,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        PlanActSpacing.lg,
        0,
        PlanActSpacing.lg,
        bottom + PlanActSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تعهد جدید',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: PlanActSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: const InputDecoration(
                labelText: 'چه کاری باید انجام شود؟',
                hintText: 'مثلاً کلاس زبان',
              ),
            ),
            const SizedBox(height: PlanActSpacing.md),
            TextButton.icon(
              onPressed: () => setState(() => _showOptions = !_showOptions),
              icon: Icon(_showOptions ? Icons.expand_less : Icons.tune),
              label: Text(_showOptions ? 'بستن گزینه‌ها' : 'افزودن جزئیات'),
            ),
            if (_showOptions) ...[
              Wrap(
                spacing: PlanActSpacing.sm,
                runSpacing: PlanActSpacing.sm,
                children: [
                  const Chip(
                    avatar: Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text('امروز'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.schedule_outlined, size: 18),
                    label: Text(
                      _time == null ? 'زمان' : _time!.format(context),
                    ),
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time ?? TimeOfDay.now(),
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                  ),
                  const Chip(
                    avatar: Icon(Icons.repeat, size: 18),
                    label: Text('تکرار'),
                  ),
                  const Chip(
                    avatar: Icon(Icons.notifications_none, size: 18),
                    label: Text('یادآوری'),
                  ),
                ],
              ),
              const SizedBox(height: PlanActSpacing.md),
            ],
            Wrap(
              spacing: PlanActSpacing.sm,
              children: [
                for (final day in const [('د', 1), ('پ', 4)])
                  FilterChip(
                    label: Text(day.$1),
                    selected: false,
                    onSelected: (_) {},
                  ),
              ],
            ),
            const SizedBox(height: PlanActSpacing.md),
            FilledButton(onPressed: _save, child: const Text('ثبت')),
          ],
        ),
      ),
    );
  }
}
