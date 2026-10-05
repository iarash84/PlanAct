import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/app_lock.dart';

class _DeferredAuthenticator implements AppAuthenticator {
  final Completer<bool> result = Completer<bool>();
  int attempts = 0;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate() {
    attempts++;
    return result.future;
  }
}

void main() {
  testWidgets('cold start hides private content until authentication', (
    tester,
  ) async {
    final auth = _DeferredAuthenticator();
    final controller = AppLockController(authenticator: auth);
    await tester.pumpWidget(
      MaterialApp(
        home: AppLockGate(
          enabled: true,
          controller: controller,
          child: const Text('private-content'),
        ),
      ),
    );
    await tester.pump();
    expect(controller.isLocked, isTrue);
    expect(find.text('private-content'), findsNothing);
    expect(find.text('پلن‌اکت قفل است'), findsOneWidget);
    auth.result.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('private-content'), findsOneWidget);
  });

  testWidgets('failed authentication keeps private content hidden', (
    tester,
  ) async {
    final auth = _DeferredAuthenticator();
    await tester.pumpWidget(
      MaterialApp(
        home: AppLockGate(
          enabled: true,
          controller: AppLockController(authenticator: auth),
          child: const Text('private-content'),
        ),
      ),
    );
    await tester.pump();
    auth.result.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('private-content'), findsNothing);
    expect(find.textContaining('احراز هویت انجام نشد'), findsOneWidget);
  });
}
