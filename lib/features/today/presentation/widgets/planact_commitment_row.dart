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
    final isPaused = commitment.status == CommitmentStatus.paused;
    return Semantics(
      button: onTap != null,
      label: commitment.title,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: PlanActSpacing.md),
          child: Row(
            children: [
              Icon(
                isPaused
                    ? Icons.pause_circle_outline
                    : Icons.radio_button_unchecked,
                color: isPaused
                    ? PlanActColors.attention
                    : Theme.of(context).colorScheme.primary,
              ),
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
                          ? 'فعال • بدون زمان‌بندی'
                          : 'فعال • ${scheduledDates.length} جلسه',
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
