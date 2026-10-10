import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:planact/core/errors/app_error.dart';

/// Ephemeral export key. Never persisted alongside its encrypted package.
class BackupRecoveryKey {
  BackupRecoveryKey._(this.bytes);
  final Uint8List bytes;

  static Future<BackupRecoveryKey> generate() async {
    final key = await AesGcm.with256bits().newSecretKey();
    return BackupRecoveryKey._(Uint8List.fromList(await key.extractBytes()));
  }

  String get text => base64UrlEncode(bytes);

  static BackupRecoveryKey parse(String text) {
    try {
      final value = text.trim();
      final bytes = base64Url.decode(value);
      if (bytes.length != 32 || base64UrlEncode(bytes) != value) {
        throw const FormatException();
      }
      return BackupRecoveryKey._(bytes);
    } catch (_) {
      throw const ValidationError('Invalid recovery key');
    }
  }

  void dispose() => bytes.fillRange(0, bytes.length, 0);
}
