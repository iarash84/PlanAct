import 'package:flutter/foundation.dart';
import 'package:planact/app/app_settings.dart';
import 'package:planact/features/calendar/domain/calendar_visibility.dart';

final class CalendarVisibilityController extends ChangeNotifier {
  CalendarVisibilityController(this.settings) : ready = settings == null;
  final AppSettings? settings;
  CalendarVisibility value = const CalendarVisibility();
  bool ready;
  bool saving = false;
  bool loadFailed = false;

  Future<void> load() async {
    try {
      final loaded =
          await settings?.readCalendarVisibility() ??
          const CalendarVisibility();
      value = loaded;
      ready = true;
      loadFailed = false;
    } catch (_) {
      loadFailed = true;
      ready = false;
    }
    notifyListeners();
  }

  Future<void> select(CalendarVisibility next) async {
    if (!ready || saving || settings == null) {
      throw StateError('Calendar settings unavailable');
    }
    saving = true;
    notifyListeners();
    try {
      await settings!.writeCalendarVisibility(next);
      value = next;
    } finally {
      saving = false;
      notifyListeners();
    }
  }
}
