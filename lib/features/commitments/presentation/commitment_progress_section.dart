import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_radius.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/app/theme/planact_status_colors.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/commitments/application/commitment_progress_reader.dart';
import 'package:planact/features/commitments/domain/counted_commitment_progress.dart';

class CommitmentProgressSection extends StatefulWidget {
  const CommitmentProgressSection({
    super.key,
    required this.reader,
    required this.commitmentId,
    this.revision = 0,
  });
  final CommitmentProgressReader reader;
  final StableId commitmentId;
  final int revision;
  @override
  State<CommitmentProgressSection> createState() =>
      _CommitmentProgressSectionState();
}

class _CommitmentProgressSectionState extends State<CommitmentProgressSection> {
  CountedCommitmentProgress? _progress;
  bool _loading = true;
  bool _error = false;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(CommitmentProgressSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision ||
        oldWidget.reader != widget.reader ||
        oldWidget.commitmentId != widget.commitmentId) {
      if (oldWidget.commitmentId != widget.commitmentId) _progress = null;
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final result = await widget.reader.read(widget.commitmentId);
      if (!mounted || request != _request) return;
      setState(() {
        _progress = result;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final progress = _progress;
    if (progress == null && !_loading && !_error) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: PlanActSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_loading)
            LinearProgressIndicator(semanticsLabel: l10n.progressLoading),
          if (_error) ...[
            Semantics(liveRegion: true, child: Text(l10n.progressReadError)),
            TextButton(onPressed: _load, child: Text(l10n.commonRetry)),
          ],
          if (progress != null) ...[
            if (!progress.consistent)
              Text(l10n.progressAmbiguous)
            else ...[
              _CountChart(progress: progress.outcomes, payment: false),
              if (progress.payments case final payments?) ...[
                const SizedBox(height: PlanActSpacing.lg),
                _CountChart(progress: payments, payment: true),
              ],
            ],
            if (progress.excludedCancellations > 0)
              Text(
                l10n.progressExcludedCancellations(
                  PersianNumbers.format(progress.excludedCancellations),
                ),
              ),
            if (progress.consistent)
              Text(
                l10n.progressCountBasis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ],
      ),
    );
  }
}

class _CountChart extends StatelessWidget {
  const _CountChart({required this.progress, required this.payment});
  final CountedProgress progress;
  final bool payment;

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final colors = PlanActStatusColors.of(context);
    final parts = ProgressPart.values
        .where((p) => progress.count(p) > 0)
        .toList();
    final labels = {
      ProgressPart.completed: payment
          ? l10n.progressPaid
          : l10n.progressCompleted,
      ProgressPart.partial: l10n.progressPartPaid,
      ProgressPart.cancelled: l10n.progressCancelled,
      ProgressPart.skipped: l10n.progressSkipped,
      ProgressPart.remaining: payment
          ? l10n.progressUnpaid
          : l10n.progressRemaining,
      ProgressPart.unknown: l10n.progressUnknownPayment,
    };
    final paint = {
      ProgressPart.completed: colors.success,
      ProgressPart.partial: colors.attention,
      ProgressPart.cancelled: colors.inactive,
      ProgressPart.skipped: colors.attention,
      ProgressPart.remaining: colors.info,
      ProgressPart.unknown: colors.danger,
    };
    final icons = {
      ProgressPart.completed: Icons.check_circle_outline,
      ProgressPart.partial: Icons.timelapse,
      ProgressPart.cancelled: Icons.cancel_outlined,
      ProgressPart.skipped: Icons.skip_next_outlined,
      ProgressPart.remaining: Icons.pending_outlined,
      ProgressPart.unknown: Icons.help_outline,
    };
    return Column(
      key: ValueKey(payment ? 'payment-progress' : 'occurrence-progress'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          payment ? l10n.progressPaymentsTitle : l10n.progressOutcomesTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(l10n.progressTotal(PersianNumbers.format(progress.total))),
        if (payment)
          Text(
            l10n.progressPaymentSummary(
              PersianNumbers.format(progress.percent(ProgressPart.completed)),
              PersianNumbers.format(
                100 - progress.percent(ProgressPart.completed),
              ),
            ),
          ),
        const SizedBox(height: PlanActSpacing.sm),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: PlanActRadius.input,
            child: SizedBox(
              height: PlanActSpacing.lg,
              child: Row(
                children: [
                  for (final part in parts)
                    Expanded(
                      flex: progress.count(part),
                      child: ColoredBox(
                        key: ValueKey(
                          '${payment ? 'payment' : 'outcome'}-segment-${part.name}',
                        ),
                        color: paint[part]!,
                        child: const SizedBox.expand(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: PlanActSpacing.sm),
        for (final part in parts)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icons[part], color: paint[part]),
              const SizedBox(width: PlanActSpacing.sm),
              Expanded(
                child: Text(
                  l10n.progressLegend(
                    labels[part]!,
                    PersianNumbers.format(progress.count(part)),
                    PersianNumbers.format(progress.percent(part)),
                  ),
                ),
              ),
            ],
          ),
        if (payment)
          Text(
            l10n.progressPaymentBasis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
