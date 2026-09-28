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

class AndroidSmsSource {
  AndroidSmsSource({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('planact/sms');
  final MethodChannel _channel;

  Future<bool> requestAccess() async =>
      await _channel.invokeMethod<bool>('requestAccess') ?? false;
  Future<bool> hasAccess() async =>
      await _channel.invokeMethod<bool>('hasAccess') ?? false;
  Future<List<AndroidSmsMessage>> readRelevantMessages() async {
    final result = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'readRelevant',
    );
    final messages = <AndroidSmsMessage>[];
    for (final item in result ?? const []) {
      try {
        messages.add(AndroidSmsMessage.fromMap(item));
      } on AndroidSmsParseError {
        continue;
      }
    }
    return messages;
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
