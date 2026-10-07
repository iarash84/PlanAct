import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/backup_application_scope.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/features/backup/data/file_backup_actions.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';

Future<void> _waitForApp(WidgetTester tester) async {
  for (var i = 0; i < 200; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await tester.pump();
    if (find.byType(PlanActApp).evaluate().isNotEmpty) return;
  }
  fail('File-backed application did not become ready');
}

void main() {
  testWidgets(
    'production startup retains durable data and retries failed preparation',
    (tester) async => tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp('planact-retry-');
      var attempts = 0;
      final retryStarted = Completer<void>();
      final finishRetry = Completer<void>();
      await tester.pumpWidget(
        BackupApplicationScope(
          directory: () async => directory,
          synchronizeReminders: (database) async {
            attempts++;
            if (attempts == 1) {
              await database.writeMetadata('retry_evidence', 'preserved');
              throw StateError('Preparation failed');
            }
            expect(await database.readMetadata('retry_evidence'), 'preserved');
            retryStarted.complete();
            await finishRetry.future;
          },
          clearNotifications: () async {},
        ),
      );
      try {
        for (var i = 0; i < 200; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find.text('تلاش دوباره').evaluate().isNotEmpty) break;
        }
        expect(attempts, 1);
        expect(find.byType(PlanActApp), findsNothing);
        expect(
          find.text('آماده‌سازی امن اطلاعات ممکن نشد. دوباره تلاش کنید.'),
          findsOneWidget,
        );
        expect(find.text('تلاش دوباره'), findsOneWidget);
        await tester.tap(find.text('تلاش دوباره'));
        await tester.pump();
        await retryStarted.future;
        await tester.pump();
        expect(attempts, 2);
        expect(find.byType(PlanActApp), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('تلاش دوباره'), findsNothing);
        finishRetry.complete();
        await _waitForApp(tester);
        final app = tester.widget<PlanActApp>(find.byType(PlanActApp));
        final repository = app.repository! as DriftCommitmentRepository;
        expect(
          await repository.database.readMetadata('retry_evidence'),
          'preserved',
        );
        for (var i = 0; i < 200; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
          if (find.text('چه چیزی نیاز به توجه دارد؟').evaluate().isNotEmpty) {
            break;
          }
        }
        expect(find.text('چه چیزی نیاز به توجه دارد؟'), findsOneWidget);
      } finally {
        if (!finishRetry.isCompleted) finishRetry.complete();
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await directory.delete(recursive: true);
      }
    }),
  );

  testWidgets(
    'backup host drains full commands, disposes UI and rebinds a fresh file-backed generation',
    (tester) async => tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp('planact-host-');
      await tester.pumpWidget(
        BackupApplicationScope(
          directory: () async => directory,
          synchronizeReminders: (_) async {},
          clearNotifications: () async {},
        ),
      );
      try {
        await _waitForApp(tester);
        final oldApp = tester.widget<PlanActApp>(find.byType(PlanActApp));
        final oldRepository = oldApp.repository! as DriftCommitmentRepository;
        final oldState = tester.state(find.byType(PlanActApp));
        final actions = oldApp.backupActions! as FileBackupActions;
        final platform = Completer<void>();
        final started = Completer<void>();
        final command = oldRepository.commandGate!.run(() async {
          await oldRepository.database.writeMetadata('in_flight', 'persisted');
          started.complete();
          await platform.future;
          // A nested repository call remains admitted after retirement.
          await oldRepository.list();
        });
        await started.future;
        var operationStarted = false;
        final backup = actions.exclusive(() async {
          operationStarted = true;
          expect(oldState.mounted, false);
          expect(
            await oldRepository.database.readMetadata('in_flight'),
            'persisted',
          );
          return false; // Picker cancellation must also create a fresh generation.
        });
        await tester.pump();
        expect(find.byType(PlanActApp), findsNothing);
        expect(operationStarted, false);
        await expectLater(
          oldRepository.list(),
          throwsA(isA<StaleApplicationCommand>()),
        );
        platform.complete();
        await command;
        await backup;
        await _waitForApp(tester);
        final newApp = tester.widget<PlanActApp>(find.byType(PlanActApp));
        final newRepository = newApp.repository! as DriftCommitmentRepository;
        expect(
          identical(oldRepository.database, newRepository.database),
          false,
        );
        expect(oldState.mounted, false);
        expect(
          await newRepository.database.readMetadata('in_flight'),
          'persisted',
        );
        await newRepository.list();
        await expectLater(
          oldRepository.list(),
          throwsA(isA<StaleApplicationCommand>()),
        );
        expect(operationStarted, true);
      } finally {
        await tester.pumpWidget(const SizedBox());
        // Native background executor shutdown is asynchronous at widget disposal.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await directory.delete(recursive: true);
      }
    }),
  );
}
