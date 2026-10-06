import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_colors.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/commitments/domain/commitment.dart';
import 'package:planact/features/today/application/attention_engine.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.commitments,
    required this.scheduledDates,
    this.dashboard,
    this.actionCenter,
    this.error,
    this.onRetry,
    required this.onAdd,
    required this.onCommitmentTap,
    required this.onCommitmentArchive,
    required this.onReview,
  });

  final List<Commitment> commitments;
  final Map<String, List<DateTime>> scheduledDates;
  final TodayDashboard? dashboard;
  final TodayActionCenter? actionCenter;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback onAdd;
  final ValueChanged<Commitment> onCommitmentTap;
  final ValueChanged<Commitment> onCommitmentArchive;
  final ValueChanged<TodayActionItem> onReview;

  @override
  Widget build(BuildContext context) {
    final today = JalaliDate.now();
    final center = actionCenter;
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
        if (error != null)
          Column(
            children: [
              Text(error!),
              TextButton(onPressed: onRetry, child: const Text('تلاش دوباره')),
            ],
          )
        else if (center == null)
          const Center(child: CircularProgressIndicator())
        else if (center.isEmpty)
          _EmptyState(onAdd: onAdd)
        else ...[
          if (center.attention.isNotEmpty) ...[
            _AttentionSummary(items: center.attention),
            const SizedBox(height: PlanActSpacing.sm),
            _AttentionGroups(
              items: center.attention,
              onOpen: onCommitmentTap,
              onReview: onReview,
            ),
            const SizedBox(height: PlanActSpacing.xl),
          ],
          if (center.today.isNotEmpty) ...[
            const _SectionHeader(title: 'امروز', color: PlanActColors.primary),
            const SizedBox(height: PlanActSpacing.sm),
            ...center.today.map(
              (item) => _ActionItemCard(
                item: item,
                onOpen: onCommitmentTap,
                onReview: () => onReview(item),
              ),
            ),
            const SizedBox(height: PlanActSpacing.xl),
          ],
          if (center.upcoming.isNotEmpty) ...[
            const _SectionHeader(
              title: 'آینده نزدیک',
              color: PlanActColors.info,
            ),
            const SizedBox(height: PlanActSpacing.sm),
            ...center.upcoming.map(
              (item) => _ActionItemCard(
                item: item,
                onOpen: onCommitmentTap,
                onReview: () => onReview(item),
              ),
            ),
          ],
        ],
      ],
    );
  }
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

class _AttentionSummary extends StatelessWidget {
  const _AttentionSummary({required this.items});

  final List<TodayActionItem> items;

  @override
  Widget build(BuildContext context) {
    final urgentCount = items.where((item) => item.urgency >= 90).length;
    return Text(
      urgentCount == 0
          ? '${items.length} مورد برای رسیدگی وجود دارد.'
          : '${items.length} مورد برای رسیدگی؛ $urgentCount مورد فوری است.',
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _AttentionGroups extends StatelessWidget {
  const _AttentionGroups({
    required this.items,
    required this.onOpen,
    required this.onReview,
  });

  final List<TodayActionItem> items;
  final ValueChanged<Commitment> onOpen;
  final ValueChanged<TodayActionItem> onReview;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<TodayActionItem>>{};
    for (final item in items) {
      groups.putIfAbsent(item.actionLabel, () => []).add(item);
    }
    final entries = groups.entries.toList();
    return Column(
      children: [
        for (var index = 0; index < entries.length; index++)
          Card(
            margin: const EdgeInsets.only(bottom: PlanActSpacing.xs),
            child: ExpansionTile(
              initiallyExpanded: index == 0,
              title: Text(entries[index].key),
              subtitle: Text('${entries[index].value.length} مورد'),
              children: [
                for (final item in entries[index].value)
                  _ActionItemCard(
                    item: item,
                    onOpen: onOpen,
                    onReview: () => onReview(item),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionItemCard extends StatelessWidget {
  const _ActionItemCard({
    required this.item,
    required this.onOpen,
    required this.onReview,
  });

  final TodayActionItem item;
  final ValueChanged<Commitment> onOpen;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final details = item.attentionItem;
    final financial = details == null
        ? const <String>[]
        : <String>[
            if (details.amountMinorUnits != null)
              PersianMoneyText.amount(
                details.amountMinorUnits!,
                details.currency ?? '',
              ),
            if (details.accountName != null) 'حساب: ${details.accountName}',
            if (details.description != null) details.description!,
          ];
    return Card(
      child: ListTile(
        leading: Icon(
          item.type == TodayActionItemType.occurrence
              ? Icons.event_available
              : Icons.priority_high,
        ),
        title: Text(item.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [
                item.subtitle,
                if (financial.isNotEmpty) financial.first,
              ].join(' · '),
            ),
            if (item.commitment case final Commitment commitment)
              TagLabels(labels: commitment.tags),
          ],
        ),
        trailing: TextButton(
          onPressed: item.commitment == null
              ? onReview
              : () => onOpen(item.commitment!),
          child: Text(
            item.type == TodayActionItemType.occurrence
                ? 'تعیین وضعیت'
                : item.actionLabel,
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('همه‌چیز مرتب است؛ موردی نیاز به توجه ندارد.'),
      const SizedBox(height: PlanActSpacing.sm),
      OutlinedButton.icon(
        onPressed: onAdd,
        icon: const Icon(Icons.add),
        label: const Text('ثبت تعهد جدید'),
      ),
    ],
  );
}
