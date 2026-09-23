import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_colors.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/features/commitments/domain/commitment.dart';

class PlanActCommitmentRow extends StatelessWidget {
  const PlanActCommitmentRow({
    super.key,
    required this.commitment,
    this.scheduledDates = const [],
    this.onTap,
  });

  final Commitment commitment;
  final List<DateTime> scheduledDates;
  final VoidCallback? onTap;

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
        PlanActColors.attention,
        'متوقف‌شده',
      ),
      CommitmentStatus.completed => (
        Icons.check_circle_outline,
        PlanActColors.success,
        'تکمیل‌شده',
      ),
      CommitmentStatus.cancelled => (
        Icons.cancel_outlined,
        Theme.of(context).colorScheme.error,
        'لغوشده',
      ),
      CommitmentStatus.archived => (
        Icons.archive_outlined,
        Theme.of(context).colorScheme.onSurfaceVariant,
        'بایگانی‌شده',
      ),
    };
    return Semantics(
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
                    const SizedBox(height: PlanActSpacing.xs),
                    Text(
                      scheduledDates.isEmpty
                          ? '$statusLabel • بدون زمان‌بندی'
                          : '$statusLabel • ${scheduledDates.length} جلسه',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_left, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
