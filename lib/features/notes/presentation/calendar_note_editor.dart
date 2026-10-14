import 'package:flutter/material.dart';
import 'package:planact/app/theme/commitment_identity_palette.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/core/localization/planact_localizations.dart';
import 'package:planact/core/localization/persian_date_formatter.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/core/presentation/planact_form_sheet.dart';
import 'package:planact/core/time/jalali_date.dart';
import 'package:planact/features/calendar/presentation/planned_occurrence_widgets.dart';
import 'package:planact/features/commitments/domain/commitment_color.dart';
import 'package:planact/features/commitments/presentation/commitment_color_picker.dart';
import 'package:planact/features/notes/application/calendar_note_repository.dart';
import 'package:planact/features/notes/domain/calendar_note.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

class CalendarNoteEditor extends StatefulWidget {
  const CalendarNoteEditor({super.key, required this.repository, this.note});
  final CalendarNoteRepository repository;
  final CalendarNote? note;

  static Future<CalendarNote?> show(
    BuildContext context,
    CalendarNoteRepository repository, {
    CalendarNote? note,
  }) => showModalBottomSheet<CalendarNote>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: false,
    enableDrag: false,
    showDragHandle: true,
    builder: (_) => CalendarNoteEditor(repository: repository, note: note),
  );

  @override
  State<CalendarNoteEditor> createState() => _CalendarNoteEditorState();
}

class _CalendarNoteEditorState extends State<CalendarNoteEditor> {
  late final _title = TextEditingController(text: widget.note?.title);
  late final _description = TextEditingController(
    text: widget.note?.description,
  );
  late final _id = widget.note?.id ?? StableId.generate();
  late LocalDate? _date = widget.note?.date;
  late CommitmentColor? _color = widget.note?.color;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = planActL10n(context);
    if (_title.text.trim().isEmpty || _date == null) {
      setState(
        () => _error = _title.text.trim().isEmpty
            ? l10n.calendarNoteTitleRequired
            : l10n.calendarNoteDateRequired,
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await SaveCalendarNote(widget.repository)(
        id: _id,
        title: _title.text,
        description: _description.text,
        date: _date!,
        color: CommitmentIdentityPalette.resolve(_color, _id),
        expectedRevision: widget.note?.revision ?? 0,
      );
      if (!mounted) return;
      // Re-enable PopScope before returning the committed result.
      setState(() => _saving = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, result);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is StaleCalendarNote
            ? l10n.calendarNoteStale
            : l10n.calendarNoteSaveFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = planActL10n(context);
    return PopScope(
      canPop: !_saving,
      child: PlanActFormSheet(
        title: widget.note == null
            ? l10n.calendarNoteCreateTitle
            : l10n.calendarNoteEditTitle,
        primaryKey: const ValueKey('calendar-note-save'),
        onPrimary: _save,
        isLoading: _saving,
        error: _error,
        child: AbsorbPointer(
          absorbing: _saving,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('calendar-note-title'),
                controller: _title,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: l10n.calendarNoteTitleField,
                ),
              ),
              TextField(
                key: const ValueKey('calendar-note-description'),
                controller: _description,
                enabled: !_saving,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n.calendarNoteDescriptionField,
                ),
              ),
              TextButton.icon(
                key: const ValueKey('calendar-note-date'),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  _date == null
                      ? l10n.calendarNoteChooseDate
                      : '${PersianDateFormatter.date(_jalali(_date!))} ${PersianNumbers.format(_jalali(_date!).year)}',
                ),
                onPressed: _saving
                    ? null
                    : () async {
                        final picked = await pickPlannedDate(
                          context,
                          _date == null ? JalaliDate.now() : _jalali(_date!),
                        );
                        if (picked != null && mounted) {
                          setState(
                            () => _date = LocalDate.fromDateTime(
                              picked.toDateTime(),
                            ),
                          );
                        }
                      },
              ),
              CommitmentColorPicker(
                label: l10n.calendarNoteColorLabel,
                helperText: l10n.calendarNoteColorHint,
                selected: _color,
                enabled: !_saving,
                onChanged: (color) => setState(() => _color = color),
              ),
              Text(l10n.calendarNoteNoDelivery),
            ],
          ),
        ),
      ),
    );
  }

  JalaliDate _jalali(LocalDate date) =>
      JalaliDate.fromDateTime(DateTime(date.year, date.month, date.day));
}
