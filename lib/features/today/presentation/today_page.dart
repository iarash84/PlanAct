import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/app/money_unit_scope.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:flutter/material.dart';
import 'package:planact/features/commitments/presentation/commitment_identity_marker.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/presentation/persian_money_text.dart';
import 'package:planact/core/presentation/planact_state_message.dart';
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
    this.smsSyncError,
    this.onRetry,
    this.onRefresh,
    required this.onAdd,
    required this.onCommitmentTap,
    required this.onCommitmentArchive,
    required this.onReview,
    this.onOpenRelationshipQueue,
  });

  final List<Commitment> commitments;
  final Map<String, List<DateTime>> scheduledDates;
  final TodayDashboard? dashboard;
  final TodayActionCenter? actionCenter;
  final String? error;
  final String? smsSyncError;
  final VoidCallback? onRetry;
  final Future<void> Function()? onRefresh;
  final VoidCallback onAdd;
  final ValueChanged<Commitment> onCommitmentTap;
  final ValueChanged<Commitment> onCommitmentArchive;
  final ValueChanged<TodayActionItem> onReview;
  final VoidCallback? onOpenRelationshipQueue;

  @override
  Widget build(BuildContext context) {
    final today = JalaliDate.now();
    final center = actionCenter;
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
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
          planActL10n(context).todayPageContentChildren,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: PlanActSpacing.lg),
        if (smsSyncError != null)
          PlanActStateMessage(
            message: smsSyncError!,
            isError: true,
            action: TextButton(
              onPressed: onRefresh,
              child: Text(planActL10n(context).commonRetry),
            ),
          ),
        if (onOpenRelationshipQueue != null)
          OutlinedButton.icon(
            onPressed: onOpenRelationshipQueue,
            icon: const Icon(Icons.playlist_add_check),
            label: Text(planActL10n(context).relationshipQueuePageBuildTitle),
          ),
        if (error != null)
          PlanActStateMessage(
            message: error!,
            isError: true,
            action: TextButton(
              onPressed: onRetry,
              child: Text(planActL10n(context).commonRetry),
            ),
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
            _SectionHeader(
              title: planActL10n(context).commonToday,
              color: Theme.of(context).colorScheme.primary,
            ),
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
            _SectionHeader(
              title: planActL10n(context).todayPageContentTitle,
              color: PlanActStatusColors.of(context).info,
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
    return onRefresh == null
        ? content
        : RefreshIndicator(onRefresh: onRefresh!, child: content);
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
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
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
          ? planActL10n(context)
                .todayPageBuildMessage((items.length).toString())
          : planActL10n(context).todayPageBuildMessage2(
              (items.length).toString(),
              (urgentCount).toString(),
            ),
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
              subtitle: Text(
                planActL10n(context).todayPageBuildSubtitle(
                  (entries[index].value.length).toString(),
                ),
              ),
              children: [
                for (final item in entries[index].value)
                  _ActionItemCard(
                    item: item,
                    grouped: true,
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
    this.grouped = false,
  });

  final TodayActionItem item;
  final ValueChanged<Commitment> onOpen;
  final VoidCallback onReview;
  final bool grouped;

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
                unit: MoneyUnitScope.of(context),
              ),
            if (details.accountName != null)
              planActL10n(context).transactionRelationshipPageBuildChildren3(
                (details.accountName).toString(),
              ),
            if (details.description != null) details.description!,
          ];
    final row = ListTile(
      leading: item.commitment != null
          ? CommitmentIdentityMarker(
              key: ValueKey('today-identity-${item.id}'),
              commitment: item.commitment!,
              icon: item.type == TodayActionItemType.occurrence
                  ? Icons.event_available
                  : Icons.priority_high,
            )
          : Icon(
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
              ? planActL10n(context)
                    .attentionEngineAttentionActionDetermineOccurrenceStatus
              : item.actionLabel,
        ),
      ),
    );
    return grouped ? row : Card(child: row);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => PlanActStateMessage(
    message: planActL10n(context).todayPageBuildMessage3,
    action: OutlinedButton.icon(
      onPressed: onAdd,
      icon: const Icon(Icons.add),
      label: Text(planActL10n(context).todayPageBuildLabel),
    ),
  );
}
