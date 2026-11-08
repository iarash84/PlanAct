import 'package:planact/core/localization/persian_copy.g.dart';

import 'dart:async';
import 'dart:convert';

import 'package:planact/core/application/command_gate.dart';
import 'package:planact/core/errors/app_error.dart';
import 'package:planact/features/inbox/application/android_sms_source.dart';
import 'package:planact/features/inbox/application/inbox_use_cases.dart';

abstract interface class SmsScanStore {
  Future<String?> readSmsScan();
  Future<void> writeSmsScan(String? expected, String value);
}

/// All three consent records are compared and committed together at setup start.
abstract interface class ManualSmsScanStore {
  Future<String?> readManualSmsScan();
  Future<void> writeManualSmsScan(String? expected, String value);
  Future<void> writeSmsSetup({
    required String? expectedHistory,
    required String? expectedManual,
    required String? expectedAutomatic,
    required String history,
    required String manual,
    required String? automatic,
  });
}

class ManualSmsScanAdapter implements SmsScanStore {
  ManualSmsScanAdapter(this.store);
  final ManualSmsScanStore store;
  @override
  Future<String?> readSmsScan() => store.readManualSmsScan();
  @override
  Future<void> writeSmsScan(String? expected, String value) =>
      store.writeManualSmsScan(expected, value);
}

abstract interface class AutomaticSmsScanStore {
  Future<String?> readAutomaticSmsScan();
  Future<void> writeAutomaticSmsScan(String? expected, String value);
}

class AutomaticSmsScanAdapter implements SmsScanStore {
  AutomaticSmsScanAdapter(this.store);
  final AutomaticSmsScanStore store;
  @override
  Future<String?> readSmsScan() => store.readAutomaticSmsScan();
  @override
  Future<void> writeSmsScan(String? expected, String value) =>
      store.writeAutomaticSmsScan(expected, value);
}

class SmsScan {
  SmsScan({
    required this.from,
    required this.until,
    required this.newOnly,
    this.timestamp = -1,
    this.id = -1,
    this.inspected = 0,
    this.unsupported = 0,
    this.complete = false,
    this.automatic = false,
  });
  final int from;
  int until;
  final bool newOnly;
  int timestamp;
  int id;
  int inspected;
  int unsupported;
  bool complete;
  bool automatic;

  String encode() => jsonEncode({
    'version': 1,
    'from': from,
    'until': until,
    'newOnly': newOnly,
    'timestamp': timestamp,
    'id': id,
    'inspected': inspected,
    'unsupported': unsupported,
    'complete': complete,
    'automatic': automatic,
  });
  factory SmsScan.decode(String text) {
    final m = jsonDecode(text) as Map<String, dynamic>;
    if (m['version'] != 1) {
      throw const ValidationError(PersianCopy.smsIngestionMessage);
    }
    return SmsScan(
      from: m['from'] as int,
      until: m['until'] as int,
      newOnly: m['newOnly'] as bool,
      timestamp: m['timestamp'] as int,
      id: m['id'] as int,
      inspected: m['inspected'] as int,
      unsupported: m['unsupported'] as int,
      complete: m['complete'] as bool,
      automatic: m['automatic'] as bool? ?? false,
    );
  }
}

/// Bounded ingestion, invoked by explicit imports or separately consented sync.
class SmsIngestion {
  SmsIngestion(this.inbox, this.source, {SmsScanStore? store})
    : _store = store ?? inbox.repository as SmsScanStore;
  final InboxUseCases inbox;
  final AndroidSmsSource source;
  static final _tails = Expando<Future<void>>();
  bool _cancelled = false;
  final SmsScanStore _store;

  // The native read is outside a database transaction. Serialize whole scans
  // within this application owner; durable writes still compare fresh state.
  Future<void> _exclusive(Future<void> Function() action) async {
    final previous = _tails[inbox.repository] ?? Future<void>.value();
    final done = Completer<void>();
    _tails[inbox.repository] = done.future;
    try {
      await CommandGate.runFor(inbox.repository, () async {
        await previous;
        await action();
      });
    } finally {
      done.complete();
    }
  }

  Future<SmsScan?> load() async {
    final text = await _store.readSmsScan();
    return text == null ? null : SmsScan.decode(text);
  }

  void cancel() => _cancelled = true;

  Future<void> consent({
    required DateTime from,
    required DateTime until,
    required bool newOnly,
    bool automatic = false,
  }) => _exclusive(() async {
    if (from.isAfter(until)) {
      throw const ValidationError(PersianCopy.smsIngestionConsentMessage);
    }
    final old = await _store.readSmsScan();
    await _store.writeSmsScan(
      old,
      SmsScan(
        from: from.millisecondsSinceEpoch,
        until: until.millisecondsSinceEpoch,
        newOnly: newOnly,
        automatic: automatic,
      ).encode(),
    );
  });

  /// A missing manual record may inherit only explicit new-only consent, never
  /// a historical range. No compatibility read creates or enables consent.
  Future<SmsScan?> loadManual() async {
    final repository = inbox.repository as ManualSmsScanStore;
    final saved = await repository.readManualSmsScan();
    if (saved != null) return SmsScan.decode(saved);
    final history = await (inbox.repository as SmsScanStore).readSmsScan();
    if (history != null) {
      final scan = SmsScan.decode(history);
      if (scan.newOnly) return _manualBoundary(scan.from);
    }
    final automatic = await (inbox.repository as AutomaticSmsScanStore)
        .readAutomaticSmsScan();
    if (automatic != null) {
      final scan = SmsScan.decode(automatic);
      if (scan.newOnly) return _manualBoundary(scan.from);
    }
    return null;
  }

  SmsScan _manualBoundary(int from) =>
      SmsScan(from: from, until: from, newOnly: true, complete: true);

  Future<void> activateManual(DateTime now) => _exclusive(() async {
    final store = inbox.repository as ManualSmsScanStore;
    final saved = await store.readManualSmsScan();
    if (saved != null) return;
    final inherited = await loadManual();
    await store.writeManualSmsScan(
      saved,
      (inherited ?? _manualBoundary(now.millisecondsSinceEpoch)).encode(),
    );
  });

  Future<void> setup({
    required int days,
    required bool automatic,
    required DateTime now,
  }) => _exclusive(() async {
    if (![0, 7, 30].contains(days)) {
      throw const ValidationError(PersianCopy.smsIngestionConsentMessage);
    }
    final repository = inbox.repository;
    final store = repository as ManualSmsScanStore;
    final history = await (repository as SmsScanStore).readSmsScan();
    final manual = await store.readManualSmsScan();
    final auto = await (repository as AutomaticSmsScanStore)
        .readAutomaticSmsScan();
    final prior = await loadManual();
    final at = now.millisecondsSinceEpoch;
    // Setup never narrows an already consented manual window. Existing enabled
    // automatic consent retains its own boundary and progress.
    final autoScan = auto == null ? null : SmsScan.decode(auto);
    await store.writeSmsSetup(
      expectedHistory: history,
      expectedManual: manual,
      expectedAutomatic: auto,
      history: SmsScan(
        from: now.subtract(Duration(days: days)).millisecondsSinceEpoch,
        until: at,
        newOnly: days == 0,
      ).encode(),
      manual: (prior ?? _manualBoundary(at)).encode(),
      automatic: automatic
          ? (autoScan?.automatic == true
                ? auto
                : SmsScan(
                    from: at,
                    until: at,
                    newOnly: true,
                    automatic: true,
                  ).encode())
          : (autoScan == null ? null : (autoScan..automatic = false).encode()),
    );
  });

  Future<void> run({
    required void Function(SmsScan) onProgress,
    void Function()? onNewSuggestion,
    DateTime Function()? now,
    bool Function()? canRun,
  }) {
    bool stopped() => _cancelled || (canRun != null && !canRun());
    if (canRun != null && !canRun()) return Future.value();
    _cancelled = false;
    return _exclusive(() async {
      if (stopped()) return;
      var saved = await _store.readSmsScan();
      if (saved == null) {
        throw const ValidationError(PersianCopy.smsIngestionRunMessage);
      }
      final scan = SmsScan.decode(saved);
      final knownIds = onNewSuggestion == null
          ? null
          : (await inbox.repository.listSuggestions()).map((s) => s.id).toSet();
      if (!await source.hasAccess()) {
        throw const ValidationError(PersianCopy.smsIngestionRunMessage2);
      }
      if (stopped()) return;
      if (scan.complete && scan.newOnly) {
        scan.until = (now ?? DateTime.now)().millisecondsSinceEpoch;
        // Explicit new-only refresh replays only the consented window so late
        // provider insertions cannot hide behind a previously completed cursor.
        scan.timestamp = -1;
        scan.id = -1;
        scan.inspected = 0;
        scan.unsupported = 0;
        scan.complete = false;
        await _store.writeSmsScan(saved, scan.encode());
        saved = scan.encode();
      }
      onProgress(scan);
      while (!stopped() && !scan.complete) {
        final page = await source.readPage(
          from: scan.from,
          until: scan.until,
          afterTimestamp: scan.timestamp,
          afterId: scan.id,
        );
        for (final row in page.rows) {
          if (stopped()) break;
          if (row.timestamp < scan.from ||
              row.timestamp > scan.until ||
              row.timestamp < scan.timestamp ||
              (row.timestamp == scan.timestamp && row.id <= scan.id)) {
            throw const ValidationError(PersianCopy.smsIngestionRunMessage3);
          }
          if (row.message != null) {
            try {
              final suggestion = await inbox.stageSms(
                rawText: row.message!.body,
                sourceKey: row.message!.sourceKey,
                sourceAddress: row.message!.address,
                currency: 'IRR',
                importedAt: row.message!.receivedAt,
              );
              if (knownIds != null && knownIds.add(suggestion.id)) {
                onNewSuggestion!();
              }
            } on DuplicateSmsImport {
              // Legacy fingerprint policy; never reopen a resolved suggestion.
            } on UnsupportedSmsFormat {
              scan.unsupported++;
            }
          }
          scan.timestamp = row.timestamp;
          scan.id = row.id;
          scan.inspected++;
          onProgress(scan);
          await Future<void>.delayed(Duration.zero);
        }
        if (!stopped() && page.rows.length < 100) {
          scan.complete = true;
        }
        // Crash before this checkpoint replays the bounded page safely.
        await _store.writeSmsScan(saved, scan.encode());
        saved = scan.encode();
        onProgress(scan);
      }
    });
  }
}
