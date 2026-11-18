import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:planact/app/backup_application_scope.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/core/application/command_gate.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/inbox/data/sms_background_runtime.dart';
import 'package:planact/features/inbox/data/drift_sms_detection_notification_store.dart';
import 'package:planact/features/inbox/application/sms_detection_notifications.dart';
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

class _SmsRuntime extends SmsBackgroundRuntime {
  final events = <String>[];
  bool busy = false;
  @override
  Future<void> configure(String path) async => events.add('configure');
  @override
  Future<void> suspend() async {
    events.add('suspend');
    if (busy) throw StateError('headless worker still owns database');
  }

  @override
  Future<void> resume() async => events.add('resume');
}

void main() {
  testWidgets(
    'SMS restore refuses busy worker and suppresses restored batch before rebind',
    (tester) async => tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp(
        'planact-sms-restore-',
      );
      final runtime = _SmsRuntime();
      await tester.pumpWidget(
        BackupApplicationScope(
          directory: () async => directory,
          smsRuntime: runtime,
          synchronizeReminders: (_) async {},
          clearNotifications: () async {},
        ),
      );
      try {
        await _waitForApp(tester);
        expect(runtime.events, ['configure', 'suspend', 'configure', 'resume']);
        var app = tester.widget<PlanActApp>(find.byType(PlanActApp));
        var actions = app.backupActions! as FileBackupActions;
        runtime.busy = true;
        var replaced = false;
        final denied = actions.exclusive(() async {
          replaced = true;
          return true;
        });
        await tester.pump();
        await expectLater(denied, throwsStateError);
        expect(replaced, false);
        expect(runtime.events.where((e) => e == 'resume').length, 1);
        await _waitForApp(tester);
        runtime.busy = false;
        app = tester.widget<PlanActApp>(find.byType(PlanActApp));
        actions = app.backupActions! as FileBackupActions;
        final repository = app.repository! as DriftCommitmentRepository;
        final detectedAt = DateTime.now();
        final state = const SmsDetectionNotificationState(enabled: true)
            .stage('restored-older', detectedAt)
            .stage(
              'restored-pending',
              detectedAt.add(const Duration(seconds: 30)),
            );
        expect(state.backlog, hasLength(1));
        await DriftSmsDetectionNotificationStore(repository.database)
            .compareAndWrite(null, state.encode());
        final hook = tester.state(
          find.byType(BackupApplicationScope),
        ) as BackupRebuildHook;
        final restored = actions.exclusive(() async {
          await hook.rebuild();
          return true;
        });
        await tester.pump();
        await restored;
        await _waitForApp(tester);
        app = tester.widget<PlanActApp>(find.byType(PlanActApp));
        final fresh = app.repository! as DriftCommitmentRepository;
        final saved = SmsDetectionNotificationState.decode(
          await DriftSmsDetectionNotificationStore(fresh.database).read(),
        );
        expect(saved.enabled, true);
        expect(saved.eligible, {'restored-older', 'restored-pending'});
        expect(saved.delivered, containsAll(saved.eligible));
        expect(saved.backlog, isEmpty);
        expect(saved.visible, isEmpty);
        expect(saved.isDismissed, true);
        expect(saved.attempted, true);
        expect(runtime.events.last, 'resume');
      } finally {
        await tester.pumpWidget(const SizedBox());
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await directory.delete(recursive: true);
      }
    }),
  );
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
