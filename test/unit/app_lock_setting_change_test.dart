import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_lock.dart';

class _Authenticator implements AppAuthenticator {
  bool allowed = true;
  Completer<bool>? pending;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate() async =>
      pending == null ? allowed : pending!.future;
}

void main() {
  test('denied authentication never writes settings or unlocks', () async {
    final auth = _Authenticator()..allowed = false;
    final controller = AppLockController(authenticator: auth)..lock();
    addTearDown(controller.dispose);
    var writes = 0;
    await expectLater(
      controller.changeSetting(enabled: false, persist: (_) async => writes++),
      throwsStateError,
    );
    expect(writes, 0);
    expect(controller.isLocked, isTrue);
  });

  test('failed durable write preserves effective protection', () async {
    final controller = AppLockController(authenticator: _Authenticator())
      ..lock();
    addTearDown(controller.dispose);
    await expectLater(
      controller.changeSetting(
        enabled: false,
        persist: (_) async => throw StateError('write failed'),
      ),
      throwsStateError,
    );
    expect(controller.isLocked, isTrue);
    await controller.changeSetting(enabled: false, persist: (_) async {});
    expect(controller.isLocked, isFalse);
  });

  test('disable only unlocks after persistence completes', () async {
    final controller = AppLockController(authenticator: _Authenticator())
      ..lock();
    addTearDown(controller.dispose);
    final writing = Completer<void>();
    final started = Completer<void>();
    final change = controller.changeSetting(
      enabled: false,
      persist: (enabled) {
        expect(enabled, isFalse);
        expect(controller.isLocked, isTrue);
        started.complete();
        return writing.future;
      },
    );
    await started.future;
    expect(controller.isLocked, isTrue);
    writing.complete();
    await change;
    expect(controller.isLocked, isFalse);
  });

  test(
    'background invalidates setting authentication before persistence',
    () async {
      final auth = _Authenticator()..pending = Completer<bool>();
      final controller = AppLockController(authenticator: auth);
      addTearDown(controller.dispose);
      var writes = 0;
      final change = controller.changeSetting(
        enabled: true,
        persist: (_) async => writes++,
      );
      final expectation = expectLater(change, throwsStateError);
      controller.lock();
      auth.pending!.complete(true);
      await expectation;
      expect(writes, 0);
      expect(controller.isLocked, isTrue);
    },
  );

  test(
    'concurrent setting changes are rejected without a second write',
    () async {
      final auth = _Authenticator()..pending = Completer<bool>();
      final controller = AppLockController(authenticator: auth);
      addTearDown(controller.dispose);
      var writes = 0;
      final change = controller.changeSetting(
        enabled: true,
        persist: (_) async => writes++,
      );
      await expectLater(
        controller.changeSetting(
          enabled: false,
          persist: (_) async => writes++,
        ),
        throwsStateError,
      );
      auth.pending!.complete(true);
      await change;
      expect(writes, 1);
    },
  );
}
