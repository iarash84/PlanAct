import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';

import 'package:planact/core/database/app_database.dart' show AppDatabase;
import 'package:planact/core/ids/stable_id.dart';
import 'package:planact/features/commitments/application/commitment_plan_use_case.dart';
import 'package:planact/features/commitments/data/drift_commitment_plan_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/reminders/application/reminder_platform.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/scheduling/domain/occurrence.dart';

/// Isolated, real-DB/device smoke test. Reopen only after the notification action.
/// Between runs: Home, `am kill com.iarash.planact.verification` (never force-stop).
/// First ring: press native Snooze, reopen. Second ring: press Stop, reopen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if ((await PackageInfo.fromPlatform()).packageName !=
      'com.iarash.planact.verification') {
    throw StateError(
      'Alarm verification requires the isolated application ID.',
    );
  }
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Alarm verification — isolated')),
      ),
    ),
  );
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/planact.sqlite');
  final db = AppDatabase(NativeDatabase(file));
  final repository = DriftReminderRepository(db);
  final plans = DriftCommitmentPlanRepository(db);
  final platform = AndroidReminderPlatformAdapter();
  final service = ReminderService(repository: repository, platform: platform);
  try {
    await db.customSelect('SELECT 1').get();
    await platform.configureAlarms(
      databasePath: file.path,
      schemaVersion: db.schemaVersion,
    );
    var phase = await db.readMetadata('alarm_fixture_phase_v1');
    if (phase == 'done') {
      debugPrint('PLANACT_ALARM_NATIVE_PASS: already verified');
      return;
    }
    if (phase != null) {
      final owner = StableId.parse(
        (await db.readMetadata('alarm_fixture_owner_v1'))!,
      );
      final plan = (await plans.findByCommitmentId(owner))!;
      final ids = plan.occurrences.map((o) => o.id).toSet();
      final instances = (await repository.listInstances())
          .where((i) => ids.contains(i.occurrenceId))
          .toList();
      if (phase == 'snooze') {
        final alarm = instances.single;
        if (alarm.status == ReminderInstanceStatus.scheduled &&
            alarm.scheduledAt.isBefore(DateTime.now())) {
          // A fixture left before delivery may be retried without deleting history.
          await service.cancel(alarm);
          phase = null;
        } else {
          final remaining = alarm.snoozedUntil
              ?.difference(DateTime.now().toUtc())
              .inSeconds;
          if (alarm.status != ReminderInstanceStatus.snoozed ||
              remaining == null ||
              remaining < 500 ||
              remaining > 600) {
            throw StateError(
              'Native snooze did not persist ten-minute intent.',
            );
          }
          await service.reconcile(now: DateTime.now());
          await service.cancel(alarm);
          debugPrint(
            'PLANACT_ALARM_NATIVE_SNOOZE_PASS: cold reopen, ten-minute durable intent, cancellation',
          );
        }
      } else {
        if (instances.single.status != ReminderInstanceStatus.delivered ||
            plan.occurrences.single.status != OccurrenceStatus.scheduled) {
          throw StateError(
            'Stop must preserve occurrence status and delivered reminder.',
          );
        }
        await db.writeMetadata('alarm_fixture_phase_v1', 'done');
        debugPrint(
          'PLANACT_ALARM_NATIVE_PASS: background delivery, snooze, cold reopen, cancellation, stop without completion',
        );
        return;
      }
    }
    // Product creation intentionally has minute precision. Do not use a
    // seconds-only fixture which could already be past after slot generation.
    final now = DateTime.now();
    final startAt = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 2,
    );
    final plan =
        await CreateCommitmentPlan(
          commitments: DriftCommitmentRepository(db),
          plans: plans,
          reminderService: service,
        )(
          title: 'isolated alarm fixture',
          startAt: startAt,
          reminderOffsets: [Duration.zero],
          reminderDelivery: ReminderDelivery.alarm,
        );
    if (plan.reminderDeliveryPending) {
      throw StateError('Alarm delivery pending.');
    }
    await db.writeMetadata('alarm_fixture_owner_v1', plan.commitment.id.value);
    await db.writeMetadata(
      'alarm_fixture_phase_v1',
      phase == null ? 'snooze' : 'stop',
    );
    debugPrint(
      'PLANACT_ALARM_NATIVE_READY: ${phase == null ? "snooze" : "stop"} in ${startAt.difference(DateTime.now()).inSeconds} seconds',
    );
  } catch (error) {
    debugPrint('PLANACT_ALARM_NATIVE_FAIL: ${error.runtimeType}');
    rethrow;
  } finally {
    await db.close();
  }
}
