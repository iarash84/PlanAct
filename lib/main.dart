import 'package:flutter/material.dart';
import 'package:planact/app/backup_application_scope.dart';

export 'app/planact_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BackupApplicationScope());
}
