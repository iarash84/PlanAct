import 'package:planact/core/errors/app_error.dart';
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/domain/commitment_color.dart';
import 'package:planact/features/scheduling/domain/schedule_definition.dart';

/// A civil-day annotation, with no schedule, status or delivery semantics.
final class CalendarNote {
  CalendarNote({
    required this.id,
    required String title,
    required String description,
    required this.date,
    required this.color,
    required this.revision,
  }) : title = title.trim(),
       description = description.trim() {
    if (this.title.isEmpty) {
      throw const ValidationError('Note title is required');
    }
    if (revision < 1) throw const ValidationError('Invalid note revision');
    if (date.year < 1 || date.year > 9999) {
      throw const ValidationError('Unsupported note date');
    }
  }

  final StableId id;
  final String title;
  final String description;
  final LocalDate date;
  final CommitmentColor color;
  final int revision;
}

final class StaleCalendarNote implements Exception {
  const StaleCalendarNote();
}
