import 'dart:async';

import 'package:flutter/services.dart';
import 'package:planact/core/errors/app_error.dart';

class AndroidSmsParseError extends AppError {
  const AndroidSmsParseError(String message)
    : super(message, AppErrorCategory.validation);
}

class AndroidSmsMessage {
  const AndroidSmsMessage({
    required this.sourceKey,
    this.address = '',
    required this.body,
    required this.receivedAt,
  });
  final String sourceKey;
  final String address;
  final String body;
  final DateTime receivedAt;

  factory AndroidSmsMessage.fromMap(Map<Object?, Object?> map) {
    final sourceKey = map['sourceKey'];
    final body = map['body'];
    final timestamp = map['receivedAt'];
    if (sourceKey is! String || sourceKey.trim().isEmpty) {
      throw const AndroidSmsParseError('شناسهٔ پیامک معتبر نیست.');
    }
    if (body is! String || body.length > 100000) {
      throw const AndroidSmsParseError('متن پیامک معتبر نیست.');
    }
    if (timestamp is! int || timestamp < 0 || timestamp > 32503680000000) {
      throw const AndroidSmsParseError('زمان پیامک معتبر نیست.');
    }
    final address = map['address'];
    if (address != null && address is! String) {
      throw const AndroidSmsParseError('مبدأ پیامک معتبر نیست.');
    }
    return AndroidSmsMessage(
      sourceKey: sourceKey,
      address: address as String? ?? '',
      body: body,
      receivedAt: DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true),
    );
  }
}

class SmsProviderRow {
  const SmsProviderRow(this.timestamp, this.id, this.message);
  final int timestamp;
  final int id;
  final AndroidSmsMessage? message;
}

class SmsProviderPage {
  const SmsProviderPage(this.rows);
  final List<SmsProviderRow> rows;
}

class AndroidSmsSource {
  AndroidSmsSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('planact/sms');
  final MethodChannel _channel;

  Future<bool> requestAccess() async =>
      await _channel.invokeMethod<bool>('requestAccess') ?? false;
  Future<bool> hasAccess() async =>
      await _channel.invokeMethod<bool>('hasAccess') ?? false;
  Future<SmsProviderPage> readPage({
    required int from,
    required int until,
    required int afterTimestamp,
    required int afterId,
  }) async {
    final result = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'readPage',
      {
        'from': from,
        'until': until,
        'afterTimestamp': afterTimestamp,
        'afterId': afterId,
        'limit': 100,
      },
    );
    if (result == null || result.length > 100) {
      throw const AndroidSmsParseError('صفحهٔ پیامک معتبر نیست.');
    }
    return SmsProviderPage(
      result
          .map((item) {
            final id = item['id'];
            final timestamp = item['receivedAt'];
            if (id is! int || id < 0 || timestamp is! int || timestamp < 0) {
              throw const AndroidSmsParseError('نشانگر پیامک معتبر نیست.');
            }
            return SmsProviderRow(
              timestamp,
              id,
              item['body'] == null ? null : AndroidSmsMessage.fromMap(item),
            );
          })
          .toList(growable: false),
    );
  }

  Stream<AndroidSmsMessage> get messages =>
      const EventChannel('planact/sms/events')
          .receiveBroadcastStream()
          .where((value) => value is Map)
          .map((value) {
            try {
              return AndroidSmsMessage.fromMap(
                Map<Object?, Object?>.from(value as Map),
              );
            } on AndroidSmsParseError {
              throw PlatformException(code: 'malformed_sms_payload');
            }
          });
}
