import 'package:flutter/widgets.dart';

import '../app_settings.dart';
import 'theme_preset.dart';

/// Persistence completes before the effective palette changes.
class ThemePresetController extends ChangeNotifier {
  ThemePresetController(this.settings);
  final AppSettings? settings;
  ThemePreset preset = ThemePreset.original;
  bool ready = false;
  bool busy = false;
  bool loadFailed = false;
  bool saveFailed = false;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (busy) return;
    busy = true;
    loadFailed = false;
    _notify();
    try {
      preset = await settings?.readThemePreset() ?? ThemePreset.original;
      ready = true;
    } catch (_) {
      loadFailed = true;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> select(ThemePreset next) async {
    if (!ready || busy || next == preset) return;
    busy = true;
    saveFailed = false;
    _notify();
    try {
      await settings?.writeThemePreset(next);
      preset = next;
    } catch (_) {
      saveFailed = true;
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ThemePresetScope extends InheritedNotifier<ThemePresetController> {
  const ThemePresetScope({
    super.key,
    required ThemePresetController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemePresetController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ThemePresetScope>()?.notifier;
}
