import 'dart:io';

import 'package:flutter/services.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/features/inbox/application/sms_ingestion.dart';
import 'package:planact/features/inbox/domain/inbox.dart';

/// Process-wide native exclusion, shared by foreground scans and restore.
class SmsBackgroundRuntime {
  const SmsBackgroundRuntime({MethodChannel? channel, this.supportedOverride})
    : _channel = channel ?? const MethodChannel('planact/sms-background');
  final MethodChannel _channel;
  final bool? supportedOverride;
  bool get supported => supportedOverride ?? Platform.isAndroid;

  Future<void> configure(String path) async {
    if (supported) {
      await _channel.invokeMethod<void>('configure', {'path': path});
    }
  }

  Future<void> suspend() async {
    if (supported) await _channel.invokeMethod<void>('suspend');
  }

  Future<void> resume() async {
    if (supported) await _channel.invokeMethod<bool>('resume');
  }

  Future<void> schedule() async {
    if (supported) await _channel.invokeMethod<bool>('schedule');
  }

  Future<T> withForegroundLease<T>(Future<T> Function() action) async {
    if (!supported) return action();
    if (await _channel.invokeMethod<bool>('acquire') != true) {
      throw StateError('SMS runtime busy');
    }
    try {
      return await action();
    } finally {
      await _channel.invokeMethod<void>('release');
    }
  }
}

/// Keeps the same scanner and parser while leasing every foreground run,
/// including the standalone historical Resume path.
class ForegroundSmsIngestion extends SmsIngestion {
  ForegroundSmsIngestion(
    super.inbox,
    super.source, {
    super.store,
    this.runtime = const SmsBackgroundRuntime(),
  });
  final SmsBackgroundRuntime runtime;

  @override
  Future<void> run({
    required void Function(SmsScan) onProgress,
    void Function()? onNewSuggestion,
    Future<void> Function(InboxSuggestion)? onDetected,
    DateTime Function()? now,
    bool Function()? canRun,
    int? maxPages,
    DateTime Function()? notificationNow,
  }) => CommandGate.runFor(
    inbox.repository,
    () => runtime.withForegroundLease(
      () => super.run(
        onProgress: onProgress,
        onNewSuggestion: onNewSuggestion,
        onDetected: onDetected,
        now: now,
        canRun: canRun,
        maxPages: maxPages,
        notificationNow: notificationNow,
      ),
    ),
  );
}
