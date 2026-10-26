import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/features/commitments/application/checklist_repository.dart';
import 'package:planact/features/commitments/presentation/commitment_checklist_section.dart';

class CommitmentChecklistDisclosure extends StatefulWidget {
  const CommitmentChecklistDisclosure({
    super.key,
    required this.repository,
    required this.commitmentId,
    this.onChanged,
    this.showScope = false,
  });

  final ChecklistRepository repository;
  final StableId commitmentId;
  final Future<void> Function()? onChanged;
  final bool showScope;

  @override
  State<CommitmentChecklistDisclosure> createState() =>
      _CommitmentChecklistDisclosureState();
}

class _CommitmentChecklistDisclosureState
    extends State<CommitmentChecklistDisclosure> {
  ChecklistSnapshot? _snapshot;
  bool _expanded = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snapshot = await widget.repository.load(widget.commitmentId);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    final active = _snapshot?.list.items
        .where((item) => !item.removed)
        .toList();
    final checked = active?.where((item) => item.checked).length ?? 0;
    final total = active?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: l10n.checklistTitle,
          child: InkWell(
            key: ValueKey('checklist-disclosure-${widget.commitmentId.value}'),
            borderRadius: BorderRadius.circular(12),
            onTap: _loading
                ? null
                : () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: PlanActSpacing.sm,
                horizontal: PlanActSpacing.xs,
              ),
              child: Row(
                children: [
                  const Icon(Icons.checklist_outlined),
                  const SizedBox(width: PlanActSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.checklistTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  if (_loading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else ...[
                    Flexible(
                      child: Text(
                        l10n.checklistProgress(
                          PersianNumbers.format(checked),
                          PersianNumbers.format(total),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: PlanActSpacing.sm),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: PlanActMotion.duration(context),
          curve: PlanActMotion.curve,
          alignment: AlignmentDirectional.topStart,
          child: !_expanded
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: PlanActSpacing.sm),
                  child: CommitmentChecklistSection(
                    repository: widget.repository,
                    commitmentId: widget.commitmentId,
                    showScope: widget.showScope,
                    onChanged: () async {
                      await widget.onChanged?.call();
                      await _load();
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
