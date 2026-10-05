import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'package:planact/app/startup_splash.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:planact/features/reminders/application/reminder_platform.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';

export 'app/planact_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PlanActStartup(repositoryLoader: _initializeApplication));
}

Future<CommitmentRepository> _initializeApplication() => _createRepository();

Future<CommitmentRepository> _createRepository() async {
  final directory = await getApplicationDocumentsDirectory();
  final database = AppDatabase(
    NativeDatabase.createInBackground(File('${directory.path}/planact.sqlite')),
  );
  final platform = AndroidReminderPlatformAdapter();
  await platform.initialize();
  // Permission prompts belong to an explicit reminder-capability interaction,
  // never the general application startup (ADR 0012).
  await ReminderService(
    repository: DriftReminderRepository(database),
    platform: platform,
  ).reconcile(now: DateTime.now().toUtc());
  return DriftCommitmentRepository(database);
}
