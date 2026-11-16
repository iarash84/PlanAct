import 'package:flutter/services.dart';
import 'package:planact/core/money/money_input_formatter.dart';
import 'package:planact/core/localization/persian_copy.g.dart';
import 'package:planact/core/localization/persian_numbers.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

/// Independent channel avoids replacing the reminder plugin's tap callback.
class AndroidSmsDetectionNotifications
    implements SmsDetectionNotificationPlatform {
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
  Future<void> show(
    List<InboxSuggestion> pending, {
    required bool showAmounts,
  }) async {
    var body = pending.length == 1
        ? PersianCopy.smsDetectionBody
        : PersianCopy.smsDetectionMultiple;
    if (pending.length == 1 && showAmounts) {
      final draft = pending.single.draft;
      final evidence = draft.currencyEvidence;
      // Only explicit source evidence, never a reviewer proposal or unknown unit.
      if (evidence != null &&
          evidence.detectedUnit != null &&
          draft.amount.currency == 'IRR' &&
          draft.amount.minorUnits > 0) {
        body = PersianCopy.smsDetectionAmountBody(
          PersianNumbers.format(
            MoneyInputFormatter.groupText(draft.amount.minorUnits.toString()),
          ),
          body,
        );
      }
    }
    await channel.invokeMethod<void>('show', {
      'title': PersianCopy.smsDetectionTitle,
      'body': body,
      'generic': PersianCopy.smsDetectionBody,
      'target': pending.length == 1 ? pending.single.id.value : 'pending',
    });
  }
}
