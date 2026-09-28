import 'dart:async';

import 'package:flutter/services.dart';

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

  factory AndroidSmsMessage.fromMap(Map<Object?, Object?> map) =>
      AndroidSmsMessage(
        sourceKey: map['sourceKey']! as String,
        address: map['address'] as String? ?? '',
        body: map['body']! as String,
        receivedAt: DateTime.fromMillisecondsSinceEpoch(
          map['receivedAt']! as int,
          isUtc: true,
        ),
      );
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
    return [
      for (final item in result ?? const []) AndroidSmsMessage.fromMap(item),
    ];
  }

  Stream<AndroidSmsMessage> get messages =>
      const EventChannel('planact/sms/events').receiveBroadcastStream().map(
        (value) =>
            AndroidSmsMessage.fromMap(Map<Object?, Object?>.from(value as Map)),
      );
}
