import 'dart:io';

import 'package:planact/features/calendar/application/holiday_package_service.dart';
import 'package:planact/features/calendar/data/sqlite_holiday_package_store.dart';
import 'package:planact/features/calendar/data/file_holiday_package_source.dart';

import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:planact/app/planact_app.dart';
import 'package:planact/app/theme/planact_theme.dart';
import 'package:planact/core/database/app_database.dart';
import 'package:planact/core/database/app_database_lifecycle.dart';
import 'package:planact/features/backup/application/backup_service.dart';
import 'package:planact/features/backup/data/file_backup_actions.dart';
import 'package:planact/features/backup/data/secure_backup_keys.dart';
import 'package:planact/features/backup/data/sqlite_backup_storage.dart';
import 'package:planact/features/backup/data/sqlite_backup_snapshot.dart';
import 'package:planact/features/backup/domain/backup_encryption.dart';
import 'package:planact/features/backup/domain/backup_package.dart';
import 'package:planact/features/commitments/data/drift_commitment_repository.dart';
import 'package:planact/features/reminders/application/reminder_platform.dart';
import 'package:planact/features/reminders/application/reminder_service.dart';
import 'package:planact/features/reminders/domain/reminder.dart';
import 'package:planact/features/reminders/data/drift_reminder_repository.dart';
import 'package:sqlite3/sqlite3.dart';

class BackupApplicationScope extends StatefulWidget {
  const BackupApplicationScope({
    super.key,
    this.directory,
    this.synchronizeReminders,
    this.clearNotifications,
  });

  // Native defaults remain production-owned; isolated tests inject only the
  // filesystem location and platform effects, never an in-memory repository.
  final Future<Directory> Function()? directory;
  final Future<void> Function(AppDatabase database)? synchronizeReminders;
  final Future<void> Function()? clearNotifications;
  @override
  State<BackupApplicationScope> createState() => _BackupApplicationScopeState();
}

class _BackupApplicationScopeState extends State<BackupApplicationScope>
    implements BackupRebuildHook {
  AppDatabaseLifecycle? _owner;
  late File _live;
  FileBackupActions? _actions;
  HolidayPackageService? _holidayPackages;
  String? _message;
  bool _busy = true;
  bool _failed = false;
  int _generation = 0;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _close() async {
    final owner = _owner;
    _owner = null;
    await owner?.close();
  }

  Future<void> _open() async {
    if (_disposed) throw StateError('Application host disposed');
    final owner = AppDatabaseLifecycle.open(
      NativeDatabase.createInBackground(_live),
    );
    _owner = owner;
    await owner.database.customSelect('SELECT 1').get();
    if (_disposed) {
      await owner.close();
      if (identical(_owner, owner)) _owner = null;
      throw StateError('Application host disposed');
    }
  }

  Future<void> _clearNotifications() =>
      widget.clearNotifications?.call() ??
      FlutterLocalNotificationsPlugin().cancelAll();

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      _actions = null;
      final directory =
          await (widget.directory?.call() ??
              getApplicationDocumentsDirectory());
      _live = File('${directory.path}/planact.sqlite');
      _holidayPackages = HolidayPackageService(
        SqliteHolidayPackageStore(
          File('${directory.path}/holiday-packages.sqlite'),
        ),
        FileHolidayPackageSource(),
      );
      try {
        await _holidayPackages!.load();
      } catch (_) {
        _message = 'دادهٔ واردشدهٔ تعطیلات قابل بررسی نیست؛ تقویم پایه نمایش داده می‌شود. دادهٔ قبلی حفظ شده است؛ برای بازیابی فایل با پشتیبانی تماس بگیرید.';
      }
      // Build a trusted reference using the real current creation/migration code.
      final reference = File(
        '${directory.path}/planact-schema-reference.sqlite',
      );
      if (await reference.exists()) await reference.delete();
      final expected = AppDatabase(NativeDatabase(reference));
      await expected.customSelect('SELECT 1').get();
      final version = expected.schemaVersion;
      await expected.close();
      final referenceDb = sqlite3.open(reference.path, mode: OpenMode.readOnly);
      final schema = SqliteBackupStorage.schema(referenceDb);
      referenceDb.close();
      await reference.delete();
      final storage = SqliteBackupStorage(
        live: _live,
        schemaVersion: version,
        expectedSchema: schema,
        snapshot: () => _snapshot(redact: false),
        closeLive: _close,
      );
      final recovering = await storage.marker.exists();
      // Keep crash recovery evidence until reopening and platform rebuild both
      // succeed. The storage-only recovery helper clears the marker too early
      // for this application lifecycle.
      if (recovering) await storage.restoreSafetySnapshot();
      await _open();
      if (recovering) await _clearNotifications();
      try {
        await _synchronizeReminders();
      } on ReminderPermissionUnavailable {
        // Normal startup must remain usable without optional capabilities.
        // Recovery still requires a successful rebuild before committing.
        if (recovering) rethrow;
        _message = 'یادآوری‌ها ذخیره شده‌اند، اما مجوز اعلان یا زنگ دقیق فعال نیست. از تنظیمات یادآوری‌ها را فعال کنید.';
      }
      if (recovering) await storage.clearRecoveryMarker();
      const keys = SecureBackupKeys();
      final service = BackupService(
        storage: storage,
        validator: BackupValidator(currentSchemaVersion: version),
        rebuildHook: this,
        keyStorage: keys,
        encryptor: AesGcmBackupEncryptor(),
        nonceGenerator: SecureBackupNonce(),
      );
      _actions = FileBackupActions(
        service: service,
        keys: keys,
        exportPayload: () => _snapshot(redact: true),
        exclusive: _exclusive,
      );
      if (mounted) setState(() => _busy = false);
    } catch (_) {
      await _close();
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
          _message = 'آماده‌سازی امن اطلاعات ممکن نشد. دوباره تلاش کنید.';
        });
      }
    }
  }

  Future<Uint8List> _snapshot({required bool redact}) => sqliteBackupSnapshot(
    database: _owner!.database,
    target: File('${_live.path}.export-snapshot'),
    redact: redact,
  );

  Future<void> _synchronizeReminders() async {
    if (widget.synchronizeReminders case final synchronize?) {
      await synchronize(_owner!.database);
      if (_disposed) throw StateError('Application host disposed');
      return;
    }
    final platform = AndroidReminderPlatformAdapter();
    await platform.initialize();
    await ReminderService(
      repository: DriftReminderRepository(_owner!.database),
      platform: platform,
    ).reconcile(now: DateTime.now().toUtc());
  }

  @override
  Future<void> rebuild() async {
    await _close();
    await _open();
    // Restored platform IDs are not authoritative; cancel the old installation
    // queue before deterministic reconciliation on the replacement state.
    await _clearNotifications();
    await _synchronizeReminders();
    if (_disposed) throw StateError('Application host disposed');
  }

  Future<bool> _exclusive(Future<bool> Function() operation) async {
    if (_busy || _disposed) throw StateError('Backup host unavailable');
    setState(() {
      _busy = true;
      _message = null;
    });
    // Admission closes before yielding. Disposal is not command completion:
    // admitted commands must finish all writes and platform effects first.
    final drained = _owner!.commands.retire();
    try {
      await WidgetsBinding.instance.endOfFrame;
      await drained;
      final success = await operation();
      _message = success
          ? 'عملیات پشتیبان‌گیری یا بازیابی با موفقیت انجام شد.'
          : null;
      return success;
    } catch (_) {
      _message = 'عملیات انجام نشد. فایل، فضای ذخیره‌سازی و کلید همین نصب را بررسی کنید و دوباره تلاش کنید.';
      if (await File('${_live.path}.restore-marker').exists()) {
        await _close();
      }
      rethrow;
    } finally {
      // Export/cancel also retired the old generation. Reopen rather than
      // reviving callbacks which still hold that generation's repositories.
      if (!_disposed &&
          _owner != null &&
          !await File('${_live.path}.restore-marker').exists()) {
        try {
          await _close();
          await _open();
        } catch (_) {
          await _close();
        }
      }
      if (_owner == null) {
        // Do not reopen an uncommitted candidate after failed recovery.
        _failed = true;
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _generation++;
        });
      }
    }
  }

  @override
  void dispose() {
    // Retire synchronously; close waits for admitted commands even if the host
    // is removed while a restore/rebuild is awaiting a platform operation.
    _disposed = true;
    _owner?.commands.retire();
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_busy && !_failed && _owner != null) {
      return PlanActApp(
        key: ValueKey(_generation),
        repository: DriftCommitmentRepository(_owner!.database),
        holidayPackages: _holidayPackages,
        backupActions: _actions,
        backupMessage: _message,
      );
    }
    return MaterialApp(
      theme: PlanActTheme.light(),
      darkTheme: PlanActTheme.dark(),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Center(
            child: _busy
                ? const CircularProgressIndicator(
                    semanticsLabel: 'در حال آماده‌سازی اطلاعات',
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_message ?? 'بازیابی امن نیاز به تلاش دوباره دارد.'),
                      TextButton(
                        onPressed: _start,
                        child: const Text('تلاش دوباره'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
