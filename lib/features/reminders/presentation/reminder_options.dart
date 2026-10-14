import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/l10n/generated/app_localizations.dart';

/// Ready-made choices only; no reminder is enabled until explicitly selected.
const reminderDayPresetMinutes = [1440, 4320, 14400];

String reminderOffsetLabel(AppLocalizations l10n, int minutes) {
  if (minutes == 0) {
    return l10n.occurrenceRemindersReminderRuleLabelMessage2;
  }
  if (minutes >= 1440 && minutes % 1440 == 0) {
    return l10n.quickCaptureSheetReminderLabelMessage(
      PersianNumbers.format(minutes ~/ 1440),
    );
  }
  if (minutes >= 60 && minutes % 60 == 0) {
    return l10n.quickCaptureSheetReminderLabelMessage2(
      PersianNumbers.format(minutes ~/ 60),
    );
  }
  return l10n.quickCaptureSheetReminderLabelMessage3(
    PersianNumbers.format(minutes),
  );
}
