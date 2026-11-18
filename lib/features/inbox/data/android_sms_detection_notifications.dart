import 'package:flutter/services.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

/// Payloads contain only opaque batch identity and delivery semantics. Native
/// code owns generic localized text for both unlocked and lockscreen content.
class AndroidSmsDetectionNotifications
    implements
        SmsDetectionNotificationPlatform,
        SmsDetectionNotificationBatchPlatform {
  static const channel = MethodChannel('planact/sms-notifications');

  void listenForTaps(Future<void> Function()? callback) {
    channel.setMethodCallHandler(
      callback == null
          ? null
          : (call) async {
              if (call.method == 'tapAvailable') await callback();
            },
    );
  }

  @override
  Future<bool> permitted() async =>
      await channel.invokeMethod<bool>('permitted') ?? false;

  Future<bool> requestPermission() async =>
      await channel.invokeMethod<bool>('requestPermission') ?? false;

  Future<String?> takeTap() async {
    try {
      return await channel.invokeMethod<String>('takeTap');
    } on MissingPluginException {
      return null;
    }
  }

  @override
  Future<void> cancel() => channel.invokeMethod<void>('cancel');

  @override
  Future<bool> showBatch({
    required String batchId,
    required bool silent,
  }) async =>
      await channel.invokeMethod<bool>('show', {
        'batchId': batchId,
        'silent': silent,
      }) ??
      false;

  @override
  Future<bool> dismissed({required String batchId}) async =>
      await channel.invokeMethod<bool>('dismissed', {'batchId': batchId}) ??
      false;

  @override
  Future<void> dismiss({required String batchId}) =>
      channel.invokeMethod<void>('dismiss', {'batchId': batchId});

  /// Legacy calls are generic and quiet. Production uses durable showBatch.
  @override
  Future<void> show(
    List<InboxSuggestion> pending, {
    required bool showAmounts,
  }) async {
    if (pending.isEmpty) return;
    await showBatch(batchId: pending.first.id.value, silent: true);
  }
}
