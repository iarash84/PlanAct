import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/native.dart';
import 'package:planact/app/startup_splash.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/features/commitments/application/commitment_repository.dart';

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
  return DriftCommitmentRepository(database);
}
