import 'package:planact/features/commitments/presentation/commitment_card_layout.dart';
import 'package:planact/features/commitments/presentation/commitment_checklist_disclosure.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:planact/features/commitments/application/checklist_repository.dart';
import 'package:planact/app/money_unit_scope.dart';
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
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment_checklist.dart';
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
    this.onOccurrenceTap,
    this.checklists = const {},
    this.checklistRepository,
    this.onChecklistChanged,
    this.onChecklistUpdated,
    this.onEditCommitment,
    this.onOpenRelationshipQueue,
    this.bottomContentPadding = 0,
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
  final ValueChanged<TodayActionItem>? onOccurrenceTap;
  final Map<StableId, CommitmentChecklist> checklists;
  final ChecklistRepository? checklistRepository;
  final Future<void> Function()? onChecklistUpdated;
  final ValueChanged<Commitment>? onEditCommitment;
  final Future<void> Function(
    StableId commitmentId,
    StableId itemId,
    bool checked,
  )?
  onChecklistChanged;
  final VoidCallback? onOpenRelationshipQueue;
  final double bottomContentPadding;

  @override
  Widget build(BuildContext context) {
    final today = JalaliDate.now();
    final center = actionCenter;
    final content = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        PlanActSpacing.lg,
        PlanActSpacing.md,
        PlanActSpacing.lg,
        PlanActSpacing.lg + bottomContentPadding,
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
              onOccurrenceTap: onOccurrenceTap,
              onReview: onReview,
              checklists: checklists,
              checklistRepository: checklistRepository,
              onEditCommitment: onEditCommitment,
              onChecklistChanged: onChecklistChanged,
              onChecklistUpdated: onChecklistUpdated,
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
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: PlanActSpacing.md),
                child: _ActionItemCard(
                  item: item,
                  onOpen: onCommitmentTap,
                  onOccurrenceTap: onOccurrenceTap == null
                      ? null
                      : () => onOccurrenceTap!(item),
                  onReview: () => onReview(item),
                  checklist: item.commitment == null
                      ? null
                      : checklists[item.commitment!.id],
                  checklistRepository: checklistRepository,
                  onEditCommitment: onEditCommitment,
                  onChecklistChanged: onChecklistChanged,
                  onChecklistUpdated: onChecklistUpdated,
                ),
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
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: PlanActSpacing.md),
                child: _ActionItemCard(
                  item: item,
                  onOpen: onCommitmentTap,
                  onOccurrenceTap: onOccurrenceTap == null
                      ? null
                      : () => onOccurrenceTap!(item),
                  onReview: () => onReview(item),
                  checklist: item.commitment == null
                      ? null
                      : checklists[item.commitment!.id],
                  checklistRepository: checklistRepository,
                  onEditCommitment: onEditCommitment,
                  onChecklistChanged: onChecklistChanged,
                  onChecklistUpdated: onChecklistUpdated,
                ),
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
    this.onOccurrenceTap,
    required this.onReview,
    required this.checklists,
    this.checklistRepository,
    required this.onChecklistChanged,
    this.onChecklistUpdated,
    this.onEditCommitment,
  });

  final List<TodayActionItem> items;
  final ValueChanged<Commitment> onOpen;
  final ValueChanged<TodayActionItem>? onOccurrenceTap;
  final ValueChanged<TodayActionItem> onReview;
  final Map<StableId, CommitmentChecklist> checklists;
  final ChecklistRepository? checklistRepository;
  final Future<void> Function()? onChecklistUpdated;
  final ValueChanged<Commitment>? onEditCommitment;
  final Future<void> Function(StableId, StableId, bool)? onChecklistChanged;

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
                    onOccurrenceTap: onOccurrenceTap == null
                        ? null
                        : () => onOccurrenceTap!(item),
                    onReview: () => onReview(item),
                    checklist: item.commitment == null
                        ? null
                        : checklists[item.commitment!.id],
                    checklistRepository: checklistRepository,
                    onEditCommitment: onEditCommitment,
                    onChecklistChanged: onChecklistChanged,
                    onChecklistUpdated: onChecklistUpdated,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ActionItemCard extends StatefulWidget {
  const _ActionItemCard({
    required this.item,
    required this.onOpen,
    this.onOccurrenceTap,
    required this.onReview,
    this.grouped = false,
    this.checklist,
    this.checklistRepository,
    this.onEditCommitment,
    this.onChecklistChanged,
    this.onChecklistUpdated,
  });

  final TodayActionItem item;
  final ValueChanged<Commitment> onOpen;
  final VoidCallback? onOccurrenceTap;
  final VoidCallback onReview;
  final bool grouped;
  final CommitmentChecklist? checklist;
  final ChecklistRepository? checklistRepository;
  final ValueChanged<Commitment>? onEditCommitment;
  final Future<void> Function(StableId, StableId, bool)? onChecklistChanged;
  final Future<void> Function()? onChecklistUpdated;

  @override
  State<_ActionItemCard> createState() => _ActionItemCardState();
}

class _ActionItemCardState extends State<_ActionItemCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
    final commitment = item.commitment;
    final row = CommitmentCardLayout(
      grouped: widget.grouped,
      expanded: _expanded,
      details: _details(context, commitment),
      leading: commitment != null
          ? CommitmentIdentityMarker(
              key: ValueKey('today-identity-${item.id}'),
              commitment: commitment,
              icon: item.type == TodayActionItemType.occurrence
                  ? Icons.event_available
                  : Icons.priority_high,
            )
          : Icon(
              item.type == TodayActionItemType.occurrence
                  ? Icons.event_available
                  : Icons.priority_high,
            ),
      title: item.title,
      preview: commitment == null || widget.checklistRepository == null
          ? null
          : CommitmentChecklistDisclosure(
              repository: widget.checklistRepository!,
              commitmentId: commitment.id,
              onChanged: widget.onChecklistUpdated,
            ),
      tags: commitment == null || commitment.tags.isEmpty
          ? null
          : TagLabels(labels: commitment.tags),
      metadata: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            [
              item.subtitle,
              if (financial.isNotEmpty) financial.first,
            ].join(' · '),
          ),
        ],
      ),
      actions: [
        if (commitment != null)
          IconButton(
            key: ValueKey('today-edit-${commitment.id.value}'),
            tooltip: planActL10n(context).commitmentEdit,
            onPressed: widget.onEditCommitment == null
                ? null
                : () => widget.onEditCommitment!(commitment),
            icon: const Icon(Icons.edit_outlined),
          ),
        IconButton(
          key: ValueKey('today-details-${item.id}'),
          tooltip: _expanded
              ? planActL10n(context).detailsHide
              : planActL10n(context).detailsShow,
          onPressed: () => setState(() => _expanded = !_expanded),
          icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
        ),
        TextButton(
          onPressed:
              item.type == TodayActionItemType.occurrence &&
                  widget.onOccurrenceTap != null
              ? widget.onOccurrenceTap
              : commitment == null
              ? widget.onReview
              : () => widget.onOpen(commitment),
          child: Text(
            item.type == TodayActionItemType.occurrence
                ? planActL10n(context)
                      .attentionEngineAttentionActionDetermineOccurrenceStatus
                : item.actionLabel,
          ),
        ),
      ],
    );
    return row;
  }

  Widget _details(BuildContext context, Commitment? commitment) {
    final description = commitment?.description?.trim();
    if (description == null || description.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        PlanActSpacing.lg,
        0,
        PlanActSpacing.lg,
        PlanActSpacing.md,
      ),
      child: Text(description),
    );
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
