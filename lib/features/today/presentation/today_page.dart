import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_colors.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/today/application/attention_engine.dart';

import 'widgets/planact_commitment_row.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.commitments,
    required this.scheduledDates,
    this.dashboard,
    required this.onAdd,
    required this.onCommitmentTap,
    required this.onCommitmentArchive,
  });
  final List<Commitment> commitments;
  final Map<String, List<DateTime>> scheduledDates;
  final TodayDashboard? dashboard;
  final VoidCallback onAdd;
  final ValueChanged<Commitment> onCommitmentTap;
  final ValueChanged<Commitment> onCommitmentArchive;

  @override
  Widget build(BuildContext context) {
    final today = JalaliDate.now();
    final todayItems =
        dashboard?.today ??
        commitments.where((commitment) {
          final dates =
              scheduledDates[commitment.id.value] ?? const <DateTime>[];
          return dates.any((date) => JalaliDate.fromDateTime(date) == today);
        }).toList();
    final attentionItems = dashboard?.attention ?? const <AttentionItem>[];
    final nextItems = dashboard?.next ?? const <Commitment>[];
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
        if (attentionItems.isEmpty)
          const _AttentionState(hasItems: false)
        else
          ...attentionItems.map((item) => _AttentionItemCard(item: item)),
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
              onArchive: () => onCommitmentArchive(item),
            ),
          ),
        const SizedBox(height: PlanActSpacing.xl),
        const _SectionHeader(title: 'بعدی', color: PlanActColors.info),
        const SizedBox(height: PlanActSpacing.sm),
        if (nextItems.isEmpty)
          const Text('مورد مهمی برای نمایش در آینده نزدیک نیست.')
        else
          ...nextItems.map(
            (item) => PlanActCommitmentRow(
              commitment: item,
              scheduledDates: scheduledDates[item.id.value] ?? const [],
              onTap: () => onCommitmentTap(item),
              onArchive: () => onCommitmentArchive(item),
            ),
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
      borderRadius: PlanActRadius.card,
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
        width: PlanActSpacing.xs,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          borderRadius: PlanActRadius.chip,
        ),
      ),
      const SizedBox(width: PlanActSpacing.sm),
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    ],
  );
}

class _AttentionItemCard extends StatelessWidget {
  const _AttentionItemCard({required this.item});
  final AttentionItem item;

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (item.amountMinorUnits != null)
        '${MoneyInputFormatter.format(item.amountMinorUnits!)} ${item.currency ?? ''}',
      if (item.occurredAt != null) _date(item.occurredAt!),
      if (item.accountName != null) 'حساب: ${item.accountName}',
      if (item.description != null) item.description!,
      item.explanation,
    ];
    return Card(
      child: ListTile(
        leading: const Icon(Icons.priority_high),
        title: Text(item.title),
        subtitle: Text(details.join(' · ')),
        trailing: item.reason == AttentionReason.unmatchedTransaction
            ? const Chip(label: Text('بررسی'))
            : null,
      ),
    );
  }

  String _date(DateTime value) {
    final local = value.toLocal();
    return '${local.year}/${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }
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
