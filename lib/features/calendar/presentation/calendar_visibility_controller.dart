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
  bool _disposed = false;

  Future<void> load() async {
    try {
      final loaded =
          await settings?.readCalendarVisibility() ??
          const CalendarVisibility();
      if (_disposed) return;
      value = loaded;
      ready = true;
      loadFailed = false;
    } catch (_) {
      if (_disposed) return;
      loadFailed = true;
      ready = false;
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> select(CalendarVisibility next) async {
    if (_disposed) throw StateError('Calendar settings unavailable');
    if (!ready || saving || settings == null) {
      throw StateError('Calendar settings unavailable');
    }
    saving = true;
    notifyListeners();
    try {
      await settings!.writeCalendarVisibility(next);
      if (!_disposed) value = next;
    } finally {
      if (!_disposed) {
        saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
