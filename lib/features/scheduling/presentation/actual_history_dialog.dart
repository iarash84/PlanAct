import 'package:planact/core/localization/persian_numbers.dart';
import 'package:flutter/material.dart';
import 'package:planact/app/theme/planact_spacing.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/actuals/application/actual_use_cases.dart';
import 'package:planact/features/actuals/domain/actual.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';
import 'package:planact/features/scheduling/presentation/actual_text_dialog.dart';

class ActualHistoryDialog extends StatefulWidget {
  const ActualHistoryDialog({
    super.key,
    required this.repository,
    required this.occurrence,
    required this.readOnly,
    required this.onChanged,
  });
  final ActualRepository repository;
  final Occurrence occurrence;
  final bool readOnly;
  final Future<void> Function() onChanged;

  @override
  State<ActualHistoryDialog> createState() => _ActualHistoryDialogState();
}

class _ActualHistoryDialogState extends State<ActualHistoryDialog> {
  late Future<List<Actual>> _items = Future.sync(widget.repository.list);

  void _reload() {
    final future = Future.sync(widget.repository.list);
    setState(() {
      _items = future;
    });
  }

  String _date(DateTime time) =>
      PersianDateFormatter.date(JalaliDate.fromDateTime(time.toLocal()));

  Future<void> _edit(
    Actual actual, {
    Evidence? evidence,
    bool discard = false,
  }) async {
    final writer = widget.repository;
    if (writer is! ActualEvidenceWriter) return;
    Evidence? expected = evidence;
    final l10n = planActL10n(context);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ActualTextDialog(
        title: discard
            ? l10n.actualTextDiscard
            : evidence == null
            ? l10n.actualTextAdd
            : l10n.actualTextEdit,
        initialValue: evidence?.value ?? '',
        discard: discard,
        onSave: (value) => (writer as ActualEvidenceWriter).mutateTextEvidence(
          actualId: actual.id,
          expected: expected,
          value: value,
        ),
        onReload: () async {
          final latest = (await widget.repository.list()).firstWhere(
            (item) => item.id == actual.id,
          );
          if (evidence == null) return null;
          expected = latest.evidence.firstWhere(
            (item) => item.id == evidence.id,
          );
          return expected!.value;
        },
      ),
    );
    if (saved != true || !mounted) return;
    _reload();
    // A committed evidence change is not a failed save if route refresh fails.
    try {
      await widget.onChanged();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.actualTextRefreshError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return AlertDialog(
      title: Text(l10n.occurrenceActionRowShowHistoryTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: FutureBuilder<List<Actual>>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.occurrenceActionRowShowHistoryBuilder),
                  TextButton(
                    onPressed: _reload,
                    child: Text(l10n.actualTextHistoryRetry),
                  ),
                ],
              );
            }
            if (!snapshot.hasData) {
              return const Center(
                heightFactor: 2,
                child: CircularProgressIndicator(),
              );
            }
            final items = snapshot.data!
                .where((item) => item.occurrenceId == widget.occurrence.id)
                .toList();
            if (items.isEmpty) {
              return Text(l10n.occurrenceActionRowShowHistoryBuilder2);
            }
            return ListView(
              shrinkWrap: true,
              children: [
                for (final actual in items)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      bottom: PlanActSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(switch (actual.outcome) {
                          ActualOutcome.completed =>
                            l10n.planactAppShowCommitmentDetailsTitle,
                          ActualOutcome.attended =>
                            l10n.occurrenceActionRowActualOutcomeAttended,
                          ActualOutcome.cancelled =>
                            l10n.occurrenceActionRowSelectedChildren2,
                          ActualOutcome.missed =>
                            l10n.occurrenceActionRowActualOutcomeMissed,
                          ActualOutcome.noShow => l10n.occurrenceSkipped,
                          ActualOutcome.partial =>
                            l10n.occurrenceActionRowSelectedChildren3,
                          ActualOutcome.reopened =>
                            l10n.occurrenceActionRowActualOutcomeReopened,
                        }, style: Theme.of(context).textTheme.titleSmall),
                        Text(_date(actual.recordedAt)),
                        if (actual.note != null) Text(actual.note!),
                        for (final evidence in actual.evidence) ...[
                          const Divider(),
                          Text(
                            evidence.isDiscarded
                                ? l10n.actualTextDiscarded
                                : l10n.actualTextLabel,
                          ),
                          Text(evidence.value),
                          if (!widget.readOnly &&
                              evidence.type == EvidenceType.note &&
                              !evidence.isDiscarded &&
                              widget.repository is ActualEvidenceWriter)
                            Wrap(
                              spacing: PlanActSpacing.sm,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _edit(actual, evidence: evidence),
                                  child: Text(l10n.actualTextEdit),
                                ),
                                TextButton(
                                  onPressed: () => _edit(
                                    actual,
                                    evidence: evidence,
                                    discard: true,
                                  ),
                                  child: Text(l10n.actualTextDiscard),
                                ),
                              ],
                            ),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text(l10n.actualTextRevisions),
                            children: [
                              ListTile(
                                title: Text(l10n.actualTextOriginal),
                                subtitle: Text(evidence.originalValue),
                              ),
                              for (final revision in evidence.history)
                                ListTile(
                                  title: Text(
                                    '${PersianNumbers.format(revision.revision)} · ${_date(revision.recordedAt)}',
                                  ),
                                  subtitle: Text(
                                    '${revision.isDiscarded ? l10n.actualTextDiscarded : l10n.actualTextLabel}\n${revision.value}',
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (!widget.readOnly &&
                            widget.repository is ActualEvidenceWriter)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton.icon(
                              key: ValueKey(
                                'actual-evidence-add-${actual.id.value}',
                              ),
                              onPressed: () => _edit(actual),
                              icon: const Icon(Icons.note_add_outlined),
                              label: Text(l10n.actualTextAdd),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonClose),
        ),
      ],
    );
  }
}
