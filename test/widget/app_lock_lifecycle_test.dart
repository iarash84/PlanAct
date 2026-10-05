import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_lock.dart';
import 'package:planact/features/settings/presentation/app_lock_settings_card.dart';

class _Auth implements AppAuthenticator {
  final requests = <Completer<bool>>[];
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<bool> authenticate() {
    final request = Completer<bool>();
    requests.add(request);
    return request.future;
  }
}

void main() {
  test('background invalidates an in-flight authentication result', () async {
    final auth = _Auth();
    final controller = AppLockController(authenticator: auth)..lock();
    final result = controller.unlock();
    await Future<void>.delayed(Duration.zero);
    controller.lock();
    auth.requests.single.complete(true);
    expect(await result, isFalse);
    expect(controller.isLocked, isTrue);
  });

  testWidgets('root lock hides pushed routes and retains form input', (
    tester,
  ) async {
    final auth = _Auth();
    final controller = AppLockController(authenticator: auth);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigator,
        builder: (_, child) =>
            AppLockGate(enabled: true, controller: controller, child: child!),
        home: const Scaffold(body: Text('home')),
      ),
    );
    await tester.pump();
    auth.requests.last.complete(true);
    await tester.pumpAndSettle();
    navigator.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: TextField()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'private draft');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    expect(find.byType(TextField), findsNothing);
    expect(find.text('پلن‌اکت قفل است'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(auth.requests.length, 2);
    auth.requests.last.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('private draft'), findsOneWidget);
  });

  testWidgets('native prompt inactive/resume does not repeat authentication', (
    tester,
  ) async {
    final auth = _Auth();
    await tester.pumpWidget(
      MaterialApp(
        home: AppLockGate(
          enabled: true,
          controller: AppLockController(authenticator: auth),
          child: const Text('private'),
        ),
      ),
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    auth.requests.single.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('private'), findsOneWidget);
    expect(auth.requests.length, 1);
  });

  testWidgets(
    'authentication exception offers retry without exposing content',
    (tester) async {
      final auth = _Auth();
      await tester.pumpWidget(
        MaterialApp(
          home: AppLockGate(
            enabled: true,
            controller: AppLockController(authenticator: auth),
            child: const Text('private'),
          ),
        ),
      );
      await tester.pump();
      auth.requests.single.completeError(StateError('unavailable'));
      await tester.pumpAndSettle();
      expect(find.text('private'), findsNothing);
      await tester.tap(find.text('باز کردن قفل'));
      await tester.pump();
      expect(auth.requests.length, 2);
      auth.requests.last.complete(true);
      await tester.pumpAndSettle();
      expect(find.text('private'), findsOneWidget);
    },
  );

  testWidgets('settings failure retains value and permits retry', (
    tester,
  ) async {
    int attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppLockSettingsCard(
            enabled: true,
            change: (_) async {
              attempts++;
              throw StateError('write failed');
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(find.textContaining('تغییر قفل انجام نشد'), findsOneWidget);
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });
}
