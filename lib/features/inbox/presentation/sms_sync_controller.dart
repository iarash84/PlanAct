import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';

/// One foreground owner shared by the root shell and Inbox. Broadcast bodies
/// never enter staging: delayed provider scans retain the durable source ID.
class SmsSyncController extends ChangeNotifier with WidgetsBindingObserver {
  SmsSyncController({
    required InboxUseCases inbox,
    required this.source,
    this.onChanged,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now,
       _store = AutomaticSmsScanAdapter(
         inbox.repository as AutomaticSmsScanStore,
       ) {
    _ingestion = SmsIngestion(inbox, source, store: _store);
  }

  final AndroidSmsSource source;
  final Future<void> Function()? onChanged;
  final DateTime Function() _now;
  final SmsScanStore _store;
  late final SmsIngestion _ingestion;
  StreamSubscription<AndroidSmsMessage>? _subscription;
  final List<Timer> _timers = [];
  Future<void>? _refreshing;
  bool _refreshAgain = false;
  bool _checkAccessRequested = false;
  bool _started = false;
  bool _disposed = false;
  bool _foreground = true;
  bool _changing = false;

  bool enabled = false;
  bool ready = false;
  bool busy = false;
  bool? access;
  String? error;
  int revision = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void start() {
    if (_started || _disposed) return;
    _started = true;
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    unawaited(refresh());
  }

  void _listen() {
    if (!_started || _subscription != null) return;
    _subscription = source.messages.listen(
      (_) {
        if (!_foreground || !enabled) return;
        // Some default SMS apps insert after the system broadcast. Retry even
        // after an empty first scan; resume/pull also recovers later insertions.
        for (final delay in [2, 8]) {
          late final Timer timer;
          timer = Timer(Duration(seconds: delay), () {
            _timers.remove(timer);
            if (_foreground && !_disposed) unawaited(refresh());
          });
          _timers.add(timer);
        }
      },
      onError: (Object _) {
        if (enabled) {
          error = PersianCopy.smsAutomaticSyncFailed;
          _notify();
        }
      },
    );
  }

  void _stopListening() {
    _subscription?.cancel();
    _subscription = null;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(refresh());
    } else {
      _ingestion.cancel();
      for (final timer in _timers) {
        timer.cancel();
      }
      _timers.clear();
    }
  }

  /// Coalescing also makes pull-to-refresh await any running synchronization.
  Future<void> refresh({bool checkAccess = false}) {
    if (_disposed) return Future.value();
    _checkAccessRequested |= checkAccess;
    if (_refreshing != null) {
      _refreshAgain = true;
      return _refreshing!;
    }
    return _refreshing = _drainRefreshes().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<void> _drainRefreshes() async {
    // Inbox may request this while mounting over the root owner. Notify only
    // after that build finishes, with _refreshing already assigned.
    await Future<void>.value();
    if (_disposed) return;
    do {
      _refreshAgain = false;
      final checkAccess = _checkAccessRequested;
      _checkAccessRequested = false;
      await _refresh(checkAccess: checkAccess);
    } while (_refreshAgain && _foreground && !_disposed);
  }

  Future<void> _refresh({required bool checkAccess}) async {
    busy = true;
    error = null;
    _notify();
    try {
      final scan = await _ingestion.load();
      if (_disposed) return;
      enabled = scan?.automatic ?? false;
      ready = true;
      if (!enabled) _stopListening();
      if (!enabled && !checkAccess) return;
      access = await source.hasAccess();
      if (access != true) {
        _stopListening();
        if (enabled) error = PersianCopy.smsAutomaticPermissionRequired;
        return;
      }
      if (!enabled || !_foreground || _disposed || _changing) return;
      _listen();
      await _ingestion.run(onProgress: (_) {});
      // A restarted/interrupted scan retains its original upper bound. Finish
      // it safely, then catch up newer messages during this same opening.
      if (scan?.complete == false && _foreground && !_disposed && !_changing) {
        final completed = await _ingestion.load();
        if (completed?.complete == true &&
            completed!.until < _now().millisecondsSinceEpoch) {
          await _ingestion.run(onProgress: (_) {});
        }
      }
      if (_disposed) return;
      revision++;
      await onChanged?.call();
    } catch (_) {
      if (!_disposed) error = PersianCopy.smsAutomaticSyncFailed;
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> setEnabled(bool value) async {
    if (_changing || _disposed || !ready) return;
    _changing = true;
    _notify();
    _ingestion.cancel();
    var savedSuccessfully = false;
    try {
      await _refreshing;
      if (_disposed) return;
      if (value) {
        access = await source.hasAccess();
        if (access != true) {
          error = PersianCopy.smsAutomaticPermissionRequired;
          return;
        }
        final now = _now();
        await _ingestion.consent(
          from: now,
          until: now,
          newOnly: true,
          automatic: true,
        );
      } else {
        final saved = await _store.readSmsScan();
        if (saved != null) {
          final scan = SmsScan.decode(saved)..automatic = false;
          await _store.writeSmsScan(saved, scan.encode());
        }
      }
      enabled = value;
      if (!enabled) _stopListening();
      error = null;
      savedSuccessfully = true;
    } catch (_) {
      if (!_disposed) error = PersianCopy.smsAutomaticSettingFailed;
    } finally {
      _changing = false;
      _notify();
    }
    if (savedSuccessfully && enabled && !_disposed) await refresh();
  }

  bool get changing => _changing;

  @override
  void dispose() {
    _disposed = true;
    _ingestion.cancel();
    _stopListening();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
