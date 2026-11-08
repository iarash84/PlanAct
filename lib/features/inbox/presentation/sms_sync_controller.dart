import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:planact/core/application/command_gate.dart';
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
  }) : _inbox = inbox,
       _now = now ?? DateTime.now,
       _store = AutomaticSmsScanAdapter(
         inbox.repository as AutomaticSmsScanStore,
       ) {
    _ingestion = SmsIngestion(inbox, source, store: _store);
    _manualIngestion = SmsIngestion(
      inbox,
      source,
      store: ManualSmsScanAdapter(inbox.repository as ManualSmsScanStore),
    );
    _historyIngestion = SmsIngestion(inbox, source);
  }

  final InboxUseCases _inbox;
  final AndroidSmsSource source;
  final Future<void> Function()? onChanged;
  final DateTime Function() _now;
  final SmsScanStore _store;
  late final SmsIngestion _ingestion;
  late final SmsIngestion _manualIngestion;
  late final SmsIngestion _historyIngestion;
  Future<void>? _manualChecking;
  StreamSubscription<AndroidSmsMessage>? _subscription;
  final List<Timer> _timers = [];
  Future<void>? _refreshing;
  bool _refreshAgain = false;
  bool _checkAccessRequested = false;
  bool _started = false;
  bool _disposed = false;
  bool _foreground = true;
  bool _changing = false;
  int _cancellationRevision = 0;

  bool _canRun(int revision) =>
      !_disposed && _foreground && revision == _cancellationRevision;

  bool manualReady = false;
  bool get setupRequired => ready && !manualReady;
  int? lastNewSuggestions;
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
      _cancellationRevision++;
      _ingestion.cancel();
      _manualIngestion.cancel();
      _historyIngestion.cancel();
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
    // Explicit commands own feedback until they finish. Root refresh must not
    // clear their error/count or announce idle while a manual read is running.
    if (_changing || _manualChecking != null) return;
    final cancellation = _cancellationRevision;
    busy = true;
    error = null;
    _notify();
    try {
      final scan = await _ingestion.load();
      manualReady = await _manualIngestion.loadManual() != null;
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
      if (!enabled ||
          !_foreground ||
          _disposed ||
          _changing ||
          _manualChecking != null) {
        return;
      }
      _listen();
      await _ingestion.run(
        onProgress: (_) {},
        canRun: () => _canRun(cancellation),
      );
      // A restarted/interrupted scan retains its original upper bound. Finish
      // it safely, then catch up newer messages during this same opening.
      if (scan?.complete == false && _foreground && !_disposed && !_changing) {
        final completed = await _ingestion.load();
        if (completed?.complete == true &&
            completed!.until < _now().millisecondsSinceEpoch) {
          await _ingestion.run(
            onProgress: (_) {},
            canRun: () => _canRun(cancellation),
          );
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
      await _manualChecking;
      if (_disposed) return;
      // Materialize valid legacy new-only consent before replacing an automatic
      // boundary. Otherwise re-enabling auto could silently narrow manual scope.
      if (await _manualIngestion.loadManual() != null) {
        await _manualIngestion.activateManual(_now());
        manualReady = true;
      }
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

  /// Explicit manual command; unlike refresh this ignores the automatic toggle
  /// and never resumes or replaces the historical scan.
  Future<void> checkNewMessages() {
    if (_disposed || _changing) return Future.value();
    final cancellation = _cancellationRevision;
    return _manualChecking ??=
        CommandGate.runFor(_inbox.repository, () async {
              await Future<void>.value();
              try {
                await _refreshing;
                if (!_canRun(cancellation)) return;
                busy = true;
                error = null;
                lastNewSuggestions = null;
                _notify();
                if (!await _requireAccess() || !_canRun(cancellation)) return;
                if (await _manualIngestion.loadManual() == null) {
                  manualReady = false;
                  error = PersianCopy.smsIngestionRunMessage;
                  return;
                }
                if (!_canRun(cancellation)) return;
                await _manualIngestion.activateManual(_now());
                manualReady = true;
                await _runManual(cancellation: cancellation);
              } catch (_) {
                if (!_disposed) error = PersianCopy.smsAutomaticSyncFailed;
              } finally {
                busy = false;
                _notify();
              }
            })
            .catchError((Object _) {
              if (!_disposed) error = PersianCopy.smsAutomaticSyncFailed;
              _notify();
            })
            .whenComplete(() => _manualChecking = null);
  }

  Future<bool> _requireAccess() async {
    access = await source.hasAccess();
    if (access != true) error = PersianCopy.smsAutomaticPermissionRequired;
    return access == true && !_disposed && _foreground;
  }

  Future<void> _runManual({
    required int cancellation,
    int initialCount = 0,
  }) async {
    var added = initialCount;
    final initial = await _manualIngestion.load();
    if (!_canRun(cancellation)) return;
    await _manualIngestion.run(
      onProgress: (_) {},
      onNewSuggestion: () => added++,
      now: _now,
      canRun: () => _canRun(cancellation),
    );
    final completed = await _manualIngestion.load();
    if (initial?.complete == false &&
        completed?.complete == true &&
        completed!.until < _now().millisecondsSinceEpoch &&
        _canRun(cancellation)) {
      await _manualIngestion.run(
        onProgress: (_) {},
        onNewSuggestion: () => added++,
        now: _now,
        canRun: () => _canRun(cancellation),
      );
    }
    if (!_canRun(cancellation)) return;
    // An interrupted scan is retryable, not a successful zero-result check.
    if ((await _manualIngestion.load())?.complete != true) return;
    lastNewSuggestions = added;
    revision++;
    await onChanged?.call();
  }

  /// Saves all selected consent before provider access; scanning failure retains
  /// consent and historical progress for explicit retry, never automatic resume.
  Future<void> setup({required int days, required bool automatic}) =>
      _changeManualConsent(days: days, automatic: automatic);

  /// Explicit opt-in for range-only legacy installations. Existing manual or
  /// valid legacy new-only windows are preserved rather than narrowed to now.
  Future<void> activateManualFromNow() => _changeManualConsent();

  Future<void> _changeManualConsent({int? days, bool automatic = false}) async {
    final now = _now();
    final cancellation = _cancellationRevision;
    if (_disposed || _changing) return;
    _changing = true;
    _ingestion.cancel();
    try {
      await CommandGate.runFor(_inbox.repository, () async {
        await _refreshing;
        await _manualChecking;
        if (!_canRun(cancellation)) return;
        busy = true;
        error = null;
        lastNewSuggestions = null;
        _notify();
        if (!await _requireAccess() || !_canRun(cancellation)) return;
        if (days == null) {
          await _manualIngestion.activateManual(now);
        } else {
          await _historyIngestion.setup(
            days: days,
            automatic: automatic,
            now: now,
          );
        }
        manualReady = true;
        enabled = (await _ingestion.load())?.automatic ?? false;
        ready = true;
        if (!enabled) _stopListening();
        var added = 0;
        if (days != null && _canRun(cancellation)) {
          await _historyIngestion.run(
            onProgress: (_) {},
            onNewSuggestion: () => added++,
            canRun: () => _canRun(cancellation),
          );
        }
        if (_canRun(cancellation)) {
          await _runManual(cancellation: cancellation, initialCount: added);
        }
      });
    } catch (_) {
      if (!_disposed) error = PersianCopy.smsAutomaticSyncFailed;
    } finally {
      _changing = false;
      busy = false;
      _notify();
    }
    // Do not let a follow-up automatic refresh hide a failed explicit command.
    if (error == null && enabled && _foreground && !_disposed) await refresh();
  }

  bool get changing => _changing;

  @override
  void dispose() {
    _disposed = true;
    _cancellationRevision++;
    _ingestion.cancel();
    _manualIngestion.cancel();
    _historyIngestion.cancel();
    _stopListening();
    if (_started) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
