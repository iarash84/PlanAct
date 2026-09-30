import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_lock.dart';

class _FakeAuthenticator implements AppAuthenticator {
  _FakeAuthenticator({this.available = true, this.result = true});

  bool available;
  bool result;
  int attempts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate() async {
    attempts++;
    return result;
  }
}

void main() {
  test('enabling app lock requires supported authentication', () async {
    final auth = _FakeAuthenticator(available: false);
    final controller = AppLockController(authenticator: auth);

    expect(await controller.enable(), isFalse);
    expect(auth.attempts, 0);
    expect(controller.isLocked, isFalse);
  });

  test('lock can be unlocked through the platform authenticator', () async {
    final auth = _FakeAuthenticator();
    final controller = AppLockController(authenticator: auth);

    expect(await controller.enable(), isTrue);
    controller.lock();
    expect(controller.isLocked, isTrue);
    expect(await controller.unlock(), isTrue);
    expect(controller.isLocked, isFalse);
  });

  test('failed unlock leaves the app locked', () async {
    final auth = _FakeAuthenticator(result: false);
    final controller = AppLockController(authenticator: auth);

    controller.lock();
    expect(await controller.unlock(), isFalse);
    expect(controller.isLocked, isTrue);
  });
}
