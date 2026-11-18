import 'dart:convert';

import 'package:planact/core/application/command_gate.dart';

import 'package:planact/features/inbox/domain/inbox.dart';

abstract interface class SmsDetectionNotificationPlatform {
  Future<bool> permitted();
  Future<void> show(List<InboxSuggestion> pending, {required bool showAmounts});
  Future<void> cancel();
}

abstract interface class SmsDetectionNotificationBatchPlatform {
  Future<bool> showBatch({required String batchId, required bool silent});
  Future<bool> dismissed({required String batchId});
  Future<void> dismiss({required String batchId});
}

/// Production stores require intent to be written by atomic staging, never by
/// post-stage callbacks (which cannot distinguish historical replay).
abstract interface class AtomicSmsDetectionNotificationStore {}

abstract interface class SmsDetectionNotificationStore {
  Future<String?> read();
  Future<void> compareAndWrite(String? expected, String value);
}

/// Retained delivery intent for a superseded fixed window.
class SmsNotificationBatch {
  const SmsNotificationBatch({
    required this.id,
    required this.members,
    required this.attempted,
  });
  final String id;
  final Set<String> members;
  final bool attempted;

  Map<String, Object> encode() => {
    'id': id,
    'members': members.toList()..sort(),
    'attempted': attempted,
  };

  factory SmsNotificationBatch.decode(Map<String, dynamic> value) =>
      SmsNotificationBatch(
        id: value['id'] as String,
        members: (value['members'] as List).cast<String>().toSet(),
        attempted: value['attempted'] as bool,
      );
}

class SmsDetectionNotificationState {
  const SmsDetectionNotificationState({
    this.enabled = false,
    bool showAmounts = false,
    this.eligible = const {},
    this.delivered = const {},
    this.visible = const {},
    this.batchId,
    this.startedAt,
    this.members = const {},
    this.attempted = false,
    this.isDismissed = false,
    this.backlog = const [],
  });
  final List<SmsNotificationBatch> backlog;
  final bool enabled;
  bool get showAmounts => false;
  final Set<String> eligible, delivered, visible, members;
  final String? batchId;
  final int? startedAt;
  final bool attempted, isDismissed;
  static const window = Duration(seconds: 30);

  factory SmsDetectionNotificationState.decode(String? raw) {
    if (raw == null) return const SmsDetectionNotificationState();
    final m = jsonDecode(raw) as Map<String, dynamic>;
    if (m['version'] != 1 && m['version'] != 2) {
      throw const FormatException('Unknown SMS notification version');
    }
    Set<String> ids(String key) =>
        (m[key] as List? ?? []).cast<String>().toSet();
    final legacy = m['version'] == 1;
    return SmsDetectionNotificationState(
      backlog: (m['backlog'] as List? ?? [])
          .map(
            (value) => SmsNotificationBatch.decode(
              Map<String, dynamic>.from(value as Map),
            ),
          )
          .toList(),
      enabled: m['enabled'] as bool,
      eligible: ids('eligible'),
      delivered: legacy ? ids('eligible') : ids('delivered'),
      visible: legacy ? {} : ids('visible'),
      members: ids('members'),
      batchId: m['batchId'] as String?,
      startedAt: m['startedAt'] as int?,
      attempted: m['attempted'] as bool? ?? false,
      isDismissed: m['dismissed'] as bool? ?? false,
    );
  }

  SmsDetectionNotificationState copy({
    List<SmsNotificationBatch>? backlog,
    bool? enabled,
    Set<String>? eligible,
    Set<String>? delivered,
    Set<String>? visible,
    Set<String>? members,
    String? batchId,
    int? startedAt,
    bool? attempted,
    bool? isDismissed,
  }) => SmsDetectionNotificationState(
    backlog: backlog ?? this.backlog,
    enabled: enabled ?? this.enabled,
    eligible: eligible ?? this.eligible,
    delivered: delivered ?? this.delivered,
    visible: visible ?? this.visible,
    members: members ?? this.members,
    batchId: batchId ?? this.batchId,
    startedAt: startedAt ?? this.startedAt,
    attempted: attempted ?? this.attempted,
    isDismissed: isDismissed ?? this.isDismissed,
  );

  /// Called for newly inserted new-only suggestions within the staging write.
  SmsDetectionNotificationState stage(String id, DateTime at) {
    if (eligible.contains(id)) return this;
    if (!enabled) {
      return copy(eligible: {...eligible, id}, delivered: {...delivered, id});
    }
    final time = at.millisecondsSinceEpoch;
    final joins =
        startedAt != null &&
        time >= startedAt! &&
        time < startedAt! + window.inMilliseconds;
    return copy(
      eligible: {...eligible, id},
      backlog:
          !joins &&
              batchId != null &&
              !isDismissed &&
              !delivered.containsAll(members)
          ? [
              ...backlog,
              SmsNotificationBatch(
                id: batchId!,
                members: members,
                attempted: attempted,
              ),
            ]
          : backlog,
      members: joins ? {...members, id} : {id},
      batchId: joins ? batchId : id,
      startedAt: joins ? startedAt : time,
      attempted: joins && attempted,
      isDismissed: joins && isDismissed,
      visible: joins ? visible : {},
    );
  }

  String encode() => jsonEncode({
    'version': 2,
    'backlog': backlog.map((batch) => batch.encode()).toList(),
    'enabled': enabled,
    'showAmounts': false,
    'eligible': eligible.toList()..sort(),
    'delivered': delivered.toList()..sort(),
    'visible': visible.toList()..sort(),
    'members': members.toList()..sort(),
    'batchId': batchId,
    'startedAt': startedAt,
    'attempted': attempted,
    'dismissed': isDismissed,
  });
}

class SmsDetectionNotifications {
  SmsDetectionNotifications({
    required this.store,
    required this.platform,
    required this.suggestions,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;
  final SmsDetectionNotificationStore store;
  final SmsDetectionNotificationPlatform platform;
  final Future<List<InboxSuggestion>> Function() suggestions;
  final DateTime Function() now;
  Future<void> _tail = Future.value();
  Future<void> _serial(Future<void> Function() action) {
    // Admit before queueing so retirement drains the entire platform effect,
    // not just the individual metadata reads and writes.
    final next = CommandGate.runFor(store, () => _tail.then((_) => action()));
    _tail = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  static bool pending(InboxSuggestion item) =>
      item.status == SuggestionStatus.pending ||
      item.status == SuggestionStatus.edited;

  Future<void> configure({required bool enabled, bool showAmounts = false}) =>
      _serial(() async {
        final raw = await store.read();
        final old = SmsDetectionNotificationState.decode(raw);
        await store.compareAndWrite(
          raw,
          old
              .copy(
                enabled: enabled,
                backlog: enabled ? old.backlog : [],
                delivered: enabled
                    ? old.delivered
                    : {...old.delivered, ...old.eligible},
                visible: enabled ? old.visible : {},
                isDismissed: enabled ? old.isDismissed : true,
              )
              .encode(),
        );
        if (!enabled) await platform.cancel();
        await _reconcile();
      });

  /// Compatibility only; production new-only scans already commit atomic intent.
  Future<void> detected(InboxSuggestion item) => _serial(() async {
    if (store is AtomicSmsDetectionNotificationStore) return;
    if (!pending(item)) return;
    final raw = await store.read();
    final old = SmsDetectionNotificationState.decode(raw);
    if (old.eligible.contains(item.id.value)) return;
    await store.compareAndWrite(raw, old.stage(item.id.value, now()).encode());
  });
  Future<void> reconcile() => _serial(_reconcile);
  Future<void> _reconcile() async {
    // Process oldest intent first. Each acknowledgment is durable before moving
    // on; an ambiguous submission retains its reservation for a silent retry.
    while (true) {
      final raw = await store.read();
      final state = SmsDetectionNotificationState.decode(raw);
      if (!state.enabled || state.backlog.isEmpty) break;
      if (!await platform.permitted()) return;
      final batch = state.backlog.first;
      final current = (await suggestions())
          .where(pending)
          .where((item) => batch.members.contains(item.id.value))
          .toList();
      final native = platform is SmsDetectionNotificationBatchPlatform
          ? platform as SmsDetectionNotificationBatchPlatform
          : null;
      final suppressed =
          current.isEmpty ||
          (native != null && await native.dismissed(batchId: batch.id));
      var expected = raw;
      var reserved = state;
      if (!suppressed) {
        if (!batch.attempted) {
          reserved = state.copy(
            backlog: [
              SmsNotificationBatch(
                id: batch.id,
                members: batch.members,
                attempted: true,
              ),
              ...state.backlog.skip(1),
            ],
          );
          expected = reserved.encode();
          await store.compareAndWrite(raw, expected);
        }
        if (native != null) {
          await native.showBatch(batchId: batch.id, silent: batch.attempted);
        } else {
          await platform.show(current, showAmounts: false);
        }
      }
      await store.compareAndWrite(
        expected,
        reserved
            .copy(
              backlog: reserved.backlog.skip(1).toList(),
              delivered: {...reserved.delivered, ...batch.members},
            )
            .encode(),
      );
    }
    var raw = await store.read();
    var state = SmsDetectionNotificationState.decode(raw);
    final batch = state.batchId;
    if (!state.enabled || batch == null) return;
    final current = (await suggestions())
        .where(pending)
        .where((s) => state.members.contains(s.id.value))
        .toList();
    final visible = current.map((s) => s.id.value).toSet();
    final native = platform is SmsDetectionNotificationBatchPlatform
        ? platform as SmsDetectionNotificationBatchPlatform
        : null;
    if (visible.isEmpty && !state.isDismissed) {
      await platform.cancel();
      await store.compareAndWrite(
        raw,
        state
            .copy(
              attempted: true,
              visible: {},
              delivered: {...state.delivered, ...state.members},
            )
            .encode(),
      );
      return;
    }
    if (state.isDismissed ||
        (native != null && await native.dismissed(batchId: batch))) {
      await platform.cancel();
      await store.compareAndWrite(
        raw,
        state
            .copy(
              isDismissed: true,
              visible: {},
              delivered: {...state.delivered, ...state.members},
            )
            .encode(),
      );
      return;
    }
    if (!await platform.permitted()) return;
    if (state.attempted &&
        visible.length == state.visible.length &&
        visible.containsAll(state.visible)) {
      return;
    }
    final silent = state.attempted;
    // Reserve before OS submission: ambiguous crashes/failures retry silently.
    if (!state.attempted) {
      state = state.copy(attempted: true);
      final reserved = state.encode();
      await store.compareAndWrite(raw, reserved);
      raw = reserved;
    }
    final accepted = native == null
        ? true
        : await native.showBatch(batchId: batch, silent: silent);
    if (native == null) await platform.show(current, showAmounts: false);
    await store.compareAndWrite(
      raw,
      state
          .copy(
            isDismissed: !accepted,
            delivered: {...state.delivered, ...visible},
            visible: accepted ? visible : {},
          )
          .encode(),
    );
  }

  Future<void> dismiss() => _serial(() async {
    final raw = await store.read();
    final state = SmsDetectionNotificationState.decode(raw);
    final batch = state.batchId;
    if (batch == null) return;
    if (platform case final SmsDetectionNotificationBatchPlatform native) {
      await native.dismiss(batchId: batch);
    } else {
      await platform.cancel();
    }
    await store.compareAndWrite(
      raw,
      state.copy(isDismissed: true, visible: {}).encode(),
    );
  });
  Future<InboxSuggestion?> resolveTap(String id) async {
    for (final item in await suggestions()) {
      if (item.id.value == id && pending(item)) return item;
    }
    return null;
  }
}
