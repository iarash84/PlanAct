import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:flutter/material.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/features/commitments/application/commitment_correction.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';

class CommitmentCorrectionCard extends StatefulWidget {
  const CommitmentCorrectionCard({
    super.key,
    required this.repository,
    required this.commitmentId,
    required this.onSaved,
    this.reminders,
  });
  final CommitmentCorrectionRepository repository;
  final StableId commitmentId;
  final Future<void> Function() onSaved;
  final ReminderService? reminders;
  @override
  State<CommitmentCorrectionCard> createState() =>
      _CommitmentCorrectionCardState();
}

class _CommitmentCorrectionCardState extends State<CommitmentCorrectionCard> {
  final _value = TextEditingController();
  final _reason = TextEditingController();
  bool _credit = false;
  bool _busy = false;
  String? _error;
  String? _success;
  late Future<List<CommitmentCorrectionRecord>> _history;
  @override
  void initState() {
    super.initState();
    _history = widget.repository.history(widget.commitmentId);
  }

  @override
  void dispose() {
    _value.dispose();
    _reason.dispose();
    super.dispose();
  }

  Future<void> _preview() async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      final value = int.tryParse(
        PersianNumbers.normalizeDigits(_value.text.trim()),
      );
      if (value == null) {
        throw const ValidationError(
          PersianCopy.commitmentCorrectionCardPreviewMessage,
        );
      }
      final preview = await widget.repository.preview(
        CommitmentCorrectionRequest(
          commitmentId: widget.commitmentId,
          reason: _reason.text,
          scheduleCount: _credit ? null : value,
          creditDelta: _credit ? value : null,
        ),
        DateTime.now(),
      );
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(PersianCopy.commitmentCorrectionCardConfirmedTitle),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preview.hasHistory
                      ? PersianCopy.commitmentCorrectionCardConfirmedChildren
                      : PersianCopy.commitmentCorrectionCardConfirmedChildren2,
                ),
                Text(
                  PersianCopy.commitmentCorrectionCardConfirmedChildren3(
                    (_number(preview.beforeCount)).toString(),
                    (_number(preview.afterCount)).toString(),
                  ),
                ),
                Text(
                  PersianCopy.commitmentCorrectionCardConfirmedChildren4(
                    (_number(preview.futureAdded)).toString(),
                  ),
                ),
                Text(
                  PersianCopy.commitmentCorrectionCardConfirmedChildren5(
                    (_number(preview.futureCancelled)).toString(),
                  ),
                ),
                Text(
                  PersianCopy.commitmentCorrectionCardConfirmedChildren6(
                    (_number(preview.remainingBefore)).toString(),
                    (_number(preview.remainingAfter)).toString(),
                  ),
                ),
                Text(
                  _credit
                      ? PersianCopy.commitmentCorrectionCardConfirmedChildren7
                      : PersianCopy.commitmentCorrectionCardConfirmedChildren8,
                ),
                const Text(
                  PersianCopy.commitmentCorrectionCardConfirmedChildren9,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(PersianCopy.planactAppConfirmLeaveActions),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                PersianCopy.commitmentCorrectionCardConfirmedActions,
              ),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      await widget.repository.confirm(preview, DateTime.now());
      _history = widget.repository.history(widget.commitmentId);
      var pending = false;
      try {
        await widget.reminders?.reconcile(now: DateTime.now());
      } catch (_) {
        pending = true;
      }
      try {
        await widget.onSaved();
      } catch (_) {
        pending = true;
      }
      if (mounted) {
        setState(
          () => _success = pending
              ? PersianCopy.commitmentCorrectionCardPreviewMessage2
              : PersianCopy.commitmentCorrectionCardPreviewMessage3,
        );
      }
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is ValidationError
              ? error.message
              : PersianCopy.commitmentCorrectionCardPreviewMessage4,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _number(int? value) =>
      value == null ? '—' : PersianNumbers.format(value);
  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: Text(planActL10n(context).commitmentCorrectionCardBuildTitle),
      subtitle: Text(
        planActL10n(context).commitmentCorrectionCardBuildSubtitle,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<bool>(
                initialValue: _credit,
                decoration: InputDecoration(
                  labelText: planActL10n(context)
                      .commitmentCorrectionCardBuildLabelText,
                ),
                items: [
                  DropdownMenuItem(
                    value: false,
                    child: Text(
                      planActL10n(context).commitmentCorrectionCardBuildItems,
                    ),
                  ),
                  DropdownMenuItem(
                    value: true,
                    child: Text(
                      planActL10n(context).commitmentCorrectionCardBuildItems2,
                    ),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) => setState(() {
                        _credit = value!;
                        _error = null;
                        _success = null;
                      }),
              ),
              TextField(
                controller: _value,
                enabled: !_busy,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: _credit
                      ? planActL10n(context)
                            .commitmentCorrectionCardBuildLabelText2
                      : planActL10n(context)
                            .commitmentCorrectionCardBuildLabelText3,
                ),
              ),
              TextField(
                controller: _reason,
                enabled: !_busy,
                decoration: InputDecoration(
                  labelText: planActL10n(context)
                      .commitmentCorrectionCardBuildLabelText4,
                ),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (_success != null) Text(_success!),
              FutureBuilder<List<CommitmentCorrectionRecord>>(
                future: _history,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return TextButton(
                      onPressed: () => setState(() {
                        _history = widget.repository.history(
                          widget.commitmentId,
                        );
                      }),
                      child: Text(
                        planActL10n(context)
                            .commitmentCorrectionCardBuildBuilder,
                      ),
                    );
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  if (snapshot.data!.isEmpty) {
                    return Text(
                      planActL10n(context)
                          .commitmentCorrectionCardBuildBuilder2,
                    );
                  }
                  return ExpansionTile(
                    title: Text(
                      planActL10n(context).commitmentCorrectionCardBuildTitle2,
                    ),
                    children: [
                      for (final record in snapshot.data!)
                        ListTile(
                          title: Text(record.reason),
                          subtitle: Text(
                            planActL10n(
                              context,
                            ).commitmentCorrectionCardBuildSubtitle2(
                              (PersianDateFormatter.date(
                                JalaliDate.fromDateTime(record.at.toLocal()),
                              )).toString(),
                              (_number(record.beforeCount)).toString(),
                              (_number(record.afterCount)).toString(),
                              (_number(record.beforeRemaining)).toString(),
                              (_number(record.afterRemaining)).toString(),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              if (_busy) const LinearProgressIndicator(),
              FilledButton(
                onPressed: _busy ? null : _preview,
                child: Text(
                  planActL10n(context).commitmentCorrectionCardBuildChildren,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
