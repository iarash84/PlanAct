import 'dart:async';

import 'package:planact/features/inbox/application/android_sms_source.dart';

class TestSmsProvider extends AndroidSmsSource {
  final rows = <SmsProviderRow>[];
  final events = StreamController<AndroidSmsMessage>.broadcast(sync: true);
  final bounds = <(int, int)>[];
  bool access = true;
  int reads = 0;
  int requests = 0;
  int subscriptions = 0;
  int? failRead;
  Completer<void>? blockRead;
  int concurrentReads = 0;
  int maxConcurrentReads = 0;

  void add(int id, int timestamp, {String? body}) {
    rows.add(
      SmsProviderRow(
        timestamp,
        id,
        AndroidSmsMessage(
          sourceKey: 'android-sms:$id',
          body: body ?? 'برداشت مبلغ ${1000 + id} ریال',
          receivedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
        ),
      ),
    );
    rows.sort((a, b) {
      final time = a.timestamp.compareTo(b.timestamp);
      return time != 0 ? time : a.id.compareTo(b.id);
    });
  }

  @override
  Future<bool> hasAccess() async => access;
  @override
  Future<bool> requestAccess() async {
    requests++;
    return access;
  }

  @override
  Stream<AndroidSmsMessage> get messages {
    subscriptions++;
    return events.stream;
  }

  @override
  Future<SmsProviderPage> readPage({
    required int from,
    required int until,
    required int afterTimestamp,
    required int afterId,
  }) async {
    reads++;
    bounds.add((from, until));
    concurrentReads++;
    if (concurrentReads > maxConcurrentReads) {
      maxConcurrentReads = concurrentReads;
    }
    try {
      await blockRead?.future;
      if (!access || reads == failRead) {
        throw StateError('Provider unavailable');
      }
      return SmsProviderPage(
        rows
            .where(
              (r) =>
                  r.timestamp >= from &&
                  r.timestamp <= until &&
                  (r.timestamp > afterTimestamp ||
                      (r.timestamp == afterTimestamp && r.id > afterId)),
            )
            .take(100)
            .toList(),
      );
    } finally {
      concurrentReads--;
    }
  }
}
