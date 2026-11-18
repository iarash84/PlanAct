import 'package:flutter/material.dart';
import 'package:planact/app/backup_application_scope.dart';

export 'app/planact_app.dart';
// Include the retained native-invoked library in the application compilation.
export 'features/inbox/data/sms_background_entrypoint.dart'
    show smsBackgroundMain;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BackupApplicationScope());
}
