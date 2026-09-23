import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_colors.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

import 'widgets/planact_commitment_row.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.commitments,
    required this.scheduledDates,
    required this.onAdd,
    required this.onCommitmentTap,
  });
  final List<Commitment> commitments;
  final Map<String, List<DateTime>> scheduledDates;
  final VoidCallback onAdd;
  final ValueChanged<Commitment> onCommitmentTap;

  @override
  Widget build(BuildContext context) {
    final today = JalaliDate.now();
    final todayItems = commitments.where((commitment) {
      final dates = scheduledDates[commitment.id.value] ?? const <DateTime>[];
      return dates.any((date) => JalaliDate.fromDateTime(date) == today);
    }).toList();
    final completedCount = todayItems
        .where((item) => item.status == CommitmentStatus.completed)
        .length;
    final attentionCount = todayItems
        .where(
          (item) =>
              item.status != CommitmentStatus.completed &&
              item.status != CommitmentStatus.archived,
        )
        .length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PlanActSpacing.lg,
        PlanActSpacing.md,
        PlanActSpacing.lg,
        100,
      ),
      children: [
        Text(
          PersianDateFormatter.date(today),
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: PlanActSpacing.xs),
        Text(
          'چه چیزی نیاز به توجه دارد؟',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: PlanActSpacing.lg),
        _Summary(
          plannedCount: todayItems.length,
          completedCount: completedCount,
          attentionCount: attentionCount,
        ),
        const SizedBox(height: PlanActSpacing.xl),
        const _SectionHeader(
          title: 'نیازمند توجه',
          color: PlanActColors.attention,
        ),
        const SizedBox(height: PlanActSpacing.sm),
        _AttentionState(hasItems: attentionCount > 0),
        const SizedBox(height: PlanActSpacing.xl),
        const _SectionHeader(title: 'امروز', color: PlanActColors.primary),
        const SizedBox(height: PlanActSpacing.sm),
        if (todayItems.isEmpty)
          _EmptyState(onAdd: onAdd)
        else
          ...todayItems.map(
            (item) => PlanActCommitmentRow(
              commitment: item,
              scheduledDates: scheduledDates[item.id.value] ?? const [],
              onTap: () => onCommitmentTap(item),
            ),
          ),
        const SizedBox(height: PlanActSpacing.xl),
        const _SectionHeader(title: 'بعدی', color: PlanActColors.info),
        const SizedBox(height: PlanActSpacing.sm),
        const Text(
          'برنامه‌های آینده پس از ثبت زمان‌بندی اینجا نمایش داده می‌شوند.',
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.plannedCount,
    required this.completedCount,
    required this.attentionCount,
  });

  final int plannedCount;
  final int completedCount;
  final int attentionCount;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(PlanActSpacing.lg),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _Metric(value: PersianNumbers.format(plannedCount), label: 'برنامه'),
        _Metric(
          value: PersianNumbers.format(completedCount),
          label: 'انجام شده',
        ),
        _Metric(
          value: PersianNumbers.format(attentionCount),
          label: 'نیازمند توجه',
        ),
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.headlineSmall
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
      Text(label),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});
  final String title;
  final Color color;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 4,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _AttentionState extends StatelessWidget {
  const _AttentionState({required this.hasItems});
  final bool hasItems;
  @override
  Widget build(BuildContext context) => Text(
    hasItems
        ? 'موارد نیازمند توجه اینجا نمایش داده می‌شوند.'
        : 'همه‌چیز مرتب است؛ موردی نیاز به توجه ندارد.',
    style: Theme.of(context).textTheme.bodyLarge
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('امروز چیزی برنامه‌ریزی نشده.'),
      const SizedBox(height: PlanActSpacing.sm),
      OutlinedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('ثبت اولین تعهد'),
      ),
    ],
  );
}
