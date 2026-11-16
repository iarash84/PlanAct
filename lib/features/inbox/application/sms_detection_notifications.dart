import 'dart:convert';

import 'package:planact/features/inbox/domain/inbox.dart';

/// Delivery is independent from staging and never changes review decisions.
abstract interface class SmsDetectionNotificationPlatform {
  Future<bool> permitted();
  Future<void> show(List<InboxSuggestion> pending, {required bool showAmounts});
  Future<void> cancel();
}

abstract interface class SmsDetectionNotificationStore {
  Future<String?> read();

  /// Compare-and-write under fresh transactional writer admission.
  Future<void> compareAndWrite(String? expected, String value);
}

class SmsDetectionNotificationState {
  const SmsDetectionNotificationState({
    this.enabled = false,
    this.showAmounts = false,
    this.eligible = const {},
    this.delivered = const {},
    this.visible = const {},
  });

  final bool enabled;
  final bool showAmounts;
  final Set<String> eligible;
  final Set<String> delivered;
  final Set<String> visible;

  factory SmsDetectionNotificationState.decode(String? raw) {
    if (raw == null) return const SmsDetectionNotificationState();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    if (json['version'] != 1) {
      throw const FormatException('Unknown SMS notification version');
    }
    Set<String> ids(String key) => (json[key] as List).cast<String>().toSet();
    return SmsDetectionNotificationState(
      enabled: json['enabled'] as bool,
      showAmounts: json['showAmounts'] as bool,
      eligible: ids('eligible'),
      delivered: ids('delivered'),
      visible: ids('visible'),
    );
  }

  String encode() => jsonEncode({
    'version': 1,
    'enabled': enabled,
    'showAmounts': showAmounts,
    'eligible': eligible.toList()..sort(),
    'delivered': delivered.toList()..sort(),
    'visible': visible.toList()..sort(),
  });
}

/// A single summary notification is replaced, never one alert per provider row.
/// Operations serialize locally; durable CAS also rejects stale writers.
class SmsDetectionNotifications {
  SmsDetectionNotifications({
    required this.store,
    required this.platform,
    required this.suggestions,
  });

  final SmsDetectionNotificationStore store;
  final SmsDetectionNotificationPlatform platform;
  final Future<List<InboxSuggestion>> Function() suggestions;

  Future<void> _tail = Future.value();

  Future<void> _serial(Future<void> Function() action) {
    final next = _tail.then((_) => action());
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  static bool pending(InboxSuggestion item) =>
      item.status == SuggestionStatus.pending ||
      item.status == SuggestionStatus.edited;

  Future<void> configure({required bool enabled, required bool showAmounts}) =>
      _serial(() async {
        final raw = await store.read();
        final old = SmsDetectionNotificationState.decode(raw);
        await store.compareAndWrite(
          raw,
          SmsDetectionNotificationState(
            enabled: enabled,
            showAmounts: showAmounts,
            eligible: old.eligible,
            delivered: old.delivered,
            visible: old.visible,
          ).encode(),
        );
        await _reconcile(force: old.showAmounts != showAmounts);
      });

  /// Called for replayed as well as newly staged new-only scan rows. Historical
  /// scan callers must not invoke this: durable eligibility repairs a crash
  /// between staging and this append without rediscovering the whole Inbox.
  Future<void> detected(InboxSuggestion item) => _serial(() async {
    if (!pending(item)) return;
    final raw = await store.read();
    final old = SmsDetectionNotificationState.decode(raw);
    if (old.eligible.contains(item.id.value)) return;
    await store.compareAndWrite(
      raw,
      SmsDetectionNotificationState(
        enabled: old.enabled,
        showAmounts: old.showAmounts,
        eligible: {...old.eligible, item.id.value},
        delivered: old.enabled
            ? old.delivered
            : {...old.delivered, item.id.value},
        visible: old.visible,
      ).encode(),
    );
  });

  Future<void> reconcile() => _serial(_reconcile);

  Future<void> _reconcile({bool force = false}) async {
    final raw = await store.read();
    final old = SmsDetectionNotificationState.decode(raw);
    if (!old.enabled && old.visible.isEmpty) return;
    final current = (await suggestions())
        .where(pending)
        .where((s) => old.eligible.contains(s.id.value))
        .where(
          (s) =>
              !old.delivered.contains(s.id.value) ||
              old.visible.contains(s.id.value),
        )
        .toList();
    final visible = current.map((s) => s.id.value).toSet();
    if (!old.enabled) {
      await platform.cancel();
      // Suppress disabled-period backlog rather than alerting on later opt-in.
      await store.compareAndWrite(
        raw,
        SmsDetectionNotificationState(
          enabled: false,
          showAmounts: old.showAmounts,
          eligible: old.eligible,
          delivered: {...old.delivered, ...visible},
        ).encode(),
      );
      return;
    }
    if (!await platform.permitted()) return;
    final fresh = visible.difference(old.delivered);
    final changed =
        visible.length != old.visible.length ||
        !visible.containsAll(old.visible);
    if (visible.isEmpty) {
      await platform.cancel();
    } else if (fresh.isNotEmpty ||
        ((changed || force) && old.visible.isNotEmpty)) {
      await platform.show(current, showAmounts: old.showAmounts);
    } else {
      return;
    }
    // Mark delivered only after successful OS submission. A crash before this
    // write replaces the same notification on retry; it cannot create duplicates.
    await store.compareAndWrite(
      raw,
      SmsDetectionNotificationState(
        enabled: old.enabled,
        showAmounts: old.showAmounts,
        eligible: old.eligible,
        delivered: {...old.delivered, ...visible},
        visible: visible,
      ).encode(),
    );
  }

  /// Untrusted notification payloads are only navigation hints.
  Future<InboxSuggestion?> resolveTap(String id) async {
    for (final item in await suggestions()) {
      if (item.id.value == id && pending(item)) return item;
    }
    return null;
  }
}
