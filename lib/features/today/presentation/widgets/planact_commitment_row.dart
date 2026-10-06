import 'package:planact/features/classification/presentation/tag_controls.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

class PlanActCommitmentRow extends StatelessWidget {
  const PlanActCommitmentRow({
    super.key,
    required this.commitment,
    this.scheduledDates = const [],
    this.onTap,
    this.onArchive,
    this.supportingDetails,
  });

  final Commitment commitment;
  final List<DateTime> scheduledDates;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final String? supportingDetails;

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor, statusLabel) = switch (commitment.status) {
      CommitmentStatus.active => (
        Icons.radio_button_unchecked,
        Theme.of(context).colorScheme.primary,
        'فعال',
      ),
      CommitmentStatus.paused => (
        Icons.pause_circle_outline,
        PlanActStatusColors.of(context).attention,
        'متوقف‌شده',
      ),
      CommitmentStatus.completed => (
        Icons.check_circle_outline,
        PlanActStatusColors.of(context).success,
        'تکمیل‌شده',
      ),
      CommitmentStatus.cancelled => (
        Icons.cancel_outlined,
        PlanActStatusColors.of(context).inactive,
        'لغوشده',
      ),
      CommitmentStatus.archived => (
        Icons.archive_outlined,
        PlanActStatusColors.of(context).inactive,
        'بایگانی‌شده',
      ),
    };
    final content = Semantics(
      button: onTap != null,
      label: commitment.title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PlanActSpacing.md),
          child: Row(
            children: [
              Icon(icon, color: iconColor),
              const SizedBox(width: PlanActSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      commitment.title,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (commitment.tags.isNotEmpty)
                      TagLabels(labels: commitment.tags),
                    const SizedBox(height: PlanActSpacing.xs),
                    Text(
                      supportingDetails ??
                          (scheduledDates.isEmpty
                              ? '$statusLabel • بدون زمان‌بندی'
                              : '$statusLabel • ${scheduledDates.length} جلسه'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
    if (onArchive == null) return content;
    return Dismissible(
      key: ValueKey(commitment.id.value),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        onArchive!();
        return false;
      },
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: PlanActSpacing.lg),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.archive_outlined,
          semanticLabel: 'بایگانی',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      child: content,
    );
  }
}
