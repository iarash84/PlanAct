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
  });
  final int from;
  int until;
  final bool newOnly;
  int timestamp;
  int id;
  int inspected;
  int unsupported;
  bool complete;

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
    );
  }
}

/// No read/lifecycle side effect. Every run is explicitly started or resumed.
class SmsIngestion {
  SmsIngestion(this.inbox, this.source);
  final InboxUseCases inbox;
  final AndroidSmsSource source;
  static final _active = Expando<bool>();
  bool _cancelled = false;
  SmsScanStore get _store => inbox.repository as SmsScanStore;
  Future<SmsScan?> load() async {
    final text = await _store.readSmsScan();
    return text == null ? null : SmsScan.decode(text);
  }

  void cancel() => _cancelled = true;

  Future<void> consent({
    required DateTime from,
    required DateTime until,
    required bool newOnly,
  }) => CommandGate.runFor(inbox.repository, () async {
    if (_active[inbox.repository] == true) throw StateError('Scan is active');
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
      ).encode(),
    );
  });

  Future<void> run({
    required void Function(SmsScan) onProgress,
  }) => CommandGate.runFor(inbox.repository, () async {
    if (_active[inbox.repository] == true) throw StateError('Scan is active');
    _active[inbox.repository] = true;
    _cancelled = false;
    try {
      var saved = await _store.readSmsScan();
      if (saved == null) {
        throw const ValidationError(PersianCopy.smsIngestionRunMessage);
      }
      final scan = SmsScan.decode(saved);
      if (!await source.hasAccess()) {
        throw const ValidationError(PersianCopy.smsIngestionRunMessage2);
      }
      if (scan.complete && scan.newOnly) {
        scan.until = DateTime.now().millisecondsSinceEpoch;
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
      while (!_cancelled && !scan.complete) {
        final page = await source.readPage(
          from: scan.from,
          until: scan.until,
          afterTimestamp: scan.timestamp,
          afterId: scan.id,
        );
        for (final row in page.rows) {
          if (_cancelled) break;
          if (row.timestamp < scan.from ||
              row.timestamp > scan.until ||
              row.timestamp < scan.timestamp ||
              (row.timestamp == scan.timestamp && row.id <= scan.id)) {
            throw const ValidationError(PersianCopy.smsIngestionRunMessage3);
          }
          if (row.message != null) {
            try {
              await inbox.stageSms(
                rawText: row.message!.body,
                sourceKey: row.message!.sourceKey,
                currency: 'IRR',
                importedAt: row.message!.receivedAt,
              );
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
        if (!_cancelled && page.rows.length < 100) {
          scan.complete = true;
        }
        // Crash before this checkpoint replays the bounded page safely.
        await _store.writeSmsScan(saved, scan.encode());
        saved = scan.encode();
        onProgress(scan);
      }
    } finally {
      _active[inbox.repository] = false;
    }
  });
}
