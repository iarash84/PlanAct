import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:planact/core/application/command_gate.dart';

void main() {
  test('retirement drains platform work and rejects stale commands', () async {
    final gate = CommandGate();
    final platform = Completer<void>();
    final entered = Completer<void>();
    final effects = <String>[];
    final command = gate.run(() async {
      effects.add('persisted');
      entered.complete();
      await platform.future;
      effects.add('platform complete');
    });
    await entered.future;
    var drained = false;
    final retirement = gate.retire().then((_) => drained = true);
    await expectLater(
      gate.run(() async => effects.add('stale write')),
      throwsA(isA<StaleApplicationCommand>()),
    );
    expect(drained, isFalse);
    platform.complete();
    await command;
    await retirement;
    expect(effects, ['persisted', 'platform complete']);
    expect(drained, isTrue);
    await gate.retire();
  });

  test('admitted commands may finish nested writes after retirement', () async {
    final gate = CommandGate();
    final resume = Completer<void>();
    final entered = Completer<void>();
    var writes = 0;
    final command = gate.run(() async {
      entered.complete();
      await resume.future;
      await gate.run(() async => writes++);
    });
    await entered.future;
    final retirement = gate.retire();
    resume.complete();
    await command;
    await retirement;
    expect(writes, 1);
  });

  test(
    'unawaited nested work retains barrier until its effects finish',
    () async {
      final gate = CommandGate();
      final release = Completer<void>();
      late Future<void> nested;
      await gate.run(() async {
        nested = gate.run(() async => release.future);
      });
      var drained = false;
      final retirement = gate.retire().then((_) => drained = true);
      await Future<void>.delayed(Duration.zero);
      expect(drained, isFalse);
      release.complete();
      await nested;
      await retirement;
      expect(drained, isTrue);
    },
  );

  test(
    'failed commands release admission and cannot revive a retired gate',
    () async {
      final gate = CommandGate();
      await expectLater(
        gate.run<void>(() async => throw StateError('write failed')),
        throwsStateError,
      );
      await gate.retire();
      await expectLater(
        gate.run<void>(() async {}),
        throwsA(isA<StaleApplicationCommand>()),
      );
    },
  );
}
